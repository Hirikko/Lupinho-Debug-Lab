-- utils.lua
local Utils = {}

function Utils.held(b) return b ~= nil and ui.btn(b) end
function Utils.pressed(b) return b ~= nil and ui.btnp(b) end
function Utils.held_p(b, player) return b ~= nil and ui.btn(b, player) ~= false end
function Utils.pressed_p(b, player) return b ~= nil and ui.btnp(b, player) ~= false end

function Utils.mouse_state()
  if type(ui.mouse) ~= "function" then return 0,0,0,0,0 end
  local x,y,buttons,wheel_x,wheel_y = ui.mouse()
  return tonumber(x) or 0, tonumber(y) or 0, tonumber(buttons) or 0,
         tonumber(wheel_x) or 0, tonumber(wheel_y) or 0
end

function Utils.mouse_left(bits) return bits % 2 == 1 end
function Utils.mouse_right(bits) return math.floor(bits / 2) % 2 == 1 end
function Utils.text_center_at(s,x,y,c) ui.print(s, math.floor(x-#s*6/2), y, c or 1) end

function Utils.panel(x,y,w,h,fill,border)
  ui.rectfill(x,y,x+w,y+h,fill)
  ui.rect(x,y,x+w,y+h,border or 1)
end

function Utils.clamp(v,a,b) return math.max(a,math.min(b,v)) end

-- Tabela de Cores do Controle Físico
Utils.CColors = {
  Y = Palette.hex(0x00A800), Y_flash = Palette.hex(0x50FF50),
  X = Palette.hex(0x0000A8), X_flash = Palette.hex(0x5050FF),
  A = Palette.hex(0xA80000), A_flash = Palette.hex(0xFF5050),
  B = Palette.hex(0xA8A800), B_flash = Palette.hex(0xFFFF50),
  DPAD = Palette.hex(0x9B6DDE), DPAD_flash = Palette.hex(0x5A2D8C),
  SHOULDER = Palette.hex(0x9B6DDE), SHOULDER_flash = Palette.hex(0x5A2D8C),
  SNES_GRAY = Palette.hex(0xC0C0C0)
}

return Utils
