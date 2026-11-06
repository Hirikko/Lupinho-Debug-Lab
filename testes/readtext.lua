-- testes/readtext.lua
local Utils = require "utils"
local M = {}
local notes = ""
local readtext_supported = type(ui.readtext) == "function"
local peektext_supported = type(ui.peektext) == "function"

function M.reset()
  if readtext_supported then
    for i=1,4096 do
      local ch=ui.readtext()
      if type(ch)~="string" or #ch==0 then break end
    end
  end
  notes = ""
end

function M.update(input, frame)
  if readtext_supported then
    for i=1,64 do
      local ch=ui.readtext()
      if type(ch)~="string" or #ch==0 then break end
      local lower=ch:lower()
      if ch=="\b" or ch==string.char(8) or ch=="\127" or ch==string.char(127) or lower=="backspace" or lower=="<backspace>" then
        if #notes>0 then
          local i=#notes
          while i>0 do
            local byte=notes:byte(i)
            if byte<128 or byte>=192 then break end
            i=i-1
          end
          notes=notes:sub(1,i-1)
        end
      elseif ch=="\r" or ch=="\n" then notes=notes.."\n"
      elseif ch:match("^[%g%s]$") then notes=notes..ch end
    end
  end

  ui.cls(0)
  ui.print("TESTE READTEXT - BLOCO DE NOTAS", 176, 10, 6)

  if peektext_supported then
    local peeked = ui.peektext()
    if peeked then
      ui.print("PROXIMO CARACTERE (peektext): '"..peeked.."'", 176, 24, 2)
    else
      ui.print("PROXIMO CARACTERE (peektext): <vazio>", 176, 24, 1)
    end
  else
    ui.print("ui.peektext() nao implementado nesta build.", 176, 24, 3)
  end

  Utils.panel(174,38,292,174,0,6)
  ui.print("Digite no teclado:", 184, 48, 1)
  ui.line(184,65,456,65,7)

  local shown=notes
  if #shown>600 then shown=shown:sub(#shown-600+1) end

  local lines={}
  for source_line in (shown.."\n"):gmatch("(.-)\n") do
    local rest=source_line
    while #rest>44 do
      lines[#lines+1]=rest:sub(1,44)
      rest=rest:sub(45)
    end
    lines[#lines+1]=rest
  end

  local first=math.max(1,#lines-12)
  for i=first,#lines do
    local visible=lines[i]
    if #visible>44 then visible=visible:sub(1,44) end
    ui.print(visible, 184, 73+(i-first)*10, 1)
  end

  if not readtext_supported then
    ui.print("ERRO: ui.readtext nao existe nesta API", 174, 220, 3)
  else
    ui.print("Caracteres recebidos: "..#notes, 174, 220, 2)
  end
  ui.print("CLIQUE DIREITO: SAIR PARA A SALA", 184, 246, 6)
end
return M
