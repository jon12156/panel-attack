socket = require("socket")
json = require("dkjson")
require("util")
require("class")
require("queue")
require("globals")
require("save")
require("engine")
require("graphics")
require("input")
require("network")
require("puzzles")
require("mainloop")
require("consts")

local N_FRAMES = 0
local canvas = love.graphics.newCanvas(default_width, default_height)

function love.load()
  math.randomseed(os.time())
  for i=1,4 do math.random() end
  read_key_file()
  read_conf_file() -- TODO: stop making new config files
  replay = {}
  read_replay_file()
  graphics_init() -- load images and set up stuff
  mainloop = coroutine.create(fmainloop)
end

function love.update(dt)
  if consuming_timesteps then
    leftover_time = leftover_time + dt
  end
  joystick_ax()
  if not consuming_timesteps then
    key_counts()
  end
  gfx_q:clear()
  local status, err = coroutine.resume(mainloop)
  if not status then
    error(err..'\n'..debug.traceback(mainloop))
  end
  if not consuming_timesteps then
    this_frame_keys = {}
    this_frame_unicodes = {}
  end
  this_frame_messages = {}
end

function love.draw()
  love.graphics.setCanvas(canvas)  
  love.graphics.setBackgroundColor(28, 28, 28)
  love.graphics.clear()
  for i=gfx_q.first,gfx_q.last do
    gfx_q[i][1](unpack(gfx_q[i][2]))
  end
  love.graphics.print("FPS: "..love.timer.getFPS(),315,115)
  N_FRAMES = N_FRAMES + 1
  love.graphics.setCanvas()
  love.graphics.clear()
  x, y, w, h = scale_letterbox(love.graphics.getWidth(), love.graphics.getHeight(), 4, 3)
  love.graphics.draw(canvas, x, y, 0, w / default_width, h / default_height)
end
