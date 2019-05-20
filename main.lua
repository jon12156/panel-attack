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

local canvas = love.graphics.newCanvas(default_width, default_height)

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



  leftover_time = leftover_time + dt

  local status, err = coroutine.resume(mainloop)
  if not status then
    error(err..'\n'..debug.traceback(mainloop))
  end
  this_frame_messages = {}

  --Play music here
  for k, v in pairs(music_t) do
    if v and k - love.timer.getTime() < 0.007 then
      v.t:stop()
      v.t:play()
      currently_playing_tracks[#currently_playing_tracks+1]=v.t
      if v.l then
        music_t[love.timer.getTime() + v.t:getDuration()] = make_music_t(v.t, true)
      end
      music_t[k] = nil
    end
  end
end

bg = load_img("menu/title.png")
function love.draw()
  local draw_start_time = love.timer.getTime()
  -- if not main_font then
    -- main_font = love.graphics.newFont("Oswald-Light.ttf", 15)
  -- end
  -- main_font:setLineHeight(0.66)
  -- love.graphics.setFont(main_font)
  if love.graphics.getSupported("canvas") then
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setCanvas(canvas)
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    love.graphics.clear()
  else
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill",-5,-5,900,900)
    love.graphics.setColor(1, 1, 1)
  end
  local gfx_unpack_start_time = love.timer.getTime()
  local sum_gfx_operation_times = 0
  print("#graphics operations this frame: "..gfx_q:len())
  local above_threshold1, above_threshold2 = 0,0
  for i=gfx_q.first,gfx_q.last do
    local gfx_operation_start_time = love.timer.getTime()
    gfx_q[i][1](unpack(gfx_q[i][2]))
    local this_operation_time = love.timer.getTime()-gfx_operation_start_time
    --print("gfx operation completed in "..round(this_operation_time, 6).." sec")
    sum_gfx_operation_times = sum_gfx_operation_times + this_operation_time
    -- if this_operation_time > 0.00005 then
      -- above_threshold1 = above_threshold1 + 1
      -- if this_operation_time > .001 then
        -- above_threshold2 = above_threshold2 + 1
      -- end
    -- end
  end
  -- print("sum_gfx_operation_times = "..sum_gfx_operation_times)
  -- print("gfx unpack completed in "..round(love.timer.getTime()-gfx_unpack_start_time, 6).." sec")
  -- print("#above_threshold1 = "..above_threshold1)
  -- print("#above_threshold2 = "..above_threshold2)
  gfx_q:clear()
  love.graphics.print("FPS: "..love.timer.getFPS(),315,115) -- TODO: Make this a toggle
  if love.graphics.getSupported("canvas") then
    love.graphics.setCanvas()
    love.graphics.clear(love.graphics.getBackgroundColor())
    x, y, w, h = scale_letterbox(love.graphics.getWidth(), love.graphics.getHeight(), 4, 3)
    love.graphics.setBlendMode("alpha","premultiplied")
    love.graphics.draw(canvas, x, y, 0, w / default_width, h / default_height)
    bgw, bgh = bg:getDimensions()
    menu_draw(bg, 0, 0, 0, default_width/bgw, default_height/bgh)
  end
  print("frame draw completed in "..round(love.timer.getTime()-draw_start_time, 6).." sec\n")
  
end
