-- testes/controles.lua
local Utils = require "utils"
local M = {}
local control_player = 0
local control_player_style = {
  { body = Utils.CColors.SNES_GRAY, border = 4 },
  { body = Utils.CColors.SNES_GRAY, border = 2 },
  { body = Utils.CColors.SNES_GRAY, border = 3 },
}

function M.update(input, frame)
  ui.cls(0)
  local acting = nil
  for p = 0, 2 do
    if ui.btn(UP,p) or ui.btn(DOWN,p) or ui.btn(LEFT,p) or ui.btn(RIGHT,p) or
       ui.btn(BTN_Z,p) or ui.btn(BTN_X,p) or ui.btn(BTN_Q,p) or ui.btn(BTN_E,p) or
       ui.btn(BTN_F,p) or ui.btn(BTN_G,p) then acting = p end
  end
  if acting then control_player = acting end

  local style = control_player_style[control_player+1]
  local pname = "P"..(control_player+1)

  ui.print("TESTE DE CONTROLE - "..pname, 176, 10, style.border)
  ui.print("Pressione qualquer botao para mudar o jogador", 176, 24, 1)
  ui.print("RETORNAR: BAIXO + B (em qualquer controle)", 176, 38, style.border)

  ui.rectfill(178, 70, 462, 191, style.body)
  ui.rect(178, 70, 462, 191, style.border)
  ui.rectfill(178, 70, 202, 82, style.border)
  ui.print(pname, 182, 72, 1)

  local up,down,left,right=
    Utils.held_p(UP, control_player), Utils.held_p(DOWN, control_player),
    Utils.held_p(LEFT, control_player), Utils.held_p(RIGHT, control_player)

  local db = Utils.CColors.DPAD
  local df = Utils.CColors.DPAD_flash

  ui.rectfill(231,103,251,124, up and df or db)
  ui.trisfill(231,105,251,105,241,94, up and df or db)
  ui.rectfill(231,145,251,166, down and df or db)
  ui.trisfill(231,164,251,164,241,176, down and df or db)
  ui.rectfill(209,125,230,145, left and df or db)
  ui.trisfill(211,125,211,145,199,135, left and df or db)
  ui.rectfill(252,125,273,145, right and df or db)
  ui.trisfill(271,125,271,145,283,135, right and df or db)
  ui.rect(209,94,273,176,1)

  local function btn(x,y,l,b)
    local is_held = Utils.held_p(b, control_player)
    local bc = Utils.CColors[l]
    local fc = Utils.CColors[l .. "_flash"]
    ui.circfill(x,y,13,8)
    ui.circfill(x,y,9, is_held and fc or bc)
    ui.print(l, x-math.floor(#l*6/2), y-3, 1)
  end

  btn(397,100,"Y",BTN_Q)
  btn(365,130,"X",BTN_E)
  btn(397,160,"A",BTN_Z)
  btn(429,130,"B",BTN_X)

  local function shoulder(x,y,label,b)
    local is_held = Utils.held_p(b, control_player)
    local fill = is_held and Utils.CColors.SHOULDER_flash or Utils.CColors.SHOULDER
    ui.rectfill(x-22,y-10,x+22,y+10,8)
    ui.rect(x-22,y-10,x+22,y+10,1)
    ui.rectfill(x-19,y-7,x+19,y+7,fill)
    ui.print(label, x-math.floor(#label*6/2), y-3, 1)
  end

  shoulder(241, 61, "L", BTN_F)
  shoulder(397, 61, "R", BTN_G)

  for p = 0, 2 do
    if Utils.held_p(DOWN, p) and Utils.held_p(BTN_X, p) then
      LupiDebug.state = LupiDebug.test_return_state
      LupiDebug.active_test = nil
      return
    end
  end
end
return M
