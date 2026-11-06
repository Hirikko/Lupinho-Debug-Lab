-- testes/audio.lua
local Utils = require "utils"
local M = {}

local function get_all_music_tracks()
  local tracks = {}
  local file = io.open("lupi_manifest.txt", "r") or io.open("loaded_game/lupi_manifest.txt", "r")
  if file then
    for line in file:lines() do
      local path = line:match("^%d+%s+%d+%s+([^%s]+)")
      if path and path:match("^music/") and line:match('"type":"binary"') then
        table.insert(tracks, path)
      end
    end
    file:close()
  end
  if #tracks == 0 then tracks = { "music/menu", "music/w1", "music/w2" } end
  table.sort(tracks)
  return tracks
end

local all_tracks = get_all_music_tracks()

local browser = {
  current_dir = "music/",
  items = {},
  index = 1,
  scroll = 0
}

local music_playing = false
local global_volume = 1.0
local saved_volume  = 1.0
local audio_channels_index = 1
local audio_controls_index = 1

local key_repeat = {
  timer = 0,
  delay = 0.3,
  rate = 0.05,
  last_key = nil
}
local last_time = 0

local channel_defs = {}
local function add_ch(name, mask_obj)
  if mask_obj then table.insert(channel_defs, { name=name, bit=mask_obj, muted=false }) end
end
add_ch("CH_1", CH_1); add_ch("CH_2", CH_2); add_ch("CH_3", CH_3); add_ch("CH_4", CH_4)
add_ch("CH_5", CH_5); add_ch("CH_6", CH_6); add_ch("CH_7", CH_7); add_ch("CH_8", CH_8)

local audio_controls_items = {
  { id="channels", label="CANAIS  - mute/desmute canais" },
  { id="volume",   label="VOLUME  - volume geral" },
}

local function apply_channel_state()
  if type(music) ~= "table" or not music.volume then return end
  for _, ch in ipairs(channel_defs) do
    music.volume(ch.muted and 0 or 1.0, ch.bit, 0.1)
  end
end

local function set_all_channels(muted)
  if type(music) ~= "table" or not music.volume then return end
  music.volume(muted and 0 or 1.0, CH_ALL, 0.1)
  for _, ch in ipairs(channel_defs) do ch.muted = muted end
end

local function apply_global_volume(fade)
  if type(music) ~= "table" or not music.volume then return end
  music.volume(global_volume, fade or 0.1)
end

local function toggle_mute()
  if global_volume > 0 then saved_volume = global_volume; global_volume = 0
  else global_volume = (saved_volume > 0) and saved_volume or 1.0 end
  apply_global_volume()
end

local function refresh_browser()
  browser.items = {}
  local dir_prefix = browser.current_dir
  for _, path in ipairs(all_tracks) do
    if path:sub(1, #dir_prefix) == dir_prefix then
      local rest = path:sub(#dir_prefix + 1)
      local slash = rest:find("/")
      if slash then
        local folder_name = rest:sub(1, slash - 1)
        local exists = false
        for _, item in ipairs(browser.items) do
          if item.type == "dir" and item.name == folder_name then exists = true break end
        end
        if not exists then
          table.insert(browser.items, { type = "dir", name = folder_name, path = dir_prefix .. folder_name .. "/" })
        end
      else
        table.insert(browser.items, { type = "file", name = rest, path = path })
      end
    end
  end
  table.sort(browser.items, function(a, b)
    if a.type ~= b.type then return a.type == "dir" end
    return a.name < b.name
  end)
  browser.index = 1
  browser.scroll = 0
end
refresh_browser()

local function audio_exit()
  return (Utils.pressed(BTN_X) and Utils.held(DOWN)) or (Utils.pressed(DOWN) and Utils.held(BTN_X))
end

local function activate_item()
  local item = browser.items[browser.index]
  if not item then return end
  if item.type == "dir" then
    browser.current_dir = item.path
    refresh_browser()
  else
    if type(music) == "table" and music.loop then
      music.loop(item.path, 0.5)
      music_playing = true
      apply_global_volume()
    end
  end
end

local function stop_music()
  if type(music) == "table" and music.stop then
    music.stop(0.5)
    music_playing = false
  end
end

local function go_back()
  if browser.current_dir ~= "music/" then
    local path = browser.current_dir:sub(1, -2)
    local last_slash = path:match(".*()/")
    if last_slash then browser.current_dir = path:sub(1, last_slash) else browser.current_dir = "music/" end
    refresh_browser()
  else
    LupiDebug.state = LupiDebug.test_return_state or "room"
    LupiDebug.active_test = nil
    if type(music) == "table" and music.stop then
      music.stop(0.5)
      music_playing = false
    end
  end
end

local function draw_controller_model(labels, cy)
  labels = labels or {}
  local cx = 320
  cy = cy or 145
  ui.rectfill(cx-130, cy-60, cx+130, cy+60, Utils.CColors.SNES_GRAY)
  ui.rect(cx-130, cy-60, cx+130, cy+60, 4)
  local dx, dy = cx-70, cy
  local up_h, down_h, left_h, right_h = Utils.held(UP), Utils.held(DOWN), Utils.held(LEFT), Utils.held(RIGHT)
  local db, df = Utils.CColors.DPAD, Utils.CColors.DPAD_flash
  ui.rectfill(dx-10, dy-22, dx+10, dy-5, up_h and df or db)
  ui.trisfill(dx-10, dy-22, dx+10, dy-22, dx, dy-32, up_h and df or db)
  ui.rectfill(dx-10, dy+5, dx+10, dy+22, down_h and df or db)
  ui.trisfill(dx-10, dy+22, dx+10, dy+22, dx, dy+32, down_h and df or db)
  ui.rectfill(dx-22, dy-10, dx-5, dy+10, left_h and df or db)
  ui.trisfill(dx-22, dy-10, dx-22, dy+10, dx-32, dy, left_h and df or db)
  ui.rectfill(dx+5, dy-10, dx+22, dy+10, right_h and df or db)
  ui.trisfill(dx+22, dy-10, dx+22, dy+10, dx+32, dy, right_h and df or db)
  ui.rect(dx-22, dy-22, dx+22, dy+22, 1)
  if labels.up then ui.print(labels.up, dx-#labels.up*3, dy-42, 1) end
  if labels.down then ui.print(labels.down, dx-#labels.down*3, dy+38, 1) end
  if labels.left then ui.print(labels.left, dx-52, dy-3, 1) end
  if labels.right then ui.print(labels.right, dx+38, dy-3, 1) end
  local bx, by = cx+65, cy
  local R = 26
  local function btn(x, y, letter, label)
    local b_map = { Y = BTN_Q, X = BTN_E, A = BTN_Z, B = BTN_X }
    local is_h = Utils.held(b_map[letter])
    local bc, fc = Utils.CColors[letter], Utils.CColors[letter .. "_flash"]
    ui.circfill(x, y, 10, 8)
    ui.circfill(x, y, 7, is_h and fc or bc)
    ui.print(letter, x-3, y-3, 1)
    if label then
      local lx, ly = x - math.floor(#label*6/2), y + 14
      if letter == "Y" then ly = y - 20 end
      ui.print(label, lx, ly, 1)
    end
  end
  btn(bx, by - R, "Y", labels.Y)
  btn(bx - R, by, "X", labels.X)
  btn(bx, by + R, "A", labels.A)
  btn(bx + R, by, "B", labels.B)
  local function shoulder(x, y, letter, label)
    local b_map = { L = BTN_F, R = BTN_G }
    local is_h = Utils.held(b_map[letter])
    local fill = is_h and Utils.CColors.SHOULDER_flash or Utils.CColors.SHOULDER
    ui.rectfill(x-24, y-8, x+24, y+8, 8)
    ui.rect(x-24, y-8, x+24, y+8, 1)
    ui.rectfill(x-21, y-6, x+21, y+6, fill)
    ui.print(letter, x-3, y-3, 1)
    if label then ui.print(label, x-#label*3, y-18, 1) end
  end
  shoulder(cx-70, cy-75, "L", labels.L)
  shoulder(cx+70, cy-75, "R", labels.R)
end

function M.update(input, frame)
  local current_time = os.clock()
  local dt = current_time - last_time
  last_time = current_time
  if dt > 0.1 then dt = 0.1 end

  if LupiDebug.state == "audio_menu" then
    ui.cls(0)
    ui.print("SOM - NAVEGADOR", 176, 10, 6)
    local display_path = "/" .. browser.current_dir
    if #display_path > 45 then display_path = "..." .. display_path:sub(-42) end
    ui.print("DIR: " .. display_path, 176, 24, 2)
    Utils.panel(174, 38, 292, 180, 8, 6)
    local visible_items = 14
    if browser.index > browser.scroll + visible_items then
      browser.scroll = browser.index - visible_items
    elseif browser.index <= browser.scroll then
      browser.scroll = browser.index - 1
    end
    local hovered_idx = nil
    for i = 1, visible_items do
      local item_idx = i + browser.scroll
      local item = browser.items[item_idx]
      if item then
        local y = 42 + (i-1)*12
        local bx1, by1, bx2, by2 = 176, y-1, 464, y+10
        local is_hover = (input.mx >= bx1 and input.mx <= bx2 and input.my >= by1 and input.my <= by2)
        if is_hover then hovered_idx = item_idx end
        if item_idx == browser.index or is_hover then
          ui.rectfill(bx1, by1, bx2, by2, 3)
        end
        local prefix = item.type == "dir" and "[DIR] " or "      "
        local color = item.type == "dir" and 6 or 1
        ui.print(prefix .. item.name, 180, y, color)
      end
    end
    ui.print("SETAS/SCROLL: NAVEGAR | A/ESQ: ENTRAR/TOCAR", 176, 232, 6)
    ui.print("X/DIR: VOLTAR | B: STOP | Y: CONTROLES", 176, 246, 1)
    local max_idx = #browser.items
    if max_idx > 0 then
      if hovered_idx then browser.index = hovered_idx end
      local dir = nil
      local step = 1
      if Utils.held(UP) then dir = "up"
      elseif Utils.held(DOWN) then dir = "down"
      elseif Utils.held(RIGHT) then dir = "right"; step = 5
      elseif Utils.held(LEFT) then dir = "left"; step = 5
      end
      if dir then
        local just_pressed = Utils.pressed(UP) or Utils.pressed(DOWN) or Utils.pressed(LEFT) or Utils.pressed(RIGHT)
        if just_pressed or dir ~= key_repeat.last_key then
          key_repeat.last_key = dir
          key_repeat.timer = key_repeat.delay
          if dir == "up" then browser.index = math.max(1, browser.index - step) end
          if dir == "down" then browser.index = math.min(max_idx, browser.index + step) end
          if dir == "left" then browser.index = math.max(1, browser.index - step) end
          if dir == "right" then browser.index = math.min(max_idx, browser.index + step) end
        else
          key_repeat.timer = key_repeat.timer - dt
          if key_repeat.timer <= 0 then
            key_repeat.timer = key_repeat.rate
            if dir == "up" then browser.index = math.max(1, browser.index - step) end
            if dir == "down" then browser.index = math.min(max_idx, browser.index + step) end
            if dir == "left" then browser.index = math.max(1, browser.index - step) end
            if dir == "right" then browser.index = math.min(max_idx, browser.index + step) end
          end
        end
      else
        key_repeat.last_key = nil
        key_repeat.timer = 0
      end
      if input.wheel_y > 0 then browser.index = math.max(1, browser.index - 1) end
      if input.wheel_y < 0 then browser.index = math.min(max_idx, browser.index + 1) end

      if Utils.pressed(BTN_Z) or (input.left_now and not input.previous_mouse_left) then
        activate_item()
      end
      if Utils.pressed(BTN_E) or (input.right_now and not input.previous_mouse_right) then
        go_back()
      end
      if Utils.pressed(BTN_X) and not Utils.held(DOWN) then
        stop_music()
      end
    end
    if Utils.pressed(BTN_Q) then LupiDebug.state = "audio_controls" return end
    if audio_exit() then LupiDebug.state = LupiDebug.test_return_state or "room" LupiDebug.active_test = nil end

  elseif LupiDebug.state == "audio_controls" then
    ui.cls(0)
    ui.print("CONTROLES DE SOM", 176, 10, 6)
    ui.print("Escolha um submenu para testar", 176, 24, 1)
    Utils.panel(174, 38, 292, 90, 8, 6)
    local hovered = nil
    for i, item in ipairs(audio_controls_items) do
      local y = 48 + (i-1)*26
      if input.mx >= 180 and input.mx <= 460 and input.my >= y-2 and input.my <= y+16 then hovered = i end
      if i == audio_controls_index or i == hovered then ui.rectfill(180, y-2, 460, y+16, i==hovered and 6 or 3) end
      ui.print(string.format("%02d  %s", i, item.label), 184, y+2, 1)
    end
    ui.print("SETAS+A: ABRIR  |  BAIXO+B: VOLTAR", 176, 246, 6)
    if Utils.pressed(UP) then audio_controls_index = math.max(1, audio_controls_index - 1) end
    if Utils.pressed(DOWN) and not Utils.held(BTN_X) then audio_controls_index = math.min(#audio_controls_items, audio_controls_index + 1) end
    if hovered and input.mouse_moved then audio_controls_index = hovered end
    if Utils.pressed(BTN_Z) then
      local id = audio_controls_items[audio_controls_index].id
      if id == "channels" then LupiDebug.state="audio_channels" elseif id == "volume" then LupiDebug.state="audio_volume" end
      return
    end
    if hovered and Utils.mouse_left(input.bits) and not input.previous_mouse_left then
      local id = audio_controls_items[hovered].id
      if id == "channels" then LupiDebug.state="audio_channels" elseif id == "volume" then LupiDebug.state="audio_volume" end
      return
    end
    if audio_exit() then LupiDebug.state = "audio_menu" end

  elseif LupiDebug.state == "audio_channels" then
    ui.cls(0)
    ui.print("SOM - CANAIS INDIVIDUAIS", 176, 10, 6)
    for i, ch in ipairs(channel_defs) do
      local col, row = math.floor((i-1) / 4), (i-1) % 4
      local x, y = 184 + col * 140, 36 + row * 20
      local color, status = ch.muted and 4 or 2, ch.muted and "MUDO" or "ON"
      if i == audio_channels_index then ui.rectfill(x-4, y-2, x+120, y+13, 8) end
      ui.print(string.format("%02d  %-6s %s", i, ch.name, status), x, y, color)
    end
    Utils.panel(174, 170, 292, 55, 8, 6)
    ui.print("BOTOES L e R (Triggers)", 184, 178, 6)
    ui.print("L: Desliga todos os canais", 184, 192, 1)
    ui.print("R: Liga todos os canais", 184, 206, 1)
    ui.print("CIMA/BAIXO: SELECIONAR | A: LIGAR/DESLIGAR", 176, 235, 6)
    ui.print("BAIXO+B: VOLTAR", 176, 248, 1)
    if Utils.pressed(UP) then audio_channels_index = math.max(1, audio_channels_index - 1) end
    if Utils.pressed(DOWN) and not Utils.held(BTN_X) then audio_channels_index = math.min(#channel_defs, audio_channels_index + 1) end
    if Utils.pressed(BTN_Z) then local ch = channel_defs[audio_channels_index] ch.muted = not ch.muted apply_channel_state() end
    if Utils.pressed(BTN_F) then set_all_channels(true) end
    if Utils.pressed(BTN_G) then set_all_channels(false) end
    for i, ch in ipairs(channel_defs) do
      local col, row = math.floor((i-1) / 4), (i-1) % 4
      local x, y = 184 + col * 140, 36 + row * 20
      if input.mx >= x and input.mx <= x+120 and input.my >= y-2 and input.my <= y+13 then
          if Utils.mouse_left(input.bits) and not input.previous_mouse_left then ch.muted = not ch.muted apply_channel_state() end
      end
    end
    if audio_exit() then LupiDebug.state = "audio_controls" end

  elseif LupiDebug.state == "audio_volume" then
    ui.cls(0)
    ui.print("SOM - VOLUME GERAL (MASTER)", 176, 10, 6)
    local bar_x, bar_y, bar_w = 184, 26, 260
    ui.rectfill(bar_x, bar_y, bar_x+bar_w, bar_y+8, 7)
    local filled = math.floor(bar_w * global_volume)
    if filled > 0 then ui.rectfill(bar_x, bar_y, bar_x+filled, bar_y+8, 2) end
    ui.rect(bar_x, bar_y, bar_x+bar_w, bar_y+8, 1)
    ui.print("Volume: "..math.floor(global_volume*100).."%", 184, 42, 6)
    ui.print("(0% = mudo)  Salvo: "..math.floor(saved_volume*100).."%", 184, 56, 1)
    draw_controller_model({
      up = "+10%", down = "-10%", left = "-1%", right = "+1%",
      Y = "100%", X = "FADE IN", A = "FADE OUT", B = "MUTE",
      L = "-10%", R = "+10%",
    }, 165)
    ui.print("BAIXO+B: VOLTAR", 176, 246, 6)
    if Utils.pressed(UP) then global_volume = math.min(1, global_volume + 0.10); apply_global_volume() end
    if Utils.pressed(DOWN) and not Utils.held(BTN_X) then global_volume = math.max(0, global_volume - 0.10); apply_global_volume() end
    if Utils.pressed(LEFT) then global_volume = math.max(0, global_volume - 0.01); apply_global_volume() end
    if Utils.pressed(RIGHT) then global_volume = math.min(1, global_volume + 0.01); apply_global_volume() end
    if Utils.pressed(BTN_F) then global_volume = math.max(0, global_volume - 0.10); apply_global_volume() end
    if Utils.pressed(BTN_G) then global_volume = math.min(1, global_volume + 0.10); apply_global_volume() end
    if Utils.pressed(BTN_Q) then global_volume = 1.0 apply_global_volume() end
    if Utils.pressed(BTN_Z) then if type(music) == "table" and music.volume then music.volume(0.0, 4.0) global_volume = 0 end end
    if Utils.pressed(BTN_E) then if type(music) == "table" and music.volume then music.volume(1.0, 4.0) global_volume = 1.0 end end
    if Utils.pressed(BTN_X) and not Utils.held(DOWN) then toggle_mute() end
    if audio_exit() then LupiDebug.state = "audio_controls" end
  end
end

return M
