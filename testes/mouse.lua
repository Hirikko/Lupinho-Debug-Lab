-- testes/mouse.lua
local Utils = require "utils"
local M = {}
local sonic={ walk={}, roll={}, idle={}, loaded=false }
local drag = { active=false, dx=0, dy=0 }
drag.sprite = { x=220, y=174, vx=1.2, vy=0, rolling=false }

local function find_sonic_animations()
  local result={ walk={}, roll={}, idle={} }
  local seen={}
  local visited=0
  local MAX_NODES=5000
  local function walk(v,depth)
    if type(v)~="table" or seen[v] or depth>10 or visited>=MAX_NODES then return end
    seen[v]=true
    visited=visited+1
    local path=v.path
    if type(path)=="string" then
      if path:find("sprites/sonic/andar/f",1,true) then result.walk[#result.walk+1]=v end
      if path:find("sprites/sonic/rodar/f",1,true) then result.roll[#result.roll+1]=v end
      if path:find("sprites/sonic/parado/f",1,true) then result.idle[#result.idle+1]=v end
      if type(v.width)=="number" and type(v.height)=="number" then return end
    end
    for _,child in pairs(v) do
      if type(child)=="table" then walk(child,depth+1) end
      if visited>=MAX_NODES then break end
    end
  end
  if type(Sprites)=="table" then walk(Sprites,0) end
  local function sort_frames(t) table.sort(t, function(a,b) return tostring(a.path)<tostring(b.path) end) end
  sort_frames(result.walk); sort_frames(result.roll); sort_frames(result.idle)
  return result
end

local function load_sonic()
  if sonic.loaded then return end
  pcall(require,"sprites")
  local found=find_sonic_animations()
  sonic.walk=found.walk; sonic.roll=found.roll; sonic.idle=found.idle
  sonic.loaded=true
end

function M.update(input, frame)
  load_sonic()
  ui.cls(0)
  ui.print("TESTE DE MOUSE: ARRASTAR SONIC", 176, 10, 6)
  ui.rectfill(174,188,466,201,8)
  ui.rect(174,188,466,201,6)
  ui.rectfill(265,145,355,157,3)
  ui.rect(265,145,355,157,6)
  ui.print("CHAO", 180, 207, 1)
  ui.print("PLATAFORMA", 274, 132, 1)

  local mx, my = input.mx, input.my
  local left_now = input.left_now
  local s=drag.sprite

  if not drag.active then
    s.x=s.x+s.vx
    if s.x<190 or s.x>448 then s.vx=-s.vx end
  end

  if left_now and not input.previous_mouse_left then
    if mx>=s.x-16 and mx<=s.x+16 and my>=s.y-18 and my<=s.y+18 then
      drag.active=true; drag.dx=s.x-mx; drag.dy=s.y-my; s.vy=0; s.rolling=false
    end
  end

  if left_now and drag.active then
    s.x=Utils.clamp(mx+drag.dx,188,450); s.y=Utils.clamp(my+drag.dy,45,181); s.vy=0
  elseif not left_now and drag.active then
    drag.active=false; s.rolling=true; s.roll_start=frame or 0; s.vy=-1.5
  end

  if not drag.active then
    local old_y=s.y
    s.vy=(s.vy or 0)+0.22; s.y=s.y+s.vy
    local floor_y=174
    if s.x>=249 and s.x<=371 and old_y<=132 and s.y>=132 then floor_y=132 end
    if s.y>=floor_y then s.y=floor_y; s.vy=0; s.rolling=false end
  end

  local frames
  if drag.active then frames=sonic.idle
  elseif s.rolling then frames=sonic.roll
  else frames=sonic.walk end

  if #frames>0 then
    local idx=math.floor((frame or 0)/5)%#frames+1
    ui.spr(frames[idx], math.floor(s.x-12), math.floor(s.y-16), s.vx<0, false)
  else
    Utils.panel(s.x-10, s.y-12, 20, 24, drag.active and 6 or 4, 1)
    ui.circfill(s.x-4, s.y-4, 2, 1)
    ui.circfill(s.x+4, s.y-4, 2, 1)
  end

  local over_sonic = mx>=s.x-16 and mx<=s.x+16 and my>=s.y-18 and my<=s.y+18
  if over_sonic then
    ui.print(drag.active and "SEGURANDO" or "SPRITE_CPU", mx+8, Utils.clamp(my-24,30,245), drag.active and 6 or 1)
  end

  Utils.panel(174,236,292,23,8,6)
  ui.print("CLIQUE E ARRASTE | B RETORNA", 180, 243, 1)

  if Utils.pressed(BTN_X) then
    LupiDebug.state=LupiDebug.test_return_state
    LupiDebug.active_test=nil
    drag.active=false
  end
end
return M
