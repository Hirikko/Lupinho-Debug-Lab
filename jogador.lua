-- jogador.lua
local Utils = require "utils"
local M = {}

M.x = 205
M.y = 205
M.speed = 3.8
M.r = 6

local function player_box(x,y) return { x1=x-6, y1=y-8, x2=x+6, y2=y+8 } end
local function overlaps(a,b) return a.x1 < b.x2 and a.x2 > b.x1 and a.y1 < b.y2 and a.y2 > b.y1 end

local function blocked(x, y, npcs_list)
  local p = player_box(x,y)
  for _,n in ipairs(npcs_list) do
    local b={ x1=n.x-19, y1=n.y-18, x2=n.x+19, y2=n.y+18 }
    if overlaps(p,b) then return true end
  end
  return false
end

function M.update(npcs_list)
  local nx, ny = M.x, M.y
  if Utils.held(LEFT)  then nx=nx-M.speed end
  if Utils.held(RIGHT) then nx=nx+M.speed end
  if Utils.held(UP)    then ny=ny-M.speed end
  if Utils.held(DOWN)  then ny=ny+M.speed end

  nx=Utils.clamp(nx, LupiDebug.WORLD_MIN+8, LupiDebug.WORLD_W-10)
  ny=Utils.clamp(ny, 45, LupiDebug.SCREEN_H-22)

  if not blocked(nx, M.y, npcs_list) then M.x=nx end
  if not blocked(M.x, ny, npcs_list) then M.y=ny end
end

function M.draw(camera_x)
  local sx = M.x - camera_x + LupiDebug.VIEW_X
  ui.rectfill(sx-5, M.y-7, sx+5, M.y+7, 1)
  ui.rect(sx-6, M.y-8, sx+6, M.y+8, 8)
  ui.rectfill(sx-3, M.y-4, sx+3, M.y-1, 3)
end

return M
