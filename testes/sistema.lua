-- testes/sistema.lua
local Utils = require "utils"
local M = {}

function M.update(input, frame)
  ui.cls(0)
  ui.print("TESTE DE SISTEMA (ui.stat)", 176, 10, 6)
  ui.print("Cada linha mostra o valor cru retornado por ui.stat(n).", 176, 24, 1)

  if type(ui.stat) ~= "function" then
    ui.print("ERRO: ui.stat nao existe nesta API", 176, 60, 3)
  else
    Utils.panel(174, 40, 292, 190, 8, 6)

    local labels = {
      [0] = "Memoria (bytes)",
      [1] = "Carga do Frame (%)",
      [2] = "Tempo de Jogo (s)",
      [3] = "Tempo Frame (ms)",
      [4] = "Contador Frames",
      [5] = "Lua RAM (KB)",
      [6] = "PSRAM Simulada (KB)",
      [7] = "FPS Atual",
      [8] = "Memoria Max (KB)",
      [9] = "Stat(9)"
    }

    for n = 0, 9 do
      local ok, value = pcall(ui.stat, n)
      local line
      if ok and type(value) == "number" then
        local label = labels[n] or ("Stat(" .. n .. ")")
        if n == 0 then
          line = string.format("%-20s: %d", label, value)
        elseif n == 7 then
          line = string.format("%-20s: %.0f", label, value)
        else
          line = string.format("%-20s: %.1f", label, value)
        end
      else
        line = string.format("ui.stat(%d) = ERRO", n)
      end
      ui.print(line, 184, 48 + n * 18, 1)
    end
  end

  ui.print("B ou clique direito: SAIR", 176, 246, 6)
  if Utils.pressed(BTN_X) then
    LupiDebug.state = LupiDebug.test_return_state
    LupiDebug.active_test = nil
  end
end
return M
