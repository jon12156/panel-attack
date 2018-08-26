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
require("sound")
require("timezones")
require("gen_panels")

local N_FRAMES = 0
local canvas
if love.graphics.isSupported("canvas") then
  canvas = love.graphics.newCanvas(default_width, default_height)
end
local last_x = 0
local last_y = 0
local input_delta = 0.0
local pointer_hidden = false

function love.load()
  math.randomseed(os.time())
  for i=1,4 do math.random() end
  read_key_file()
  mainloop = coroutine.create(fmainloop)
end

function love.update(dt)
  if love.mouse.getX() == last_x and love.mouse.getY() == last_y then
    if not pointer_hidden then
      if input_delta > mouse_pointer_timeout then
        pointer_hidden = true
        love.mouse.setVisible(false)
      else
       input_delta = input_delta + dt
      end
    end
  else
    last_x = love.mouse.getX()
    last_y = love.mouse.getY()
    input_delta = 0.0
    if pointer_hidden then
      pointer_hidden = false
      love.mouse.setVisible(true)
    end
  end
  
  
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
  if love.graphics.isSupported("canvas") then
    love.graphics.setCanvas(canvas)  
    love.graphics.setBackgroundColor(28, 28, 28)
    love.graphics.clear()
  else
    love.graphics.setColor(28, 28, 28)
    love.graphics.rectangle("fill",-5,-5,900,900)
    love.graphics.setColor(255, 255, 255)
  end
  for i=gfx_q.first,gfx_q.last do
    gfx_q[i][1](unpack(gfx_q[i][2]))
  end
  love.graphics.print("FPS: "..love.timer.getFPS(),315,115)
  N_FRAMES = N_FRAMES + 1
  if love.graphics.isSupported("canvas") then
    love.graphics.setCanvas()
    love.graphics.clear()
    x, y, w, h = scale_letterbox(love.graphics.getWidth(), love.graphics.getHeight(), 4, 3)
    love.graphics.draw(canvas, x, y, 0, w / default_width, h / default_height)
  end
end
