-- testes/lista.lua
local Utils = require "utils"
local M = {}
local summary_index = 1
local summary_tests = {
  { id="watchdog", label="WATCHDOG - instrucoes Lua" },
  { id="drawlist", label="DRAWLIST - bytes graficos" },
  { id="sdbytes",  label="SD BYTES - bytes lidos/frame" },
  { id="sdtx",     label="SD TX - transacoes SD" },
  { id="sprites",  label="SPRITES - carregamentos/frame" },
  { id="control",  label="CONTROLE - botoes do gamepad" },
  { id="colors",   label="CORES - paleta e indices" },
  { id="readtext", label="READTEXT - entrada de texto" },
  { id="audio",    label="SOM - canais, volume, musica" },
  { id="mouse",    label="MOUSE - arrastar Sonic CPU" },
  { id="system",   label="SISTEMA - memoria, CPU, FPS" },
}

function M.reset() summary_index = 1 end

function M.update(input, frame)
  ui.cls(0)
  ui.print("SELECAO DE TESTES", 176, 10, 6)
  Utils.panel(174,34,292,194,8,6)

  local mx, my, bits = input.mx, input.my, input.bits
  local hovered=nil
  for i,t in ipairs(summary_tests) do
    local y=42+(i-1)*16
    if mx>=180 and mx<=460 and my>=y-2 and my<=y+13 then hovered=i end
    if i==summary_index or i==hovered then
      ui.rectfill(180, y-2, 460, y+13, i==hovered and 6 or 3)
    end
    ui.print(string.format("%02d  %s",i,t.label), 184, y, 1)
  end

  ui.print("SETA CIMA/BAIXO + A PARA ABRIR", 176, 237, 6)
  ui.print("B OU CLIQUE DIREITO: SALA", 184, 251, 1)

  if Utils.pressed(UP) then summary_index=math.max(1,summary_index-1) end
  if Utils.pressed(DOWN) then summary_index=math.min(#summary_tests,summary_index+1) end
  if hovered and input.mouse_moved then summary_index=hovered end

  if Utils.pressed(BTN_Z) then
    local id=summary_tests[summary_index].id
    LupiDebug.begin_test(id, "summary")
    return
  end

  if hovered and Utils.mouse_left(bits) and not input.previous_mouse_left then
    local id=summary_tests[hovered].id
    LupiDebug.begin_test(id, "summary")
    return
  end

  if Utils.pressed(BTN_X) then
    LupiDebug.state="room"
    LupiDebug.active_test=nil
  end
end
return M
