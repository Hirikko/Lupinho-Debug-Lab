-- Lupinho Debug Lab v9
-- Mapa expansivel, colisao com NPCs, mouse, readtext e testes graduais.
SCREEN_W, SCREEN_H = 480, 270
VIEW_X, WORLD_MIN, WORLD_W = 160, 165, 1600
LUPI_HARDWARE_CONSTRAINTS = true
LUPI_LUA_WATCHDOG = true
LUPI_HARDWARE_DEBUG_OVERLAY = true
LUPI_HARDWARE_DEBUG_OVERLAY_RECT = { x0 = 0, y0 = 0, x1 = 164, y1 = 270, col = 2 }
LUPI_HARDWARE_DEBUG_OVERLAY_ALPHA = 0.5

require "palette-debug"

-- Paleta usada pela interface do Debug Lab.
-- A paleta do Sonic NAO e sobrescrita durante ui.spr().
local debug_ui_palette = {
  0x0000,0x7FFF,0x03E0,0x001F,
  0x7C00,0x03FF,0x7FE0,0x4210,
  0x2010,0x7C1F,0x02E0,0x401F,
  0x021F,0x5294,0x2D6B,0x5C2C
}

local function set_ui_palette()
  for i=1,#debug_ui_palette do
    ui.palset(i-1,debug_ui_palette[i])
  end
end

local function set_palette()
  set_ui_palette()
end

local function held(b)
  return b ~= nil and ui.btn(b)
end

local function pressed(b)
  return b ~= nil and ui.btnp(b)
end

local function mouse_state()
  if type(ui.mouse) ~= "function" then
    return 0,0,0,0,0
  end

  local x,y,buttons,wheel_x,wheel_y = ui.mouse()

  return
    tonumber(x) or 0,
    tonumber(y) or 0,
    tonumber(buttons) or 0,
    tonumber(wheel_x) or 0,
    tonumber(wheel_y) or 0
end

local function mouse_left(bits)
  return bits % 2 == 1
end

local function mouse_right(bits)
  return math.floor(bits / 2) % 2 == 1
end

local function text_center(s,y,c)
  ui.print(s, math.floor((SCREEN_W-#s*6)/2), y, c or 1)
end

local function text_center_at(s,x,y,c)
  ui.print(s, math.floor(x-#s*6/2), y, c or 1)
end

local function panel(x,y,w,h,fill,border)
  ui.rectfill(x,y,x+w,y+h,fill)
  ui.rect(x,y,x+w,y+h,border or 1)
end

local function clamp(v,a,b)
  return math.max(a,math.min(b,v))
end


local state, dialogue_npc, active_test = "room", nil, nil
local test_return_state = "room"

-- Player um pouco mais rapido para facilitar navegacao no mapa.
local player = {
  x=205,
  y=205,
  speed=3.8,
  r=6
}

local camera_x = WORLD_MIN
local color_index = 1
local summary_index = 1

local colors = {
  "PRETO",
  "BRANCO",
  "VERDE",
  "COR 3",
  "COR 4",
  "CIANO",
  "AMARELO",
  "CINZA",
  "CINZA ESCURO",
  "MAGENTA",
  "VERDE CLARO",
  "VIOLETA",
  "AZUL",
  "CINZA CLARO",
  "VERDE MEDIO",
  "VERMELHO"
}

local test_message, test_started, multiplier = "", false, 1
local previous_mouse_left = false
local previous_mouse_right = false
local mouse_world_x, mouse_world_y = 0,0
local drag = {
  active=false,
  dx=0,
  dy=0
}

local notes = ""
local readtext_supported = type(ui.readtext) == "function"


local npcs = {
  {id="watchdog",x=275,y=92,color=4,title="WATCHDOG",desc="Estoura instrucoes Lua"},
  {id="drawlist",x=405,y=92,color=3,title="DRAWLIST",desc="Excede bytes graficos"},
  {id="sdbytes",x=535,y=92,color=5,title="SD BYTES",desc="Testa bytes por frame"},
  {id="sdtx",x=665,y=92,color=6,title="SD TX",desc="Testa transacoes SD"},
  {id="sprites",x=795,y=92,color=2,title="SPRITES",desc="Carrega sprites unicos"},
  {id="control",x=925,y=92,color=11,title="CONTROLE",desc="Mapeamento do gamepad"},
  {id="colors",x=1055,y=92,color=10,title="CORES",desc="Paleta e cores"},
  {id="readtext",x=1185,y=92,color=13,title="READTEXT",desc="Teste de digitacao"},
  {id="mouse",x=1390,y=92,color=9,title="MOUSE",desc="Arrastar sprite e colisao"},
  {id="summary",x=265,y=175,color=6,title="TODOS TESTES",desc="Resumo e selecao de testes"}
}


local function world_to_screen(x)
  return x-camera_x+VIEW_X
end


local function player_box(x,y)
  return {
    x1=x-6,
    y1=y-8,
    x2=x+6,
    y2=y+8
  }
end


local function overlaps(a,b)
  return
    a.x1 < b.x2 and
    a.x2 > b.x1 and
    a.y1 < b.y2 and
    a.y2 > b.y1
end


local function blocked(x,y)
  local p=player_box(x,y)

  for _,n in ipairs(npcs) do
    local b={
      x1=n.x-19,
      y1=n.y-18,
      x2=n.x+19,
      y2=n.y+18
    }

    if overlaps(p,b) then
      return true
    end
  end

  return false
end


local function near_npc(n)
  local dx,dy=player.x-n.x,player.y-n.y
  return dx*dx+dy*dy < 42*42
end


local function find_near_npc()
  for _,n in ipairs(npcs) do
    if near_npc(n) then
      return n
    end
  end

  return nil
end


local function mouse_npc(mx,my)
  for _,n in ipairs(npcs) do
    local x=world_to_screen(n.x)

    if
      mx>=x-20 and
      mx<=x+20 and
      my>=n.y-18 and
      my<=n.y+18
    then
      return n
    end
  end

  return nil
end


local function draw_player(x,y)
  ui.rectfill(x-5,y-7,x+5,y+7,1)
  ui.rect(x-6,y-8,x+6,y+8,8)
  ui.rectfill(x-3,y-4,x+3,y-1,3)
end


local function draw_npc(n, hovered)
  local x=world_to_screen(n.x)

  panel(
    x-18,
    n.y-17,
    36,
    34,
    8,
    hovered and 6 or n.color
  )

  ui.rectfill(
    x-10,
    n.y-10,
    x+10,
    n.y+10,
    n.color
  )

  ui.circfill(x-4,n.y-3,2,1)
  ui.circfill(x+4,n.y-3,2,1)
  ui.line(x-4,n.y+4,x+4,n.y+4,1)

  text_center_at(
    n.title,
    x,
    n.y+21,
    hovered and 6 or 1
  )
end


local function draw_room(mx,my)
  ui.cls(0)

  -- Area de jogo ocupa x=160..479;
  -- o overlay permanece livre a esquerda.
  ui.rectfill(VIEW_X,0,479,269,0)

  for wx=WORLD_MIN, WORLD_W,32 do
    local x=world_to_screen(wx)

    if x>=VIEW_X and x<=479 then
      ui.line(x,28,x,260,8)
    end
  end

  for y=28,260,16 do
    ui.line(VIEW_X,y,479,y,8)
  end

  panel(
    VIEW_X+5,
    5,
    310,
    19,
    8,
    6
  )

  ui.print(
    "LUPINHO DEBUG LAB",
    VIEW_X+12,
    11,
    6
  )

  ui.print(
    "MAPA EXPANSIVEL  |  SETAS/WASD: MOVER",
    VIEW_X+10,
    32,
    1
  )

  for _,n in ipairs(npcs) do
    local sx=world_to_screen(n.x)

    if sx>=VIEW_X-30 and sx<=500 then
      draw_npc(
        n,
        mouse_npc(mx,my)==n
      )
    end
  end

  draw_player(
    world_to_screen(player.x),
    player.y
  )

  local n=mouse_npc(mx,my) or find_near_npc()

  if n then
    panel(
      VIEW_X+8,
      220,
      304,
      39,
      8,
      n.color
    )

    ui.print(
      n.title..": "..n.desc,
      VIEW_X+15,
      226,
      1
    )

    ui.print(
      "A / BTN_Z ou clique esquerdo: conversar",
      VIEW_X+15,
      240,
      6
    )
  else
    ui.print(
      "Aproxime-se de um NPC ou clique nele",
      VIEW_X+15,
      242,
      1
    )
  end

  ui.print(
    "X="..tostring(math.floor(player.x))..
    " CAM="..tostring(math.floor(camera_x)),
    VIEW_X+190,
    14,
    13
  )
end


local function start_dialogue(n)
  dialogue_npc=n
  state="dialogue"
end


local function begin_test(n, return_to)
  active_test=n.id
  test_message=""
  test_started=false
  multiplier=1
  test_return_state=return_to or "room"

  if n.id=="readtext" and readtext_supported then
    -- Descarta caracteres que tenham ficado na fila antes de entrar no teste.
    for i=1,4096 do
      local ch=ui.readtext()

      if type(ch)~="string" or #ch==0 then
        break
      end
    end
  end

  if n.id=="control" then
    state="control"
  elseif n.id=="colors" then
    state="colors"
  elseif n.id=="readtext" then
    state="readtext"
    notes=""
  elseif n.id=="mouse" then
    state="mouse"
  elseif n.id=="summary" then
    state="summary"
  else
    state="stress"
  end
end


local function draw_dialogue(mx,my)
  draw_room(mx,my)

  panel(
    VIEW_X+22,
    68,
    276,
    128,
    8,
    dialogue_npc.color
  )

  ui.print(
    "NPC: "..dialogue_npc.title,
    VIEW_X+35,
    80,
    6
  )

  ui.print(
    dialogue_npc.desc,
    VIEW_X+35,
    101,
    1
  )

  ui.print(
    "Quer iniciar este teste?",
    VIEW_X+35,
    124,
    1
  )

  ui.print(
    "A / BTN_Z OU CLIQUE ESQUERDO = SIM",
    VIEW_X+35,
    147,
    2
  )

  ui.print(
    "B / BTN_X OU CLIQUE DIREITO = NAO",
    VIEW_X+35,
    163,
    3
  )
end


local function draw_control()
  ui.cls(0)

  ui.print(
    "TESTE DE CONTROLE",
    176,
    10,
    6
  )

  ui.print(
    "Cada direcao acende somente sua propria seta",
    176,
    24,
    1
  )

  -- Controle compacto dentro da area x=160..479,
  -- sem invadir o overlay.
  ui.rectfill(
    178,
    70,
    462,
    191,
    8
  )

  ui.rect(
    178,
    70,
    462,
    191,
    4
  )

  -- D-pad com quatro segmentos independentes.
  local up,down,left,right=
    held(UP),
    held(DOWN),
    held(LEFT),
    held(RIGHT)

  ui.rectfill(
    231,103,
    251,124,
    up and 2 or 7
  )

  ui.trisfill(
    231,105,
    251,105,
    241,94,
    up and 6 or 1
  )

  ui.rectfill(
    231,145,
    251,166,
    down and 2 or 7
  )

  ui.trisfill(
    231,164,
    251,164,
    241,176,
    down and 6 or 1
  )

  ui.rectfill(
    209,125,
    230,145,
    left and 2 or 7
  )

  ui.trisfill(
    211,125,
    211,145,
    199,135,
    left and 6 or 1
  )

  ui.rectfill(
    252,125,
    273,145,
    right and 2 or 7
  )

  ui.trisfill(
    271,125,
    271,145,
    283,135,
    right and 6 or 1
  )

  ui.rect(
    209,94,
    273,176,
    1
  )


  local function btn(x,y,l,b,c)
    ui.circfill(x,y,13,8)
    ui.circfill(
      x,
      y,
      9,
      held(b) and c or 7
    )

    ui.print(
      l,
      x-math.floor(#l*6/2),
      y-3,
      1
    )
  end


  -- SNES:
  -- Y = cima
  -- X = esquerda
  -- A = baixo
  -- B = direita
  btn(397,100,"Y",BTN_Q,12)
  btn(365,130,"X",BTN_E,4)
  btn(397,160,"A",BTN_Z,2)
  btn(429,130,"B",BTN_X,3)


  -- L alinhado horizontalmente com a seta esquerda.
  -- Agora e um retangulo horizontal, sem formato de analogico.
  local function shoulder_rect(x,y,label,b)
    local fill=held(b) and 2 or 7

    ui.rectfill(
      x-22,
      y-10,
      x+22,
      y+10,
      8
    )

    ui.rect(
      x-22,
      y-10,
      x+22,
      y+10,
      1
    )

    ui.rectfill(
      x-19,
      y-7,
      x+19,
      y+7,
      fill
    )

    ui.print(
      label,
      x-math.floor(#label*6/2),
      y-3,
      1
    )
  end


  -- L: mesma coordenada horizontal da seta esquerda.
  shoulder_rect(
    241,
    61,
    "L",
    BTN_F
  )

  -- R: mesma coordenada horizontal do botao Y.
  shoulder_rect(
    397,
    61,
    "R",
    BTN_G
  )


  panel(
    173,
    211,
    294,
    37,
    8,
    6
  )

  ui.print(
    "RETORNAR: SEGURE BAIXO + B",
    184,
    219,
    6
  )

  ui.print(
    "(DOWN + BTN_X)",
    184,
    233,
    1
  )

  if held(DOWN) and held(BTN_X) then
    state=test_return_state
    active_test=nil
  end
end


local function draw_colors()
  ui.cls(0)

  ui.print(
    "TESTE DE CORES E PALETA",
    176,
    10,
    6
  )

  ui.print(
    "SETAS: SELECIONAR | A: PREENCHER | B: VOLTAR",
    176,
    24,
    1
  )

  local mx,my,bits=mouse_state()
  local hover_index=nil

  for i=0,15 do
    local col=i%8
    local row=math.floor(i/8)
    local x=174+col*36
    local y=51+row*58

    if
      mx>=x and
      mx<=x+29 and
      my>=y and
      my<=y+32
    then
      hover_index=i+1
    end

    ui.rectfill(
      x,
      y,
      x+29,
      y+32,
      i
    )

    local selected=(i==color_index-1)
    local hovered=(hover_index==i+1)

    ui.rect(
      x,
      y,
      x+29,
      y+32,
      (selected or hovered) and 6 or 1
    )

    if hovered then
      ui.rect(
        x+2,
        y+2,
        x+27,
        y+30,
        6
      )
    end

    ui.print(
      tostring(i),
      x+11,
      y+35,
      1
    )
  end

  ui.rectfill(
    174,174,
    466,205,
    8
  )

  ui.rect(
    174,174,
    466,205,
    6
  )

  ui.print(
    "INDICE: "..(color_index-1).." "..(colors[color_index] or "COR"),
    184,
    185,
    1
  )

  ui.print(
    "B RETORNA | CLIQUE DIREITO: SALA",
    184,
    232,
    6
  )

  if pressed(LEFT) then
    color_index=(color_index+14)%16+1
  end

  if pressed(RIGHT) then
    color_index=color_index%16+1
  end

  if pressed(UP) then
    color_index=math.max(1,color_index-8)
  end

  if pressed(DOWN) then
    color_index=math.min(16,color_index+8)
  end

  if hover_index then
    color_index=hover_index
  end

  if
    pressed(BTN_Z) or
    (mouse_left(bits) and not previous_mouse_left and hover_index)
  then
    state="colors_fill"
  end

  if pressed(BTN_X) then
    state=test_return_state
    active_test=nil
  end
end


local function draw_colors_fill()
  ui.cls(color_index-1)

  ui.print(
    "COR "..(color_index-1).." - "..(colors[color_index] or "COR"),
    176,
    10,
    ((color_index-1)==0 and 1 or 0)
  )

  ui.print(
    "B / CLIQUE DIREITO: VOLTAR AS CORES",
    176,
    25,
    ((color_index-1)==0 and 1 or 0)
  )

  if pressed(BTN_X) then
    state="colors"
  end
end


local function draw_readtext()
  if readtext_supported then
    for i=1,64 do
      local ch=ui.readtext()

      if type(ch)~="string" or #ch==0 then
        break
      end

      local lower=ch:lower()

      if
        ch=="\b" or
        ch==string.char(8) or
        ch=="\127" or
        ch==string.char(127) or
        lower=="backspace" or
        lower=="<backspace>"
      then
        if #notes>0 then
          local i=#notes

          while i>0 do
            local byte=notes:byte(i)

            if byte<128 or byte>=192 then
              break
            end

            i=i-1
          end

          notes=notes:sub(1,i-1)
        end

      elseif ch=="\r" or ch=="\n" then
        notes=notes.."\n"

      elseif ch:match("^[%g%s]$") then
        notes=notes..ch
      end
    end
  end

  ui.cls(0)

  ui.print(
    "TESTE READTEXT - BLOCO DE NOTAS",
    176,
    10,
    6
  )

  panel(
    174,38,
    292,174,
    0,
    6
  )

  ui.print(
    "Digite no teclado:",
    184,
    48,
    1
  )

  ui.line(
    184,65,
    456,65,
    7
  )

  local shown=notes

  if #shown>600 then
    shown=shown:sub(#shown-600+1)
  end

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

    if #visible>44 then
      visible=visible:sub(1,44)
    end

    ui.print(
      visible,
      184,
      73+(i-first)*10,
      1
    )
  end

  if not readtext_supported then
    ui.print(
      "ERRO: ui.readtext nao existe nesta API",
      174,
      220,
      3
    )
  else
    ui.print(
      "Caracteres recebidos: "..#notes,
      174,
      220,
      2
    )
  end

  ui.print(
    "CLIQUE DIREITO: SAIR PARA A SALA",
    184,
    246,
    6
  )
end


-- Busca limitada para evitar que o teste de Sonic consuma
-- instrucoes demais no watchdog.
local function find_sonic_animations()
  local result={
    walk={},
    roll={},
    idle={}
  }

  local seen={}
  local visited=0
  local MAX_NODES=2200

  local function walk(v,depth)
    if
      type(v)~="table" or
      seen[v] or
      depth>10 or
      visited>=MAX_NODES
    then
      return
    end

    seen[v]=true
    visited=visited+1

    local path=v.path

    if type(path)=="string" then
      if path:find("sprites/sonic/andar/f",1,true) then
        result.walk[#result.walk+1]=v
      end

      if path:find("sprites/sonic/rodar/f",1,true) then
        result.roll[#result.roll+1]=v
      end

      if path:find("sprites/sonic/parado/f",1,true) then
        result.idle[#result.idle+1]=v
      end

      -- Bitmap encontrado: nao precisa descer mais.
      if
        type(v.width)=="number" and
        type(v.height)=="number"
      then
        return
      end
    end

    for _,child in pairs(v) do
      if type(child)=="table" then
        walk(child,depth+1)
      end

      if visited>=MAX_NODES then
        break
      end
    end
  end

  if type(Sprites)=="table" then
    walk(Sprites,0)
  end

  local function sort_frames(t)
    table.sort(
      t,
      function(a,b)
        return tostring(a.path)<tostring(b.path)
      end
    )
  end

  sort_frames(result.walk)
  sort_frames(result.roll)
  sort_frames(result.idle)

  return result
end


local sonic={
  walk={},
  roll={},
  idle={},
  loaded=false
}


local function load_sonic()
  if sonic.loaded then
    return
  end

  pcall(require,"sprites")

  local found=find_sonic_animations()

  sonic.walk=found.walk
  sonic.roll=found.roll
  sonic.idle=found.idle

  sonic.loaded=true
end


local function draw_mouse_test(mx,my,bits,left_now,frame)
  load_sonic()

  ui.cls(0)

  ui.print(
    "TESTE DE MOUSE: ARRASTAR SONIC",
    176,
    10,
    6
  )

  -- Piso e plataforma com colisor correspondente.
  ui.rectfill(
    174,188,
    466,201,
    8
  )

  ui.rect(
    174,188,
    466,201,
    6
  )

  ui.rectfill(
    265,145,
    355,157,
    3
  )

  ui.rect(
    265,145,
    355,157,
    6
  )

  ui.print(
    "CHAO",
    180,
    207,
    1
  )

  ui.print(
    "PLATAFORMA",
    274,
    132,
    1
  )

  local s=drag.sprite

  if not drag.active then
    s.x=s.x+s.vx

    if s.x<190 or s.x>448 then
      s.vx=-s.vx
    end
  end

  if
    left_now and
    not previous_mouse_left
  then
    if
      mx>=s.x-16 and
      mx<=s.x+16 and
      my>=s.y-18 and
      my<=s.y+18
    then
      drag.active=true
      drag.dx=s.x-mx
      drag.dy=s.y-my
      s.vy=0
      s.rolling=false
    end
  end

  if left_now and drag.active then
    s.x=clamp(mx+drag.dx,188,450)
    s.y=clamp(my+drag.dy,45,181)
    s.vy=0

  elseif not left_now and drag.active then
    drag.active=false
    s.rolling=true
    s.roll_start=frame or 0
    s.vy=-1.5
  end

  if not drag.active then
    -- Gravidade suave.
    local old_y=s.y

    s.vy=(s.vy or 0)+0.22
    s.y=s.y+s.vy

    local floor_y=174

    if
      s.x>=249 and
      s.x<=371 and
      old_y<=132 and
      s.y>=132
    then
      floor_y=132
    end

    if s.y>=floor_y then
      s.y=floor_y
      s.vy=0
      s.rolling=false
    end
  end

  local frames

  if drag.active then
    frames=sonic.idle
  elseif s.rolling then
    frames=sonic.roll
  else
    frames=sonic.walk
  end


  if #frames>0 then
    local idx=
      math.floor((frame or 0)/5)%#frames+1

    -- IMPORTANTE:
    -- nao fazemos set_sonic_palette() aqui.
    -- O sprite encontrado pelo manifesto e desenhado
    -- diretamente com a paleta atualmente registrada.
    ui.spr(
      frames[idx],
      math.floor(s.x-12),
      math.floor(s.y-16),
      s.vx<0,
      false
    )

  else
    -- Fallback visual, caso o manifesto nao exponha
    -- os caminhos esperados.
    panel(
      s.x-10,
      s.y-12,
      20,
      24,
      drag.active and 6 or 4,
      1
    )

    ui.circfill(
      s.x-4,
      s.y-4,
      2,
      1
    )

    ui.circfill(
      s.x+4,
      s.y-4,
      2,
      1
    )
  end


  local over_sonic=
    mx>=s.x-16 and
    mx<=s.x+16 and
    my>=s.y-18 and
    my<=s.y+18

  if over_sonic then
    ui.print(
      drag.active and "SEGURANDO" or "SPRITE_CPU",
      mx+8,
      clamp(my-24,30,245),
      drag.active and 6 or 1
    )
  end


  panel(
    174,236,
    292,23,
    8,
    6
  )

  ui.print(
    "CLIQUE E ARRASTE | B RETORNA",
    180,
    243,
    1
  )

  if pressed(BTN_X) then
    state=test_return_state
    active_test=nil
    drag.active=false
  end
end


drag.sprite={
  x=220,
  y=174,
  vx=1.2,
  vy=0,
  rolling=false
}


local function collect_sprites(v,found,seen,depth)
  if
    type(v)~="table" or
    seen[v] or
    depth>8
  then
    return
  end

  seen[v]=true

  if
    type(v.path)=="string" and
    type(v.width)=="number" and
    type(v.height)=="number"
  then
    found[#found+1]=v
    return
  end

  for _,ch in pairs(v) do
    if type(ch)=="table" then
      collect_sprites(
        ch,
        found,
        seen,
        depth+1
      )
    end
  end
end


local function stress_draw(wheel_y)
  ui.cls(0)

  ui.print(
    "TESTE: "..string.upper(active_test or ""),
    176,
    12,
    6
  )

  panel(
    174,35,
    292,108,
    8,
    6
  )

  ui.print(
    "Multiplicador: x"..multiplier,
    184,
    46,
    6
  )

  ui.print(
    "SETAS / RODA DO MOUSE ajustam carga",
    184,
    61,
    1
  )

  ui.print(
    test_message,
    184,
    82,
    1
  )

  ui.print(
    "B RETORNA | CLIQUE DIREITO: SALA",
    184,
    232,
    6
  )

  if pressed(LEFT) then
    multiplier=math.max(1,multiplier-1)
    test_started=false
  end

  if pressed(RIGHT) then
    multiplier=math.min(100,multiplier+1)
    test_started=false
  end

  -- Mantido como no Debug Lab anterior.
  -- Mudancas definitivas na API do mouse ficam para a etapa SDK.
  if wheel_y>0 then
    multiplier=math.min(100,multiplier+1)
    test_started=false

  elseif wheel_y<0 then
    multiplier=math.max(1,multiplier-1)
    test_started=false
  end


  if active_test=="drawlist" then
    local count=math.min(4000,200*multiplier)

    for i=1,count do
      local x=VIEW_X+(i*17)%315
      local y=(i*29)%205+35

      ui.rectfill(
        x,y,
        x+2,y+2,
        i%16
      )
    end

    test_message=
      "Retangulos/frame: "..count..
      ". Confira Draw rejected."


  elseif active_test=="watchdog" then
    local n=0

    for i=1,500*multiplier do
      n=n+(i%7)
    end

    test_message=
      "Iteracoes/frame: "..(500*multiplier)..
      "; resultado="..n


  elseif
    active_test=="sprites" or
    active_test=="sdbytes" or
    active_test=="sdtx"
  then
    if not test_started then
      pcall(require,"sprites")

      local found,seen={},{}

      if type(Sprites)=="table" then
        collect_sprites(
          Sprites,
          found,
          seen,
          0
        )
      end

      if #found==0 then
        test_message=
          "Nenhum bitmap encontrado no manifesto Sprites."

      else
        local attempts=
          math.min(
            #found,
            32*multiplier
          )

        for i=1,attempts do
          local sp=found[i]

          ui.spr(
            sp,
            VIEW_X+((i-1)%6)*48,
            150+math.floor((i-1)/6)*24
          )
        end

        test_message=
          "Sprites: "..#found..
          "; tentativas: "..attempts
      end

      test_started=true
    end
  end


  if pressed(BTN_X) then
    state=test_return_state
    active_test=nil
    test_started=false
  end
end


local summary_tests={
  {
    id="watchdog",
    label="WATCHDOG - instrucoes Lua"
  },
  {
    id="drawlist",
    label="DRAWLIST - bytes graficos"
  },
  {
    id="sdbytes",
    label="SD BYTES - bytes lidos/frame"
  },
  {
    id="sdtx",
    label="SD TX - transacoes SD"
  },
  {
    id="sprites",
    label="SPRITES - carregamentos/frame"
  },
  {
    id="control",
    label="CONTROLE - botoes do gamepad"
  },
  {
    id="colors",
    label="CORES - paleta e indices"
  },
  {
    id="readtext",
    label="READTEXT - entrada de texto"
  },
  {
    id="mouse",
    label="MOUSE - arrastar Sonic CPU"
  }
}


local function draw_summary(mx,my,bits)
  ui.cls(0)

  ui.print(
    "SELECAO DE TESTES",
    176,
    10,
    6
  )

  panel(
    174,34,
    292,194,
    8,
    6
  )

  local hovered=nil

  for i,t in ipairs(summary_tests) do
    local y=43+(i-1)*18

    if
      mx>=180 and
      mx<=460 and
      my>=y-2 and
      my<=y+13
    then
      hovered=i
    end

    if
      i==summary_index or
      i==hovered
    then
      ui.rectfill(
        180,
        y-2,
        460,
        y+13,
        i==hovered and 6 or 3
      )
    end

    ui.print(
      string.format("%02d  %s",i,t.label),
      184,
      y,
      1
    )
  end

  ui.print(
    "SETA CIMA/BAIXO + A PARA ABRIR",
    176,
    237,
    6
  )

  ui.print(
    "B OU CLIQUE DIREITO: SALA",
    184,
    251,
    1
  )


  if pressed(UP) then
    summary_index=
      math.max(
        1,
        summary_index-1
      )
  end

  if pressed(DOWN) then
    summary_index=
      math.min(
        #summary_tests,
        summary_index+1
      )
  end

  if hovered then
    summary_index=hovered
  end


  if pressed(BTN_Z) then
    local id=
      summary_tests[summary_index].id

    for _,n in ipairs(npcs) do
      if n.id==id then
        begin_test(n,"summary")
        return
      end
    end
  end


  if
    hovered and
    mouse_left(bits) and
    not previous_mouse_left
  then
    local id=
      summary_tests[hovered].id

    for _,n in ipairs(npcs) do
      if n.id==id then
        begin_test(n,"summary")
        return
      end
    end
  end


  if pressed(BTN_X) then
    state="room"
    active_test=nil
  end
end


function update(frame)
  -- A interface continua usando a paleta de Debug a cada frame.
  set_palette()

  local mx,my,bits,wheel_x,wheel_y=
    mouse_state()

  mouse_world_x=
    mx+camera_x-VIEW_X

  mouse_world_y=my

  local left_now=mouse_left(bits)
  local right_now=mouse_right(bits)


  if
    right_now and
    not previous_mouse_right and
    state~="room"
  then
    if state=="colors_fill" then
      state="colors"

    elseif
      state=="dialogue" or
      state=="summary"
    then
      state="room"
      dialogue_npc=nil

    else
      -- Mantem a origem do teste:
      -- lista se veio da selecao, sala se veio de NPC.
      state=test_return_state or "room"
      active_test=nil
      test_started=false
    end

    dialogue_npc=nil
    drag.active=false
  end


  if state=="room" then
    local nx,ny=player.x,player.y

    if held(LEFT) then
      nx=nx-player.speed
    end

    if held(RIGHT) then
      nx=nx+player.speed
    end

    if held(UP) then
      ny=ny-player.speed
    end

    if held(DOWN) then
      ny=ny+player.speed
    end

    nx=clamp(
      nx,
      WORLD_MIN+8,
      WORLD_W-10
    )

    ny=clamp(
      ny,
      45,
      SCREEN_H-22
    )

    if not blocked(nx,player.y) then
      player.x=nx
    end

    if not blocked(player.x,ny) then
      player.y=ny
    end

    camera_x=
      math.max(
        WORLD_MIN,
        math.min(
          WORLD_W-320,
          player.x-160
        )
      )

    if pressed(BTN_Z) then
      local n=find_near_npc()

      if n then
        start_dialogue(n)
      end
    end

    local hovered=mouse_npc(mx,my)

    if
      left_now and
      not previous_mouse_left and
      hovered
    then
      start_dialogue(hovered)
    end

    draw_room(mx,my)


  elseif state=="dialogue" then
    draw_dialogue(mx,my)

    if
      pressed(BTN_Z) or
      (left_now and not previous_mouse_left)
    then
      begin_test(
        dialogue_npc,
        "room"
      )
    end

    if
      pressed(BTN_X) or
      (right_now and not previous_mouse_right)
    then
      state="room"
      dialogue_npc=nil
    end


  elseif state=="control" then
    draw_control()


  elseif state=="colors" then
    draw_colors()


  elseif state=="colors_fill" then
    draw_colors_fill()


  elseif state=="readtext" then
    draw_readtext()


  elseif state=="mouse" then
    draw_mouse_test(
      mx,
      my,
      bits,
      left_now,
      frame
    )


  elseif state=="summary" then
    draw_summary(
      mx,
      my,
      bits
    )


  elseif state=="stress" then
    local wheel=wheel_y

    if wheel==0 then
      wheel=wheel_x
    end

    stress_draw(wheel)
  end


  previous_mouse_left=left_now
  previous_mouse_right=right_now
end
