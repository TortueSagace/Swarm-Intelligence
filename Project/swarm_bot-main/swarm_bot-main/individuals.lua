--[[
  individuals.lua - Reactive Foraging Controller (INDI-BOT)

  This script implements the baseline foraging behavior for individual footbots
  in the ARGoS simulator, under the INDI-BOT paradigm. Robots act autonomously
  without communication or explicit cooperation.

  Key Features:
    - Finite-State Machine with four states:
        • WANDER: explores the arena randomly
        • APPROACH: moves toward a detected food item
        • CARRY: grabs the item and carries it away from the nest
    - Simulated annealing parameter α(t) controls post-drop randomness
    - Nest detection based on ground sensor readings (darkest area = nest)
    - Obstacle avoidance and forward bias during exploration
    - Cooldown mechanism to prevent re-engaging with freshly dropped food

  This controller serves as the non-cooperative reference behavior for comparing
  swarm-level strategies in the constrained foraging task.
]]


----------------------------------------------------------
--  CONFIGURATION SWITCH
----------------------------------------------------------
OBSTACLE_AVOIDANCE_ENABLED = true  -- set true to re-enable avoiding walls/boxes

----------------------------------------------------------
--  CONSTANTS
----------------------------------------------------------
FORWARD_SPEED   = 20
TURN_SPEED      = 10

CENTER_EPS      = 0.05   -- rad (~3°)
PROX_GRAB       = 0.9    -- front proximity for grabbing
PROX_WALL       = 0.30   -- front proximity for walls
LOST_TIMEOUT    = 5      -- steps to remember lost food
NEST_DARK       = 0.99   -- avg ground < this = nest
FLOOR_DIFF      = 0.01   -- avg ground diff to detect nest

ALPHA_START = 0.10        -- initial α  (very exploratory)
ALPHA_TARGET = 1.00       -- final α    (always random-turn)
ALPHA_TAU    = 500       -- time-constant (in steps) of the rise
--             ↑ bigger  → slower convergence
DROP_MARGIN     = 9.00   -- cm to move past the grab point
IGNORE_MARGIN   = 150 -- after deposing food, ignore new food for this distance
DRAGGING_MARGIN = 400    -- cm to move past the grab point
ARC_STEPS       = 20          -- number of 0.1 s steps for curved move
ARC_BIAS        = 0.1         -- inner-wheel speed factor (0‒1)

-- compute number of steps ≃ DROP_MARGIN cm (0.1s per step)
local CROSS_STEPS = math.ceil(DROP_MARGIN * 10 / FORWARD_SPEED)
local IGNORE_STEPS = math.ceil(IGNORE_MARGIN * 10 / FORWARD_SPEED)
local DRAGGING_EARLY_STOP_STEPS = math.ceil(DRAGGING_MARGIN * 10 / FORWARD_SPEED)

STATE_WANDER    = 0
STATE_APPROACH  = 1
STATE_CARRY     = 2
STATE_CURVE     = 3         -- temporary state after a straight drop

----------------------------------------------------------
--  COLOUR TESTS
----------------------------------------------------------
local function is_red(c)
   return c.red   > 200 and c.green <  80 and c.blue <  80
end
local function is_yellow(c)
   return c.red   > 200 and c.green > 200 and c.blue < 100
end

----------------------------------------------------------
--  HELPER FUNCTIONS (must come before init)
----------------------------------------------------------
local function set_wheels(l, r)
   robot.wheels.set_velocity(l, r)
end

local function mixed_drive(angle)
   local lin = FORWARD_SPEED * math.max(0, math.cos(angle))
   local rot = TURN_SPEED    * angle
   set_wheels(lin - rot, lin + rot)
end

local function front_prox()
   local m = 0
   for i = 1, 4  do m = math.max(m, robot.proximity[i].value) end
   for i = 20, 24 do m = math.max(m, robot.proximity[i].value) end
   return m
end

local function avg_ground()
   local s = 0
   for i = 1, 4 do s = s + robot.motor_ground[i].value end
   return s / 4
end

-- debug log only on fb0
local function dbg(msg)
   if robot.id == "fb0" then
      log(string.format("[t=%d] %s", step_id, msg))
   end
end

----------------------------------------------------------
--  GLOBAL STATE
----------------------------------------------------------
state                = STATE_WANDER
target_angle         = 0
lost_counter         = 0
carrying             = false
carry_turn_steps     = 0
turning_dir          = 1
cross_steps          = 0
ignore_food_steps    = 0
prelock_steps        = 0      -- counts down while crossing DROP_MARGIN
step_id              = 0
has_seen_food        = false
has_gone_to_food     = false
has_crossed_nest     = false
carry_floor_reference= NEST_DARK - FLOOR_DIFF - 0.01
pending_nest_drop    = false -- indicates we still have to drop after the 180° nest-turn
curve_steps          = 0
curve_dir            = 1         -- +1 or –1 (CW / CCW)
dragging_early_stop  = 0
alpha                = ALPHA_START       -- current annealed value


----------------------------------------------------------
--  INIT
----------------------------------------------------------
function init()
   robot.colored_blob_omnidirectional_camera.enable()
   robot.gripper.unlock()
   robot.leds.set_all_colors("blue")
   dbg("INIT: starting in WANDER")
end

----------------------------------------------------------
--  MAIN LOOP
----------------------------------------------------------
function step()
   -------------------------------------------------- PERCEPTION
   local fprox    = front_prox()
   local wall_hit = OBSTACLE_AVOIDANCE_ENABLED and (fprox > PROX_WALL)

   local food_seen, food_ang, best_abs = false, 0, math.huge
   local yellow_front = false

   for _, b in ipairs(robot.colored_blob_omnidirectional_camera) do
      local c = b.color
      if is_yellow(c) and math.abs(b.angle) < 0.30 then
         yellow_front = true
      elseif is_red(c) and math.abs(b.angle) < best_abs then
         food_seen, food_ang, best_abs = true, b.angle, math.abs(b.angle)
      end
   end

   -- Identify darker floor as potential nest edge
   if avg_ground() < carry_floor_reference then
      carry_floor_reference = avg_ground()
      log("NEST candidate → floor ref = " .. string.format("%.2f", carry_floor_reference))
   end

   -------------------------------------------------- FSM TRANSITIONS
   if state == STATE_WANDER then
      if food_seen and ignore_food_steps < 1 then
         state, target_angle, lost_counter = STATE_APPROACH, food_ang, 0
         if not has_seen_food then
            has_seen_food = true
            log(string.format("I SEE FOOD! angle=%.2f", food_ang))
         end
      end

   elseif state == STATE_APPROACH then
      if food_seen then
         target_angle, lost_counter = food_ang, 0
         if not has_gone_to_food then
            has_gone_to_food = true
            log(string.format("APPROACHING food: angle=%.2f", food_ang))
         end
      else
         lost_counter = lost_counter + 1
         if lost_counter > LOST_TIMEOUT then
            state = STATE_WANDER
            log("LOST food → back to WANDER")
         end
      end

      -- Grab sequence (two-phase: cross + lock_negative)
    if fprox > PROX_GRAB and math.abs(target_angle) < CENTER_EPS then
        prelock_steps       = CROSS_STEPS        -- move forward first
        cross_steps         = CROSS_STEPS        
        state               = STATE_CARRY        -- will lock after crossing
        dragging_early_stop = DRAGGING_EARLY_STOP_STEPS -- will stop the STATE_CARRY after this
        carrying            = false              -- not yet!
        carry_turn_steps    = 20                 -- 180° spin scheduled later
        turning_dir         = robot.random.bernoulli()==1 and 1 or -1
        log("FOOD aligned: crossing "..DROP_MARGIN.." m before rear-lock")
    end


   elseif state == STATE_CARRY then
        if dragging_early_stop > 0 then
            dragging_early_stop = dragging_early_stop - 1 
        end
        if dragging_early_stop == 0 then
            robot.gripper.unlock()           -- drop whatever we still drag
            state             = STATE_WANDER
            ignore_food_steps = CROSS_STEPS  -- cool-down before new hunt
            log("EARLY-STOP → could not nest: drop & resume wander")
        end
      -- drop logic handled in ACTIONS
   end

   -- ignore new food alerts for a bit
      if ignore_food_steps > 0 then
        set_wheels(FORWARD_SPEED, FORWARD_SPEED)
         ignore_food_steps = ignore_food_steps - 1
      end

   -------------------------------------------------- ACTIONS & LEDs
   if state == STATE_WANDER then
      robot.leds.set_all_colors("blue")
      if yellow_front and fprox > PROX_GRAB and OBSTACLE_AVOIDANCE_ENABLED then
         set_wheels(-TURN_SPEED, TURN_SPEED)
         log("BUMPED ROBOT → bouncing")
      elseif wall_hit then
         robot.leds.set_all_colors("purple")
         local dir = robot.random.bernoulli() == 1 and 1 or -1
         set_wheels(dir*FORWARD_SPEED*0.5, -dir*FORWARD_SPEED*0.5)
         -- log("WALL ahead → turning")
      else
         set_wheels(FORWARD_SPEED, FORWARD_SPEED)
      end

   elseif state == STATE_APPROACH then
      robot.leds.set_all_colors("yellow")
      mixed_drive(target_angle)

   elseif state == STATE_CARRY then
      robot.leds.set_all_colors("green")

      if wall_hit  then
         local dir = robot.random.bernoulli() == 1 and 1 or -1
         set_wheels(dir*FORWARD_SPEED*0.5, -dir*FORWARD_SPEED*0.5)
         -- log("WALL ahead → turning")
      end

      -- Phase 0: drive forward until object is behind, then lock_negative
        if prelock_steps > 0 then
            set_wheels(FORWARD_SPEED, FORWARD_SPEED)
            prelock_steps = prelock_steps - 1
            if prelock_steps == 0 then
                robot.gripper.lock_negative()
                carrying = true
                log("LOCK_NEGATIVE performed: object now behind")
            end
            return       -- skip the rest of STATE_CARRY until rear-lock done
        end

      -- Phase 1: cross the DROP_MARGIN distance
      if cross_steps > 0 then
         set_wheels(FORWARD_SPEED, FORWARD_SPEED)
         cross_steps = cross_steps - 1

      -- Phase 2: in-place 180° turn
      elseif carry_turn_steps > 0 then
         set_wheels(turning_dir*TURN_SPEED, -turning_dir*TURN_SPEED)
         carry_turn_steps = carry_turn_steps - 1

      -- Phase 3: decide drop & random‐turn vs go straight
            -- Phase 3: once cross & initial turn are done, decide what to do
            -- Phase 3: after cross_margin & initial turn
      else
         local g = avg_ground()
         if g < carry_floor_reference + FLOOR_DIFF then -- the supposed nest is here
            ignore_food_steps = IGNORE_STEPS
            if not has_crossed_nest then
               has_crossed_nest = true
               cross_steps = CROSS_STEPS
            elseif cross_steps < 1 then
                if not pending_nest_drop then
                    -- We are in the nest: schedule a 180° turn first
                    carry_turn_steps  = 20                   -- 180° spin (approx)
                    turning_dir       = robot.random.bernoulli()==1 and 1 or -1
                    pending_nest_drop = true                 -- drop after spin
                    dbg("IN NEST → spinning 180° to place food inside")
                    set_wheels(turning_dir*TURN_SPEED, -turning_dir*TURN_SPEED)
                elseif pending_nest_drop and carry_turn_steps < 1 then
                    -- 180° finished → now drop the item
                    robot.gripper.unlock()
                    carrying             = false
                    dragging_early_stop  = 0
                    if robot.random.uniform() < alpha then
                        log("DROP in nest & random-turn away")
                        local theta = math.pi/2 + robot.random.uniform()*math.pi
                        carry_turn_steps = math.ceil(theta/(TURN_SPEED*0.1))
                        turning_dir = (theta > 0) and 1 or -1
                        state = STATE_WANDER -- finished the drop, go back to wander
                    else
                        log("DROP in nest & curved escape")
                        curve_steps = ARC_STEPS
                        curve_dir   = (robot.random.bernoulli()==1) and 1 or -1
                        state       = STATE_CURVE
                    end
                    has_crossed_nest = false
                    -- state = STATE_WANDER
                    -- set_wheels(FORWARD_SPEED, FORWARD_SPEED)
                end
            end
            
         else
            -- **fallback**: no actual nest here, so just move forward once
            -- log("No nest found after margin → moving forward")
            ignore_food_steps = CROSS_STEPS
            set_wheels(FORWARD_SPEED, FORWARD_SPEED)
         end
      end
    elseif state == STATE_CURVE then
        robot.leds.set_all_colors("blue")          -- back to normal colour

        if curve_steps > 0 then
            -- outer wheel at full speed, inner wheel slowed by ARC_BIAS
            if curve_dir == 1 then
                set_wheels(FORWARD_SPEED,
                            FORWARD_SPEED * ARC_BIAS)
            else
                set_wheels(FORWARD_SPEED * ARC_BIAS,
                            FORWARD_SPEED)
            end
            curve_steps = curve_steps - 1
        else
            -- escape completed → resume wandering
            state = STATE_WANDER
            set_wheels(FORWARD_SPEED, FORWARD_SPEED)
        end
   end

   -------------------------------------------------- REFRESH CAMERA
   robot.colored_blob_omnidirectional_camera.disable()
   robot.colored_blob_omnidirectional_camera.enable()

   -- simulated-annealing schedule: α(t) = 1 – e^(–t/τ)
    alpha = ALPHA_TARGET - (ALPHA_TARGET - ALPHA_START) *
                        math.exp( -step_id / ALPHA_TAU )
    
    if step_id % 1000 == 0 then
        log(string.format("annealed alpha = %.3f", alpha))
    end

   step_id = step_id + 1
end

----------------------------------------------------------
--  RESET / DESTROY
----------------------------------------------------------
function reset()
   state, target_angle, lost_counter = STATE_WANDER, 0, 0
   carrying, carry_turn_steps         = false, 0
   cross_steps, ignore_food_steps     = 0, 0
   curve_steps, dragging_early_stop   = 0, 0
   curve_dir                          = 1
   prelock_steps                      = 0
   turning_dir                        = 1
   carry_floor_reference              = NEST_DARK - FLOOR_DIFF - 0.01
   has_seen_food, has_gone_to_food    = false, false
   pending_nest_drop                  = false
   robot.gripper.unlock()
   robot.leds.set_all_colors("blue")
   step_id = 0
end

function destroy() end