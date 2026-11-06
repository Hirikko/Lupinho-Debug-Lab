-- npcs.lua
local Utils = require "utils"
local M = {}

M.list = {
  {id="system",x=265,y=255,color=7,title="SISTEMA",desc="Memoria, CPU, FPS"},
  {id="watchdog",x=275,y=92,color=4,title="WATCHDOG",desc="Estoura instrucoes Lua"},
  {id="drawlist",x=405,y=92,color=3,title="DRAWLIST",desc="Excede bytes graficos"},
  {id="sdbytes",x=535,y=92,color=5,title="SD BYTES",desc="Testa bytes por frame"},
  {id="sdtx",x=665,y=92,color=6,title="SD TX",desc="Testa transacoes SD"},
  {id="sprites",x=795,y=92,color=2,title="SPRITES",desc="Carrega sprites unicos"},
  {id="control",x=925,y=92,color=11,title="CONTROLE",desc="Mapeamento do gamepad"},
  {id="colors",x=1055,y=92,color=10,title="CORES",desc="Paleta e cores"},
  {id="readtext",x=1185,y=92,color=13,title="READTEXT",desc="Teste de digitacao"},
  {id="mouse",x=1390,y=92,color=9,title="MOUSE",desc="Arrastar sprite e colisao"},
  {id="audio",x=1185,y=175,color=4,title="SOM",desc="Volume, musica e canais"},
  {id="summary",x=265,y=175,color=6,title="TODOS TESTES",desc="Resumo e selecao de testes"}
}

function M.find_near(player_x, player_y)
  for _,n in ipairs(M.list) do
    local dx,dy = player_x-n.x, player_y-n.y
    if dx*dx+dy*dy < 42*42 then return n end
  end
  return nil
end

function M.find_mouse(mx, my, camera_x)
  for _,n in ipairs(M.list) do
    local x = n.x - camera_x + LupiDebug.VIEW_X
    if mx>=x-20 and mx<=x+20 and my>=n.y-18 and my<=n.y+18 then return n end
  end
  return nil
end

function M.draw(n, hovered, camera_x)
  local x = n.x - camera_x + LupiDebug.VIEW_X
  Utils.panel(x-18, n.y-17, 36, 34, 8, hovered and 6 or n.color)
  ui.rectfill(x-10, n.y-10, x+10, n.y+10, n.color)
  ui.circfill(x-4,n.y-3,2,1)
  ui.circfill(x+4,n.y-3,2,1)
  ui.line(x-4,n.y+4,x+4,n.y+4,1)
  Utils.text_center_at(n.title, x, n.y+21, hovered and 6 or 1)
end

function M.draw_all(camera_x, mx, my)
  for _,n in ipairs(M.list) do
    local sx = n.x - camera_x + LupiDebug.VIEW_X
    if sx>=LupiDebug.VIEW_X-30 and sx<=500 then
      M.draw(n, M.find_mouse(mx, my, camera_x)==n, camera_x)
    end
  end
end

return M
