--[[ 
  Swarm-Bot Foraging Controller
  Author: Alexandre Le Mercier (ULB, alexandre.le.mercier@ulb.be)

  Description:
  This Lua script implements a swarm-based foraging behavior for ARGoS footbots.
  It extends the INDI-BOT architecture by introducing cooperative mechanisms under
  the SWARM-BOT paradigm, including stigmergic signaling and Lennard-Jones-based flocking.

  Key Features:
    - Finite State Machine with multiple roles: WANDER, APPROACH, CARRY, NEST_ALERT
    - LED-based stigmergy for food detection, carrying, and nest location broadcast
    - Lennard-Jones potential-based flocking to promote organized exploration
    - Adaptive annealing for balancing exploration and exploitation
    - Obstacle avoidance and randomized motion to reduce congestion

  Experimental Modes:
    - Configurable via boolean switches (e.g., USE_GOOD_NEST_METHOD, USE_FLOCKING_DURING_WANDER)
    - Behavior can be adjusted to simulate variations in cooperation, message propagation, and carrying strategy

  Note:
    This script adheres to the constraints of the INFO-H-414 final project (Constrained Foraging),
    with all swarm behavior implemented under reactive and decentralized assumptions.
]]


-- ---------------------------------------------------------
--  CONFIGURATION SWITCH
-- ---------------------------------------------------------
OBSTACLE_AVOIDANCE_ENABLED = true

USE_VANISHING_DRAGGING_STEPS = false
FOOD_MESSAGE_PROPAGATION = true
USE_ANCHOR_METHOD = false
USE_BAD_NEST_METHOD = false
USE_GOOD_NEST_METHOD = true
SHOULD_LOCK_POSITIVE = true

USE_FLOCKING_DURING_WANDER = true
USE_FLOCKING_DURING_APPROACH_FOOD = false
USE_FLOCKING_DURING_APPROACH_NEIGHBOR = true
USE_FLOCKING_DURING_CARRY = false

-- ---------------------------------------------------------
--  CONSTANTS
-- ---------------------------------------------------------
FORWARD_SPEED   = 30
TURN_SPEED      = 30

CENTER_EPS      = 0.05   -- rad (~3°)
PROX_GRAB       = 0.9    -- front proximity for grabbing
PROX_WALL       = 0.30   -- front proximity for walls
PROX_BOT        = 1.00
LOST_TIMEOUT    = 5      -- steps to remember lost food
NEST_DARK       = 0.98   -- avg ground < this = nest
FLOOR_DIFF      = 0.01   -- avg ground diff to detect nest

ALPHA_START  = 0.10       -- initial α  (very exploratory)
ALPHA_TARGET = 1.00       -- final α    (always random-turn)
ALPHA_TAU    = 3000        -- time-constant (in steps) of the rise

DROP_MARGIN     = 9.00   -- cm to move past the grab point
GO2ANCHOR_MARGIN= 20.0
IGNORE_MARGIN   = 100    -- after deposing food, ignore new food for this distance
IGNORE_ORANGE   = 30     -- same but regarding neighbors
KEEP_ORANGE     = 10     -- should be lower than IGNORE_ORANGE
KEEP_NEST_ALERT = 30     -- for the USE_GOOD_NEST_METHOD method
DRAGGING_MARGIN = 500    -- cm to move past the grab point
ARC_STEPS       = 20     -- number of 0.1 s steps for curved move
ARC_BIAS        = 0.1    -- inner-wheel speed factor (0‒1)

-- flocking (Lennard-Jones) --------------------------------
TARGET_DIST = 100          -- desired inter-robot distance   [cm]
EPSILON     = 50          -- interaction strength factor
FLOCKING_PROBA = 0.75     -- probability to ignore flocking at each step


-- compute number of steps  X cm (0.1 s per step)
local CROSS_STEPS              = math.ceil(DROP_MARGIN * 10 / FORWARD_SPEED)
local GO2ANCHOR_STEPS          = math.ceil(GO2ANCHOR_MARGIN * 10 / FORWARD_SPEED)
local IGNORE_STEPS             = math.ceil(IGNORE_MARGIN * 10 / FORWARD_SPEED)
local IGNORE_NEI_STEPS         = math.ceil(IGNORE_ORANGE * 10 / FORWARD_SPEED)
local KEEP_ORANGE_STEPS        = math.ceil(KEEP_ORANGE * 10 / FORWARD_SPEED)
local KEEP_NEST_ALERT_STEPS   = math.ceil(KEEP_NEST_ALERT * 10 / FORWARD_SPEED)
local DRAGGING_EARLY_STOP_STEPS= math.ceil(DRAGGING_MARGIN * 10 / FORWARD_SPEED)

STATE_WANDER     = 0
STATE_APPROACH   = 1
STATE_CARRY      = 2
STATE_CURVE      = 3         -- temporary state after a straight drop
STATE_ANCHOR_1   = 4
STATE_NEST_ALERT = 5

-- ---------------------------------------------------------
--  COLOUR TESTS
-- ---------------------------------------------------------
local function is_red(c)
   return c.red   > 200 and c.green <  80 and c.blue <  80
end

local function is_yellow(c)
   return c.red   > 200 and c.green > 200 and c.blue < 100
end

local function is_green(c)  -- colour of a robot that is already carrying
   return c.green > 200 and c.red < 80 and c.blue < 80
end

local function is_blue(c)
   return c.blue  > 200 and c.red < 80 and c.green < 80
end

local function is_purple(c)
   return c.red   > 200 and c.green < 80 and c.blue > 200
end

local function is_orange(c)
   return c.red   > 200 and c.green > 100 and c.blue < 80
end

-- ---------------------------------------------------------
--  HELPER FUNCTIONS (must come before init)
-- ---------------------------------------------------------
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

-- Lennard-Jones helpers -----------------------------------
local function ComputeLennardJones(dist)
   -- dist is in cm; avoid div-by-zero
   if dist<=0 then return 0 end
   local d  = TARGET_DIST / dist
   local d2 = d*d
   local d4 = d2*d2
   return -(4*EPSILON/dist)*(d4 - d2)      -- attractive if far, repulsive if close
end

local function ProcessRAB_LJ()
   local sum_x, sum_y = 0,0
   for i=1,#robot.range_and_bearing do
      local m   = robot.range_and_bearing[i]
      local lj  = ComputeLennardJones(m.range)
      sum_x = sum_x + math.cos(m.horizontal_bearing)*lj
      sum_y = sum_y + math.sin(m.horizontal_bearing)*lj
   end
   return {sum_x,sum_y}
end
-- ---------------------------------------------------------

-- debug log only on fb0
local function dbg(msg)
   if robot.id == "fb0" then
      -- log(string.format("[t=%d] %s", step_id, msg))
   end
end

-- ---------------------------------------------------------
--  GLOBAL STATE
-- ---------------------------------------------------------
state                = STATE_WANDER
target_angle         = 0
lost_counter         = 0
carrying             = false
carry_turn_steps     = 0
go2anchor_steps      = 0
turning_dir          = 1
cross_steps          = 0
ignore_food_steps    = 0
ignore_nei_steps     = IGNORE_NEI_STEPS
keep_orange_steps    = 0
keep_nest_alert_steps= 0
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
chasing_food         = false

-- ---------------------------------------------------------
--  INIT
-- ---------------------------------------------------------
function init()
   robot.colored_blob_omnidirectional_camera.enable()
   robot.gripper.unlock()
   robot.leds.set_all_colors("blue")
   dbg("INIT: starting in WANDER")
end

-- ---------------------------------------------------------
--  MAIN LOOP
-- ---------------------------------------------------------
function step()
   -------------------------------------------------- PERCEPTION
   local fprox    = front_prox()
   local wall_hit = OBSTACLE_AVOIDANCE_ENABLED and (fprox > PROX_WALL)

   local food_seen, food_ang, best_abs = false, 0, math.huge
   local yellow_ang, orange_ang = 0, 0
   local yellow_seen = false
   local green_seen   = false
   local blue_seen    = false
   local purple_seen  = false
   local orange_seen  = false 

   for _, b in ipairs(robot.colored_blob_omnidirectional_camera) do
      -- and math.abs(b.angle) < best_abs
      local c = b.color
      if is_yellow(c) and math.abs(b.angle) < best_abs then
         yellow_seen, yellow_ang, best_abs = true, b.angle, math.abs(b.angle)
      elseif is_red(c) and math.abs(b.angle) < best_abs then
         food_seen, food_ang, best_abs = true, b.angle, math.abs(b.angle)
      elseif is_green(c) then
         green_seen = true            -- another robot already engaged
      elseif is_blue(c) then
         blue_seen = true
      elseif is_purple(c) then
         purple_seen = true
      elseif is_orange(c) and math.abs(b.angle) < best_abs  then
         orange_seen, orange_ang, best_abs = true, b.angle, math.abs(b.angle)
      end
   end

   -- Identify darker floor as potential nest edge
   if avg_ground() < carry_floor_reference then
      carry_floor_reference = avg_ground()
      -- log("NEST candidate → floor ref = " .. string.format("%.2f", carry_floor_reference))
   end

   if keep_orange_steps > 0 and state ~= STATE_CARRY then
      keep_orange_steps = keep_orange_steps - 1
      robot.leds.set_all_colors("orange")
   end

   -------------------------------------------------- REFRESH CAMERA
   robot.colored_blob_omnidirectional_camera.disable()
   robot.colored_blob_omnidirectional_camera.enable()

   -- simulated-annealing schedule: α(t) = 1 – e^(–t/τ)
   alpha = ALPHA_TARGET - (ALPHA_TARGET - ALPHA_START) * math.exp(-step_id / ALPHA_TAU)
   if step_id % 1000 == 0 then
      --log(string.format("annealed alpha = %.3f", alpha))
   end

   step_id = step_id + 1

   -------------------------------------------------- FSM TRANSITIONS
   if state == STATE_WANDER then
      if green_seen or blue_seen or purple_seen then
         local dir = robot.random.bernoulli() == 1 and 1 or -1
         set_wheels(dir*FORWARD_SPEED*0.2, -dir*FORWARD_SPEED*0.2)
      end

      if purple_seen then -- update nest information if necessary
         local g = avg_ground()
         if g < carry_floor_reference + FLOOR_DIFF then
            carry_floor_reference = carry_floor_reference - FLOOR_DIFF
         end
      end

      -- It is important to note here that red is a priority to orange, hence the "elseif"
      if food_seen and ignore_food_steps < 1 then
         state, target_angle, lost_counter = STATE_APPROACH, food_ang, 0
         chasing_food = true
         if not has_seen_food then
            has_seen_food = true
            --log(string.format("I SEE FOOD! angle=%.2f", food_ang))
         end
      elseif orange_seen and ignore_food_steps < 1 then
         state, target_angle, lost_counter = STATE_APPROACH, orange_ang, 0
         chasing_food = false
         if not has_seen_food then
            has_seen_food = true
            --log(string.format("I SEE FOOD! angle=%.2f", orange_ang))
         end
      end

      if alpha > 0.5
      -- and avg_ground() < carry_floor_reference + FLOOR_DIFF
      and (not yellow_seen)
      and USE_ANCHOR_METHOD
      then
         -- log("MOVE TO ANCHOR 1")
         state = STATE_ANCHOR_1
       
      end

   elseif state == STATE_APPROACH then
      
         if food_seen then
            if green_seen then
               if FOOD_MESSAGE_PROPAGATION then
                  robot.leds.set_all_colors("green")
                  ignore_nei_steps = IGNORE_NEI_STEPS
               end
               state = STATE_WANDER
               local dir = robot.random.bernoulli() == 1 and 1 or -1
               set_wheels(dir*FORWARD_SPEED*0.2, -dir*FORWARD_SPEED*0.2)
               ignore_food_steps = math.ceil(IGNORE_STEPS/4)
            else
               target_angle, lost_counter = food_ang, 0
               if not has_gone_to_food then
                  has_gone_to_food = true
                  --log(string.format("APPROACHING food: angle=%.2f", food_ang))
               end
            end
         else
            lost_counter = lost_counter + 1
            if lost_counter > LOST_TIMEOUT then
               state = STATE_WANDER
               --log("LOST food → back to WANDER")
            end
         end

         -- Grab sequence (two-phase: cross + lock_negative)
         if fprox > PROX_GRAB and math.abs(target_angle) < CENTER_EPS then
            prelock_steps       = CROSS_STEPS        -- move forward first
            cross_steps         = CROSS_STEPS        
            state               = STATE_CARRY        -- will lock after crossing
            if USE_VANISHING_DRAGGING_STEPS then
               dragging_early_stop = math.ceil(DRAGGING_EARLY_STOP_STEPS * (1 - alpha + ALPHA_START))
            else
               dragging_early_stop = DRAGGING_EARLY_STOP_STEPS -- will stop STATE_CARRY after this
            end
            carrying            = false              -- not yet!
            if SHOULD_LOCK_POSITIVE then robot.gripper.lock_positive() end
            carry_turn_steps    = math.ceil(200/TURN_SPEED)                 -- 180° spin later
            turning_dir         = robot.random.bernoulli()==1 and 1 or -1
            --log("FOOD aligned: crossing "..DROP_MARGIN.." cm before rear-lock")
         end
      

   elseif state == STATE_CARRY then
      chasing_food = false -- stopped chasing
      if green_seen or blue_seen or purple_seen then
         local dir = robot.random.bernoulli() == 1 and 1 or -1
         set_wheels(dir*FORWARD_SPEED*0.2, -dir*FORWARD_SPEED*0.2)
      end
      if dragging_early_stop > 0 then
         dragging_early_stop = dragging_early_stop - 1
      end
      if dragging_early_stop == 0 then
         robot.gripper.unlock()           -- drop whatever we still drag
         state             = STATE_WANDER
         ignore_food_steps = CROSS_STEPS  -- cool-down before new hunt
         --log("EARLY-STOP → could not nest: drop & resume wander")
      end
      -- drop logic handled in ACTIONS
   end

   -- ignore new food alerts for a bit (cool-down)
   if ignore_food_steps > 0 then
      set_wheels(FORWARD_SPEED, FORWARD_SPEED)
      ignore_food_steps = ignore_food_steps - 1
   end

   -------------------------------------------------- ACTIONS & LEDs
   if state == STATE_WANDER then

      local g = avg_ground()
      if g < NEST_DARK + FLOOR_DIFF and g/4 > carry_floor_reference + FLOOR_DIFF then
         -- detected a suboptimal nest location
         if USE_BAD_NEST_METHOD then robot.leds.set_all_colors("purple") end
      else
         robot.leds.set_all_colors("blue")
      end

      if purple_seen then -- means the nest is too close, so needs to explore elsewhere
            local dir = robot.random.bernoulli() == 1 and 1 or -1
            set_wheels(dir*FORWARD_SPEED*0.5, -dir*FORWARD_SPEED*0.5)
            return
      end

      if fprox > PROX_GRAB and OBSTACLE_AVOIDANCE_ENABLED then
         set_wheels(-TURN_SPEED, TURN_SPEED)
         --log("BUMPED ROBOT → bouncing")
      elseif wall_hit then
         -- robot.leds.set_all_colors("purple")
         local dir = robot.random.bernoulli() == 1 and 1 or -1
         set_wheels(dir*FORWARD_SPEED*0.3, -dir*FORWARD_SPEED*0.3)
      else
            local lj_vec = ProcessRAB_LJ()
            local len2   = lj_vec[1]*lj_vec[1] + lj_vec[2]*lj_vec[2]
            if len2 > 1e-3 and USE_FLOCKING_DURING_WANDER and robot.random.uniform() > FLOCKING_PROBA then                       -- non-zero vector?
               local ang = math.atan2(lj_vec[2],lj_vec[1])
               mixed_drive(ang)                      -- convert to wheel speeds
            else
               set_wheels(FORWARD_SPEED,FORWARD_SPEED) -- fall back to straight
            end
      end
      if go2anchor_steps < 1 then go2anchor_steps = GO2ANCHOR_STEPS end

   elseif state == STATE_APPROACH then
         if purple_seen then -- nest too close
            ignore_food_steps = IGNORE_STEPS
            state = STATE_WANDER
            return
         end
         if FOOD_MESSAGE_PROPAGATION and ignore_nei_steps < 1 then
            -- robot.leds.set_all_colors("orange")
            keep_orange_steps = KEEP_ORANGE_STEPS
         elseif FOOD_MESSAGE_PROPAGATION and ignore_nei_steps > 0 then -- cooldown
            ignore_nei_steps = ignore_nei_steps - 1
         end
         if chasing_food then
            local lj_vec = ProcessRAB_LJ()
            local len2   = lj_vec[1]*lj_vec[1] + lj_vec[2]*lj_vec[2]
            if len2 > 1e-3 and USE_FLOCKING_DURING_APPROACH_FOOD and robot.random.uniform() > FLOCKING_PROBA then                       -- non-zero vector?
               local ang = math.atan2(lj_vec[2],lj_vec[1])
               mixed_drive(ang)                      -- convert to wheel speeds
            else
               if avg_ground() > carry_floor_reference + FLOOR_DIFF then
                  mixed_drive(target_angle)
               else
                  if USE_GOOD_NEST_METHOD then
                     -- log("Good nest alert!")
                     keep_nest_alert_steps = KEEP_NEST_ALERT_STEPS
                     state = STATE_NEST_ALERT
                     return
                  end
                  ignore_food_steps = IGNORE_STEPS
                  state = STATE_WANDER
               end
            end
         else
            local lj_vec = ProcessRAB_LJ()
            local len2   = lj_vec[1]*lj_vec[1] + lj_vec[2]*lj_vec[2]
            if len2 > 1e-3 and USE_FLOCKING_DURING_APPROACH_NEIGHBOR and robot.random.uniform() > FLOCKING_PROBA then                       -- non-zero vector?
               local ang = math.atan2(lj_vec[2],lj_vec[1])
               mixed_drive(ang)                      -- convert to wheel speeds
            else
               if avg_ground() > carry_floor_reference + FLOOR_DIFF then
                  mixed_drive(target_angle)
               else
                  ignore_food_steps = IGNORE_STEPS
                  state = STATE_WANDER
               end
            end
         end

   elseif state == STATE_CARRY then
      robot.leds.set_all_colors("green")

      -- Phase 0: drive forward until object is behind, then lock_negative
      if prelock_steps > 0 then
         set_wheels(FORWARD_SPEED, FORWARD_SPEED)
         prelock_steps = prelock_steps - 1
         if prelock_steps == 0 then
            if not SHOULD_LOCK_POSITIVE then robot.gripper.lock_negative() end
            carrying = true
            --log("LOCK_NEGATIVE performed: object now behind")
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

      elseif yellow_seen and avg_ground() > carry_floor_reference + FLOOR_DIFF then
         if go2anchor_steps > 0 then
            go2anchor_steps = go2anchor_steps - 1
            mixed_drive(yellow_ang)
         else
            ignore_food_steps = IGNORE_STEPS
            if not has_crossed_nest then
               has_crossed_nest = true
               -- cross_steps = CROSS_STEPS
            elseif cross_steps < 1 then
               if not pending_nest_drop then
                  -- We are in the nest: schedule a 180° turn first
                  carry_turn_steps  = math.ceil(200/TURN_SPEED)   -- 180° spin
                  turning_dir       = robot.random.bernoulli()==1 and 1 or -1
                  pending_nest_drop = true
                  dbg("IN NEST → spinning 180° to place food inside")
                  set_wheels(turning_dir*TURN_SPEED, -turning_dir*TURN_SPEED)
               elseif pending_nest_drop and carry_turn_steps < 1 then
                  -- 180° finished → now drop the item
                  robot.gripper.unlock()
                  carrying             = false
                  dragging_early_stop  = 0
                  if robot.random.uniform() < alpha then
                     --log("DROP in nest & random-turn away")
                     local theta = math.pi/2 + robot.random.uniform()*math.pi
                     carry_turn_steps = math.ceil(theta/(TURN_SPEED*0.1))
                     turning_dir = (theta > 0) and 1 or -1
                     state = STATE_WANDER
                  else
                     --log("DROP in nest & curved escape")
                     curve_steps = ARC_STEPS
                     curve_dir   = (robot.random.bernoulli()==1) and 1 or -1
                     state       = STATE_CURVE
                  end
                  has_crossed_nest = false
               end
            end
         end

      -- Phase 3: nest detection & drop
      else
         -- robot.leds.set_all_colors("blue")
         local g = avg_ground()
         if g < carry_floor_reference + FLOOR_DIFF then -- the supposed nest is here
            ignore_food_steps = IGNORE_STEPS
            if not has_crossed_nest then
               has_crossed_nest = true
               cross_steps = CROSS_STEPS
            elseif cross_steps < 1 then
               if not pending_nest_drop then
                  -- We are in the nest: schedule a 180° turn first
                  carry_turn_steps  = math.ceil(200/TURN_SPEED)   -- 180° spin
                  turning_dir       = robot.random.bernoulli()==1 and 1 or -1
                  pending_nest_drop = true
                  dbg("IN NEST → spinning 180° to place food inside")
                  set_wheels(turning_dir*TURN_SPEED, -turning_dir*TURN_SPEED)
               elseif pending_nest_drop and carry_turn_steps < 1 then
                  -- 180° finished → now drop the item
                  robot.gripper.unlock()
                  carrying             = false
                  dragging_early_stop  = 0
                  if robot.random.uniform() < alpha then
                     --log("DROP in nest & random-turn away")
                     local theta = math.pi/2 + robot.random.uniform()*math.pi
                     carry_turn_steps = math.ceil(theta/(TURN_SPEED*0.1))
                     turning_dir = (theta > 0) and 1 or -1
                     state = STATE_WANDER
                  else
                     --log("DROP in nest & curved escape")
                     curve_steps = ARC_STEPS
                     curve_dir   = (robot.random.bernoulli()==1) and 1 or -1
                     state       = STATE_CURVE
                  end
                  has_crossed_nest = false
               end
            end

         else
            -- fallback: no actual nest here, just move forward once

            local lj_vec = ProcessRAB_LJ()
            local len2   = lj_vec[1]*lj_vec[1] + lj_vec[2]*lj_vec[2]
            if len2 > 1e-3 and USE_FLOCKING_DURING_CARRY and robot.random.uniform() > FLOCKING_PROBA then                       -- non-zero vector?
               local ang = math.atan2(lj_vec[2],lj_vec[1])
               mixed_drive(ang)                      -- convert to wheel speeds
            else
               set_wheels(FORWARD_SPEED, FORWARD_SPEED) -- fall back to straight
            end

            ignore_food_steps = CROSS_STEPS
            
         end
      end

   elseif state == STATE_CURVE then
      robot.leds.set_all_colors("blue")
      if curve_steps > 0 then
         if curve_dir == 1 then
            set_wheels(FORWARD_SPEED, FORWARD_SPEED * ARC_BIAS)
         else
            set_wheels(FORWARD_SPEED * ARC_BIAS, FORWARD_SPEED)
         end
         curve_steps = curve_steps - 1
      else
         state = STATE_WANDER
         set_wheels(FORWARD_SPEED, FORWARD_SPEED)
         if wall_hit then
            local dir = robot.random.bernoulli() == 1 and 1 or -1
            set_wheels(dir*FORWARD_SPEED*0.5, -dir*FORWARD_SPEED*0.5)
         end
      end

   elseif state == STATE_NEST_ALERT then
      -- send a message to other bots not to search food here
      set_wheels(0, 0)
      robot.leds.set_all_colors("purple")
      if keep_nest_alert_steps < 1 then
         state = STATE_WANDER
         ignore_food_steps = IGNORE_STEPS*3
      else
         keep_nest_alert_steps = keep_nest_alert_steps - 1
      end
   
   elseif state == STATE_ANCHOR_1 then
      robot.leds.set_all_colors("yellow")
      set_wheels(0, 0)
      if yellow_seen then state = STATE_WANDER end
      if food_seen and ignore_food_steps < 1 then
         state, target_angle, lost_counter = STATE_APPROACH, food_ang, 0
         if not has_seen_food then
            has_seen_food = true
            --log(string.format("I SEE FOOD! angle=%.2f", food_ang))
         end
      end
   end
end

-- ---------------------------------------------------------
--  RESET / DESTROY
-- ---------------------------------------------------------
function reset()
   state, target_angle, lost_counter = STATE_WANDER, 0, 0
   carrying, carry_turn_steps        = false, 0
   cross_steps, ignore_food_steps    = 0, 0
   curve_steps, dragging_early_stop  = 0, 0
   curve_dir                         = 1
   prelock_steps                     = 0
   turning_dir                       = 1
   carry_floor_reference             = NEST_DARK - FLOOR_DIFF - 0.01
   has_seen_food, has_gone_to_food   = false, false
   pending_nest_drop, chasing_food   = false, false
   go2anchor_steps                   = 0, 0
   ignore_nei_steps                  = 0
   keep_nest_alert_steps             = 0
   robot.gripper.unlock()
   step_id = 0
end

function destroy() end
