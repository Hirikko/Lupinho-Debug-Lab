-- testes/estresse.lua
local Utils = require "utils"
local M = {}
local test_message, test_started, multiplier = "", false, 1
local found_sprites = {}

local function collect_sprites(v,found,seen,depth)
  if type(v)~="table" or seen[v] or depth>8 then return end
  seen[v]=true
  if type(v.path)=="string" and type(v.width)=="number" and type(v.height)=="number" then
    found[#found+1]=v; return
  end
  for _,ch in pairs(v) do
    if type(ch)=="table" then collect_sprites(ch,found,seen,depth+1) end
  end
end

function M.reset()
  test_message = ""
  test_started = false
  multiplier = 1
  found_sprites = {}
end

function M.update(input, frame)
  local active_test = LupiDebug.active_test
  local wheel_y = input.wheel_y

  ui.cls(0)
  ui.print("TESTE: "..string.upper(active_test or ""), 176, 12, 6)
  Utils.panel(174,35,292,108,8,6)
  ui.print("Multiplicador: x"..multiplier, 184, 46, 6)
  ui.print("SETAS / RODA DO MOUSE ajustam carga", 184, 61, 1)
  ui.print(test_message, 184, 82, 1)
  ui.print("B RETORNA | CLIQUE DIREITO: SALA", 184, 232, 6)

  if Utils.pressed(LEFT) then multiplier=math.max(1,multiplier-1); test_started=false end
  if Utils.pressed(RIGHT) then multiplier=math.min(100,multiplier+1); test_started=false end
  if wheel_y>0 then multiplier=math.min(100,multiplier+1); test_started=false
  elseif wheel_y<0 then multiplier=math.max(1,multiplier-1); test_started=false end

  if active_test=="drawlist" then
    local count=math.min(4000,200*multiplier)
    for i=1,count do
      ui.rectfill(LupiDebug.VIEW_X+(i*17)%315, (i*29)%205+35, LupiDebug.VIEW_X+(i*17)%315+2, (i*29)%205+35+2, i%16)
    end
    test_message="Retangulos/frame: "..count..". Confira Draw rejected."

  elseif active_test=="watchdog" then
    local n=0
    for i=1,500*multiplier do n=n+(i%7) end
    test_message="Iteracoes/frame: "..(500*multiplier).."; resultado="..n

  elseif active_test=="sprites" or active_test=="sdbytes" or active_test=="sdtx" then
    if not test_started then
      pcall(require,"sprites")
      found_sprites = {}
      local seen={}
      if type(Sprites)=="table" then collect_sprites(Sprites,found_sprites,seen,0) end
      test_started=true
    end

    if #found_sprites == 0 then
      test_message = "Nenhum bitmap encontrado no manifesto Sprites."
    else
      local attempts = math.min(#found_sprites, 32 * multiplier)
      for i=1,attempts do
        ui.spr(found_sprites[i], LupiDebug.VIEW_X+((i-1)%6)*48, 150+math.floor((i-1)/6)*24)
      end
      test_message = string.format("Sprites: %d | Tentando desenhar: %d", #found_sprites, attempts)
    end
  end

  if Utils.pressed(BTN_X) then
    LupiDebug.state=LupiDebug.test_return_state
    LupiDebug.active_test=nil
    test_started=false
  end
end
return M
