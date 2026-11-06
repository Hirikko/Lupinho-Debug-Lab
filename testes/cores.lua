-- testes/cores.lua
local Utils = require "utils"
local M = {}
local color_index = 1
local colors = {
  "PRETO","BRANCO","VERDE","COR 3","COR 4","CIANO","AMARELO","CINZA",
  "CINZA ESCURO","MAGENTA","VERDE CLARO","VIOLETA","AZUL","CINZA CLARO",
  "VERDE MEDIO","VERMELHO"
}

local function bgr555_to_hex(val)
  if not val then return "N/A" end
  local r5 = val & 0x1F
  local g5 = (val >> 5) & 0x1F
  local b5 = (val >> 10) & 0x1F
  local r8 = (r5 << 3) | (r5 >> 2)
  local g8 = (g5 << 3) | (g5 >> 2)
  local b8 = (b5 << 3) | (b5 >> 2)
  return string.format("#%02X%02X%02X", r8, g8, b8)
end

function M.reset() color_index = 1 end

function M.update(input, frame)
  if LupiDebug.state == "colors_fill" then return M.update_fill(input, frame) end

  ui.cls(0)
  ui.print("TESTE DE CORES E PALETA", 176, 10, 6)
  ui.print("SETAS/SCROLL: SELECIONAR | A: PREENCHER | B: VOLTAR", 176, 24, 1)

  local mx,my,bits = input.mx, input.my, input.bits
  local hover_index=nil

  for i=0,15 do
    local col=i%8
    local row=math.floor(i/8)
    local x=174+col*36
    local y=51+row*58
    if mx>=x and mx<=x+29 and my>=y and my<=y+32 then hover_index=i+1 end
    LupiDebug.raw_ui.rectfill(x, y, x+29, y+32, i)
    local selected=(i==color_index-1)
    local hovered=(hover_index==i+1)
    ui.rect(x, y, x+29, y+32, (selected or hovered) and 6 or 1)
    if hovered then ui.rect(x+2, y+2, x+27, y+30, 6) end
    ui.print(tostring(i), x+11, y+35, 1)
  end

  ui.rectfill(174,174,466,205,8)
  ui.rect(174,174,466,205,6)

  local color_val = Palette and Palette[color_index]
  local hex_str = bgr555_to_hex(color_val)

  ui.print("INDICE: "..(color_index-1).." "..(colors[color_index] or "COR").."  |  RGB: "..hex_str, 184, 185, 1)
  ui.print("B RETORNA | CLIQUE DIREITO: SALA", 184, 232, 6)

  local changed = false
  if Utils.pressed(LEFT) then color_index=(color_index+14)%16+1; changed = true end
  if Utils.pressed(RIGHT) then color_index=color_index%16+1; changed = true end
  if Utils.pressed(UP) then color_index=math.max(1,color_index-8); changed = true end
  if Utils.pressed(DOWN) then color_index=math.min(16,color_index+8); changed = true end

  if input.wheel_y > 0 then
    color_index = color_index - 1
    if color_index < 1 then color_index = 16 end
    changed = true
  elseif input.wheel_y < 0 then
    color_index = color_index + 1
    if color_index > 16 then color_index = 1 end
    changed = true
  end

  if not changed and hover_index and input.mouse_moved then color_index = hover_index end

  if Utils.pressed(BTN_Z) or (Utils.mouse_left(bits) and not input.previous_mouse_left and hover_index) then
    LupiDebug.state="colors_fill"
    return
  end
  if Utils.pressed(BTN_X) then
    LupiDebug.state=LupiDebug.test_return_state
    LupiDebug.active_test=nil
  end
end

function M.update_fill(input, frame)
  if Utils.pressed(LEFT) then color_index=(color_index+14)%16+1 end
  if Utils.pressed(RIGHT) then color_index=color_index%16+1 end
  if Utils.pressed(UP) then color_index=math.max(1,color_index-8) end
  if Utils.pressed(DOWN) then color_index=math.min(16,color_index+8) end

  if input.wheel_y > 0 then
    color_index = color_index - 1
    if color_index < 1 then color_index = 16 end
  elseif input.wheel_y < 0 then
    color_index = color_index + 1
    if color_index > 16 then color_index = 1 end
  end

  LupiDebug.raw_ui.cls(color_index-1)

  local color_val = Palette and Palette[color_index]
  local hex_str = bgr555_to_hex(color_val)

  local text_col = 1
  if color_val then
    local r5 = color_val & 0x1F
    local g5 = (color_val >> 5) & 0x1F
    local b5 = (color_val >> 10) & 0x1F
    local luma = (r5 * 0.299) + (g5 * 0.587) + (b5 * 0.114)
    if luma >= 15 then text_col = 0 end
  end

  ui.print("COR "..(color_index-1).." - "..(colors[color_index] or "COR").." ("..hex_str..")", 176, 10, text_col)
  ui.print("B / CLIQUE DIREITO: VOLTAR AS CORES", 176, 25, text_col)

  if Utils.pressed(BTN_X) then LupiDebug.state="colors" end
end

return M
