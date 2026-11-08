-- game.lua
SCREEN_W, SCREEN_H = 480, 270
VIEW_X, WORLD_MIN, WORLD_W = 160, 165, 1600
LUPI_HARDWARE_CONSTRAINTS = true
LUPI_LUA_WATCHDOG = true
LUPI_HARDWARE_DEBUG_OVERLAY = true
LUPI_HARDWARE_DEBUG_OVERLAY_RECT = { x0 = 0, y0 = 0, x1 = 164, y1 = 270, col = 2 }
LUPI_HARDWARE_DEBUG_OVERLAY_ALPHA = 0.5

require "palette"

local debug_ui_palette = {
  0x0000,0x7FFF,0x03E0,0x001F,
  0x7C00,0x03FF,0x7FE0,0x4210,
  0x2010,0x7C1F,0x02E0,0x401F,
  0x021F,0x5294,0x2D6B,0x5C2C
}

local raw_ui = {
  cls=ui.cls, print=ui.print, rect=ui.rect, rectfill=ui.rectfill,
  line=ui.line, trisfill=ui.trisfill, circ=ui.circ, circfill=ui.circfill
}

local reverse_palette = {}
for i, rgb in ipairs(Palette) do
  if not reverse_palette[rgb] then reverse_palette[rgb] = i - 1 end
end

local ui_color_map = {}
for color_index, rgb in ipairs(debug_ui_palette) do
  ui_color_map[color_index] = reverse_palette[rgb]
end

local function remap_color(c)
  if type(c) == "number" and c >= 0 and c < #debug_ui_palette then
    return ui_color_map[c+1] or c
  end
  return c
end

local function wrap_color_function(name, color_arg)
  local original = ui[name]
  if type(original) ~= "function" then return end
  ui[name] = function(...)
    local args = {...}
    if args[color_arg] ~= nil then
      args[color_arg] = remap_color(args[color_arg])
    end
    return original(table.unpack(args))
  end
end

wrap_color_function("cls", 1)
wrap_color_function("print", 4)
wrap_color_function("rect", 5)
wrap_color_function("rectfill", 5)
wrap_color_function("line", 5)
wrap_color_function("trisfill", 7)
wrap_color_function("circ", 4)
wrap_color_function("circfill", 4)

local palette_initialized = false
local function set_palette()
  if palette_initialized or type(Palette) ~= "table" then return end
  for i=1,#Palette do
    ui.palset(i-1, Palette[i])
  end
  palette_initialized = true
end

local Utils = require "utils"
local Jogador = require "jogador"
local NPCs = require "npcs"

local testes = {
  controles = require "testes.controles",
  cores     = require "testes.cores",
  readtext  = require "testes.readtext",
  sistema   = require "testes.sistema",
  mouse     = require "testes.mouse",
  estresse  = require "testes.estresse",
  audio     = require "testes.audio",
  lista     = require "testes.lista"
}

LupiDebug = {
  state = "room",
  test_return_state = "room",
  active_test = nil,
  raw_ui = raw_ui,
  VIEW_X = VIEW_X,
  WORLD_MIN = WORLD_MIN,
  WORLD_W = WORLD_W,
  SCREEN_W = SCREEN_W,
  SCREEN_H = SCREEN_H
}

local camera_x = WORLD_MIN
local previous_mouse_left = false
local previous_mouse_right = false
local previous_mouse_x, previous_mouse_y = nil, nil
local mouse_world_x, mouse_world_y = 0,0

local telemetry = {
  enabled = false,
  last_time = 0,
  interval = 2.0,
  combo_held = false
}

local function draw_room(mx,my)
  ui.cls(0)
  ui.rectfill(VIEW_X,0,479,269,0)
  for wx=WORLD_MIN, WORLD_W,32 do
    local x = wx-camera_x+VIEW_X
    if x>=VIEW_X and x<=479 then ui.line(x,28,x,260,8) end
  end
  for y=28,260,16 do ui.line(VIEW_X,y,479,y,8) end
  Utils.panel(VIEW_X+5,5,310,19,8,6)
  ui.print("LUPINHO DEBUG LAB", VIEW_X+12, 11, 6)
  ui.print("MAPA EXPANSIVEL  |  SETAS/WASD: MOVER", VIEW_X+10, 32, 1)

  NPCs.draw_all(camera_x, mx, my)
  Jogador.draw(camera_x)

  local n = NPCs.find_mouse(mx, my, camera_x) or NPCs.find_near(Jogador.x, Jogador.y)
  if n then
    Utils.panel(VIEW_X+8,220,304,39,8,n.color)
    ui.print(n.title..": "..n.desc, VIEW_X+15, 226, 1)
    ui.print("A / BTN_Z ou clique esquerdo: conversar", VIEW_X+15, 240, 6)
  else
    ui.print("Aproxime-se de um NPC ou clique nele", VIEW_X+15, 242, 1)
  end
  ui.print("X="..tostring(math.floor(Jogador.x)).." CAM="..tostring(math.floor(camera_x)), VIEW_X+190, 14, 13)
end

local function draw_dialogue(mx,my)
  draw_room(mx,my)
  local dialogue_npc = LupiDebug.dialogue_npc
  Utils.panel(VIEW_X+22, 68, 276, 128, 8, dialogue_npc.color)
  ui.print("NPC: "..dialogue_npc.title, VIEW_X+35, 80, 6)
  ui.print(dialogue_npc.desc, VIEW_X+35, 101, 1)
  ui.print("Quer iniciar este teste?", VIEW_X+35, 124, 1)
  ui.print("A / BTN_Z OU CLIQUE ESQUERDO = SIM", VIEW_X+35, 147, 2)
  ui.print("B / BTN_X OU CLIQUE DIREITO = NAO", VIEW_X+35, 163, 3)
end

function LupiDebug.begin_test(id, return_to)
  LupiDebug.active_test = id
  LupiDebug.test_return_state = return_to or "room"

  if id == "control" then LupiDebug.state = "control"
  elseif id == "colors" then testes.cores.reset(); LupiDebug.state = "colors"
  elseif id == "readtext" then testes.readtext.reset(); LupiDebug.state = "readtext"
  elseif id == "mouse" then LupiDebug.state = "mouse"
  elseif id == "system" then LupiDebug.state = "system"
  elseif id == "audio" then LupiDebug.state = "audio_menu"
  elseif id == "summary" then testes.lista.reset(); LupiDebug.state = "summary"
  else testes.estresse.reset(); LupiDebug.state = "stress" end
end

local function start_dialogue(n)
  LupiDebug.dialogue_npc = n
  LupiDebug.state = "dialogue"
end

function update(frame)
  set_palette()

  local l1_r1_pressed = Utils.held(BTN_F) and Utils.held(BTN_G)

  if l1_r1_pressed then
    if not telemetry.combo_held then
      telemetry.combo_held = true
      telemetry.enabled = not telemetry.enabled
      ui.log(string.format("\27[32m[INFO]\27[0m [Debug Lab] Telemetria %s (Intervalo: %ds)",
        telemetry.enabled and "ATIVADA" or "DESATIVADA", telemetry.interval))

      if telemetry.enabled then
        telemetry.last_time = os.clock()
        local fps = string.format("%.1f", ui.stat(7))
        local uptime = string.format("%.1f", ui.stat(2))
        local ftime = string.format("%.2f", ui.stat(3))
        local frames = string.format("%.0f", ui.stat(4))
        local mlua = string.format("%.0f", ui.stat(5))

        ui.log(string.format("\27[32m[info]\27[0m [Telemetry] FPS: %s | Uptime: %ss | FrameTime: %sms | Frames: %s | LuaMem: %sKB",
          fps, uptime, ftime, frames, mlua))
      end
    end
  else
    telemetry.combo_held = false
  end

  if telemetry.enabled and type(ui.stat) == "function" then
    local current_time = os.clock()
    if current_time - telemetry.last_time >= telemetry.interval then
      telemetry.last_time = current_time

      local fps = string.format("%.1f", ui.stat(7))
      local uptime = string.format("%.1f", ui.stat(2))
      local ftime = string.format("%.2f", ui.stat(3))
      local frames = string.format("%.0f", ui.stat(4))
      local mlua = string.format("%.0f", ui.stat(5))

      ui.log(string.format("\27[32m[info]\27[0m [Telemetry] FPS: %s | Uptime: %ss | FrameTime: %sms | Frames: %s | LuaMem: %sKB",
        fps, uptime, ftime, frames, mlua))
    end
  end

  local mx,my,bits,wheel_x,wheel_y = Utils.mouse_state()
  mouse_world_x = mx+camera_x-VIEW_X
  mouse_world_y = my

  local left_now=Utils.mouse_left(bits)
  local right_now=Utils.mouse_right(bits)
  local mouse_moved = previous_mouse_x == nil or mx ~= previous_mouse_x or my ~= previous_mouse_y

  local input = {
    mx = mx, my = my, bits = bits,
    wheel_x = wheel_x, wheel_y = wheel_y,
    left_now = left_now, right_now = right_now,
    mouse_moved = mouse_moved,
    previous_mouse_left = previous_mouse_left,
    previous_mouse_right = previous_mouse_right
  }

  if right_now and not previous_mouse_right and LupiDebug.state~="room" and LupiDebug.state~="audio_menu" then
    if LupiDebug.state=="colors_fill" then
      LupiDebug.state="colors"
    elseif LupiDebug.state=="audio_channels" or LupiDebug.state=="audio_volume" or LupiDebug.state=="audio_controls" then
      LupiDebug.state="audio_menu"
    elseif LupiDebug.state=="summary" or LupiDebug.state=="dialogue" then
      -- Removemos o 'audio_menu' daqui para ele não fechar direto
      LupiDebug.state="room"
      LupiDebug.dialogue_npc=nil
      LupiDebug.active_test=nil
    else
      LupiDebug.state=LupiDebug.test_return_state or "room"
      LupiDebug.active_test=nil
    end
    -- ...
    LupiDebug.dialogue_npc=nil
  end

  local state = LupiDebug.state
  if state=="room" then
    Jogador.update(NPCs.list)
    camera_x=math.max(WORLD_MIN, math.min(WORLD_W-320, Jogador.x-160))

    if Utils.pressed(BTN_Z) then
      local n=NPCs.find_near(Jogador.x, Jogador.y)
      if n then start_dialogue(n) end
    end

    local hovered=NPCs.find_mouse(mx, my, camera_x)
    if left_now and not previous_mouse_left and hovered then
      start_dialogue(hovered)
    end

    draw_room(mx,my)

  elseif state=="dialogue" then
    draw_dialogue(mx,my)
    if Utils.pressed(BTN_Z) or (left_now and not previous_mouse_left) then
      LupiDebug.begin_test(LupiDebug.dialogue_npc.id, "room")
    end
    if Utils.pressed(BTN_X) or (right_now and not previous_mouse_right) then
      LupiDebug.state="room"
      LupiDebug.dialogue_npc=nil
    end

  elseif state=="control" then testes.controles.update(input, frame)
  elseif state=="colors" or state=="colors_fill" then testes.cores.update(input, frame)
  elseif state=="readtext" then testes.readtext.update(input, frame)
  elseif state=="audio_menu" or state=="audio_controls" or state=="audio_channels" or state=="audio_volume" then testes.audio.update(input, frame)
  elseif state=="mouse" then testes.mouse.update(input, frame)
  elseif state=="system" then testes.sistema.update(input, frame)
  elseif state=="summary" then testes.lista.update(input, frame)
  elseif state=="stress" then testes.estresse.update(input, frame)
  end

  previous_mouse_left=left_now
  previous_mouse_right=right_now
  previous_mouse_x=mx
  previous_mouse_y=my
end
