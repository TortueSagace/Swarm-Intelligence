----------------------------------------------------------
--  GLOBAL STATE                                        --
----------------------------------------------------------
local id_num                 -- numeric part of robot.id (0-9)
local behaviour = {}         -- holds init()/step() for this robot
local direction = 1          -- used by behaviour 4 (ping-pong)
local tick = 0               -- counts simulation steps (0.1 s each)
local started = false        -- becomes true when our 5-second window opens
local SLOT_LEN = 50          -- 50 ticks × 0.1 s = 5 s
----------------------------------------------------------
--  TEXT DESCRIPTIONS (for log output)                  --
----------------------------------------------------------
local behaviour_name = {
   [0]="forward 15 cm/s",
   [1]="rotate in place",
   [2]="backward arch",
   [3]="circle + print proximities",
   [4]="ping-pong front/back",
   [5]="LED red on black patch",
   [6]="LED encodes obstacles",
   [7]="broadcast ID + print neighbours",
   [8]="random LED + print seen colours",
   [9]="*** idle ***"
}

----------------------------------------------------------
--  AUXILIARY HELPERS                                   --
----------------------------------------------------------
local function max_proximity(min_ang,max_ang)
   local max_val = 0
   for _,p in ipairs(robot.proximity) do
      if p.angle>=min_ang and p.angle<=max_ang and p.value>max_val then
         max_val = p.value
      end
   end
   return max_val
end

local function random_rgb()      -- returns “R,G,B,255”
   local r = robot.random.uniform_int(0,255)
   local g = robot.random.uniform_int(0,255)
   local b = robot.random.uniform_int(0,255)
   return string.format("%d,%d,%d,255",r,g,b)
end

----------------------------------------------------------
--  BEHAVIOUR FACTORY (same behaviours as before)       --
----------------------------------------------------------
local behaviours = {
-- 0) forward -------------------------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(15,15) end
   function behaviour.step() end
end,
-- 1) rotate in place -----------------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(10,-10) end
   function behaviour.step() end
end,
-- 2) backward arch -------------------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(-10,-5) end
   function behaviour.step() end
end,
-- 3) circle + log proximity ----------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(10,5) end
   function behaviour.step()
      local out={}
      for i,p in ipairs(robot.proximity) do
         out[#out+1]=string.format("%d:%.2f",i,p.value)
      end
      log(table.concat(out," "))
   end
end,
-- 4) ping-pong -----------------------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(15,15) end
   function behaviour.step()
      local front=max_proximity(-0.5,0.5)
      local back =max_proximity( 2.6,3.7)
      if direction== 1 and front>0.2 then
         direction=-1; robot.wheels.set_velocity(-15,-15)
      elseif direction==-1 and back>0.2 then
         direction= 1; robot.wheels.set_velocity( 15, 15)
      end
   end
end,
-- 5) LED red on black ----------------------------------------
function()
   local white="white"
   function behaviour.init() robot.wheels.set_velocity(10,10) end
   function behaviour.step()
      local on_black=false
      for _,g in ipairs(robot.motor_ground) do if g.value==0 then on_black=true; break end end
      robot.leds.set_all_colors(on_black and "red" or white)
   end
end,
-- 6) LED encodes obstacles -----------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(10,10) end
   function behaviour.step()
      local front=max_proximity(-0.5,0.5)
      local back =max_proximity( 2.6,3.7)
      local colour
      if front>0.2 then        colour="red"
      elseif back>0.2 then     colour="blue"
      else                     colour="green"
      end
      robot.leds.set_all_colors(colour)
   end
end,
-- 7) broadcast ID + print neighbours -------------------------
function()
   local my_byte
   function behaviour.init()
      my_byte=tonumber(string.match(robot.id,"%d+"))
      robot.range_and_bearing.set_data(1,my_byte)
   end
   function behaviour.step()
      local ids={}
      for _,m in ipairs(robot.range_and_bearing) do ids[#ids+1]=m.data[1] end
      if #ids>0 then log("Neighbours: "..table.concat(ids,",")) end
   end
end,
-- 8) random LED + print seen colours -------------------------
function()
   local my_colour
   function behaviour.init()
      my_colour=random_rgb()
      robot.leds.set_all_colors(my_colour)
      robot.wheels.set_velocity(10,5)
      robot.colored_blob_omnidirectional_camera.enable()
   end
   function behaviour.step()
      local seen={}
      for _,b in ipairs(robot.colored_blob_omnidirectional_camera) do
         seen[#seen+1]=string.format("(%d,%d,%d)",
                                     b.color.red,b.color.green,b.color.blue)
      end
      if #seen>0 then log("Seen LEDs: "..table.concat(seen," ")) end
   end
end,
-- 9) idle ----------------------------------------------------
function()
   function behaviour.init() robot.wheels.set_velocity(0,0) end
   function behaviour.step() end
end
}

----------------------------------------------------------
--  STANDARD CALLBACKS                                   --
----------------------------------------------------------
function init()
   id_num = tonumber(string.match(robot.id,"%d+")) or 9
   if id_num>9 then id_num=9 end           -- safety clamp
   behaviours[id_num+1]()                 -- create the local behaviour
end

function step()
   tick = tick + 1

   -- compute window (0-based indexing)
   local window_start = id_num * SLOT_LEN + 1
   local window_end   = window_start + SLOT_LEN - 1

   if tick == window_start then           -- our 5-s slot just opened
      log(string.format(">>> fb%d performing: %s",
          id_num, behaviour_name[id_num]))
      if behaviour.init then behaviour.init() end
      started = true
   end

   if started and tick <= window_end then -- inside our slot
      if behaviour.step then behaviour.step() end
   elseif started and tick == window_end+1 then  -- slot ended
      robot.wheels.set_velocity(0,0)      -- stop
      started = false                     -- won’t run again
   end
end

function reset()
   tick=0; started=false
end

function destroy() end
