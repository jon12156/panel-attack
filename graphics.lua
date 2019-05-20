require("input")
require("util")

local floor = math.floor
local ceil = math.ceil

function load_img(path_and_name)
  local img
  if pcall(function ()
    img = love.image.newImageData("assets/"..(config.assets_dir or default_assets_dir).."/"..path_and_name)
  end) then
    if config.assets_dir and config.assets_dir ~= default_assets_dir then
      print("loaded custom asset: "..config.assets_dir.."/"..path_and_name)
    end
  else
    if pcall(function ()
      img = love.image.newImageData("assets/"..default_assets_dir.."/"..path_and_name)
    end) then
      print("loaded okay.")
    else
      img = nil
    end
  end
  if img == nil then
    return nil
  end
  local ret = love.graphics.newImage(img)
  ret:setFilter("nearest","nearest")
  return ret
end

function draw(img, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  gfx_q:push({love.graphics.draw, {img, x*GFX_SCALE, y*GFX_SCALE,
    rot, x_scale*GFX_SCALE, y_scale*GFX_SCALE}})
end

function menu_draw(img, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  gfx_q:push({love.graphics.draw, {img, x, y,
    rot, x_scale, y_scale}})
end

function menu_drawq(img, quad, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  gfx_q:push({love.graphics.draw, {img, quad, x, y,
    rot, x_scale, y_scale}})
end

function grectangle(mode, x, y, w, h)
  gfx_q:push({love.graphics.rectangle, {mode, x, y, w, h}})
end

function gprint(str, x, y)
  x = x or 0
  y = y or 0
  set_color(0, 0, 0, 1)
  gfx_q:push({love.graphics.print, {str, x+1, y+1}})
  set_color(1, 1, 1, 1)
  gfx_q:push({love.graphics.print, {str, x, y}})
end

local _r, _g, _b, _a
function set_color(r, g, b, a)
  a = a or 1
  -- only do it if this color isn't the same as the previous one...
  if _r~=r or _g~=g or _b~=b or _a~=a then
      _r,_g,_b,_a = r,g,b,a
      gfx_q:push({love.graphics.setColor, {r, g, b, a}})
  end
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

IMG_stagecount = 1
function graphics_init()
  title = load_img("menu/title.png")
  charselect = load_img("menu/charselect.png")
  IMG_stages = {}

  IMG_stagecount = 1
  i = 0
  while i > -1 do
    IMG_stages[IMG_stagecount] = load_img("stages/"..tostring(IMG_stagecount)..".png")
    if IMG_stages[IMG_stagecount] == nil then
      i=-1
      break
    else
      IMG_stagecount=IMG_stagecount+1
    end
  end

  IMG_panels = {}
  for i=1,8 do
    IMG_panels[i]={}
    for j=1,7 do
      IMG_panels[i][j]=load_img("panel"..
        tostring(i)..tostring(j)..".png")
    end
  end
  IMG_panels[9]={}
  for j=1,7 do
    IMG_panels[9][j]=load_img("panel00.png")
  end

  local g_parts = {"topleft", "botleft", "topright", "botright",
                    "top", "bot", "left", "right", "face", "pop",
                    "doubleface", "filler1", "filler2", "flash",
                    "portrait"}
  IMG_garbage = {}
  for _,key in ipairs(characters) do
    local imgs = {}
    IMG_garbage[key] = imgs
    for _,part in ipairs(g_parts) do
      imgs[part] = load_img(""..key.."/"..part..".png")
    end
  end

  IMG_metal_flash = load_img("garbageflash.png")
  IMG_metal = load_img("metalmid.png")
  IMG_metal_l = load_img("metalend0.png")
  IMG_metal_r = load_img("metalend1.png")

  IMG_ready = load_img("ready.png")
  IMG_numbers = {}
  for i=1,3 do
    IMG_numbers[i] = load_img(i..".png")
  end
  IMG_cursor = {  load_img("cur0.png"),
          load_img("cur1.png")}

  IMG_frame = load_img("frame.png")
  IMG_wall = load_img("wall.png")

  IMG_cards = {}
  IMG_cards[true] = {}
  IMG_cards[false] = {}
  for i=4,66 do
    IMG_cards[false][i] = load_img("combo"
      ..tostring(floor(i/10))..tostring(i%10)..".png")
  end
  for i=2,13 do
    IMG_cards[true][i] = load_img("chain"
      ..tostring(floor(i/10))..tostring(i%10)..".png")
  end
  for i=14,99 do
    IMG_cards[true][i] = load_img("chain00.png")
  end
  IMG_character_icons = {}
  for _, name in ipairs(characters) do
    IMG_character_icons[name] = load_img(""..name.."/icon.png")
  end
  local MAX_SUPPORTED_PLAYERS = 2
  IMG_char_sel_cursors = {}
  for player_num=1,MAX_SUPPORTED_PLAYERS do
    IMG_char_sel_cursors[player_num] = {}
    for position_num=1,2 do
      IMG_char_sel_cursors[player_num][position_num] = load_img("char_sel_cur_"..player_num.."P_pos"..position_num..".png")
    end
  end
  IMG_char_sel_cursor_halves = {left={}, right={}}
  for player_num=1,MAX_SUPPORTED_PLAYERS do
    IMG_char_sel_cursor_halves.left[player_num] = {}
    for position_num=1,2 do
      local cur_width, cur_height = IMG_char_sel_cursors[player_num][position_num]:getDimensions()
      local half_width, half_height = cur_width/2, cur_height/2 -- TODO: is these unused vars an error ??? -Endu
      IMG_char_sel_cursor_halves["left"][player_num][position_num] = love.graphics.newQuad(0,0,half_width,cur_height,cur_width, cur_height)
    end
    IMG_char_sel_cursor_halves.right[player_num] = {}
    for position_num=1,2 do
      local cur_width, cur_height = IMG_char_sel_cursors[player_num][position_num]:getDimensions()
      local half_width, half_height = cur_width/2, cur_height/2
      IMG_char_sel_cursor_halves.right[player_num][position_num] = love.graphics.newQuad(half_width,0,half_width,cur_height,cur_width, cur_height)
    end
  end
  character_display_names = {}
  for _, original_name in ipairs(characters) do
    name_txt_file = love.filesystem.newFile("assets/"..config.assets_dir.."/"..original_name.."/name.txt")
    open_success, err = name_txt_file:open("r")
    local display_name = name_txt_file:read(name_txt_file:getSize())
    if display_name then
      character_display_names[original_name] = display_name
    else
      character_display_names[original_name] = original_name
    end
  end
  print("character_display_names: ")
  for k,v in pairs(character_display_names) do
    print(k.." = "..v)
  end
  character_display_names_to_original_names = {}
  for k,v in pairs(character_display_names) do
    character_display_names_to_original_names[v] = k
  end
end

function Stack.update_cards(self)
  for i=self.card_q.first,self.card_q.last do
    local card = self.card_q[i]
    if card_animation[card.frame] then
      card.frame = card.frame + 1
      if(card_animation[card.frame]==nil) then
        self.card_q:pop()
      end
    else
      card.frame = card.frame + 1
    end
  end
end

function Stack.draw_cards(self)
  for i=self.card_q.first,self.card_q.last do
    local card = self.card_q[i]
    if card_animation[card.frame] then
      local draw_x = (card.x-1) * 16 + self.pos_x
      local draw_y = (11-card.y) * 16 + self.pos_y + self.displacement
          - card_animation[card.frame]
      draw(IMG_cards[card.chain][card.n], draw_x, draw_y)
    end
  end
end

function Stack.render(self)
  local mx,my
  local render_start_time = love.timer.getTime()
  if config.debug_mode then
    mx,my = love.mouse.getPosition()
    mx = mx / GFX_SCALE
    my = my / GFX_SCALE
  end
  local portrait_w, portrait_h = IMG_garbage[self.character].portrait:getDimensions()
  if P1 == self then
    draw(IMG_garbage[self.character].portrait, self.pos_x, self.pos_y, 0, 96/portrait_w, 192/portrait_h)
  else
    draw(IMG_garbage[self.character].portrait, self.pos_x+96, self.pos_y, 0, (96/portrait_w)*-1, 192/portrait_h)
  end
  local metal_w, metal_h = IMG_metal:getDimensions()
  local metall_w, metall_h = IMG_metal_l:getDimensions()
  local metalr_w, metalr_h = IMG_metal_r:getDimensions()
  local shake_idx = #shake_arr - self.shake_time
  local shake = ceil((shake_arr[shake_idx] or 0) * 13)
  for row=0,self.height do
    for col=1,self.width do
      local panel = self.panels[row][col]
      local draw_x = (col-1) * 16 + self.pos_x
      local draw_y = (11-(row)) * 16 + self.pos_y + self.displacement - shake
      if panel.color ~= 0 and panel.state ~= "popped" then
        local draw_frame = 1
        if panel.garbage then
          local imgs = {flash=IMG_metal_flash}
          if not panel.metal then
            imgs = IMG_garbage[self.garbage_target.character]
          end
          if panel.x_offset == 0 and panel.y_offset == 0 then
            -- draw the entire block!
            if panel.metal then
              draw(IMG_metal_l, draw_x, draw_y, 0, 8/metall_w, 16/metall_h)
              draw(IMG_metal_r, draw_x+16*(panel.width-1)+8,draw_y, 0, 8/metalr_w, 16/metalr_h)
              for i=1,2*(panel.width-1) do
                draw(IMG_metal, draw_x+8*i, draw_y, 0, 8/metal_w, 16/metal_h)
              end
            else
              local height, width = panel.height, panel.width
              local top_y = draw_y - (height-1) * 16
              local use_1 = ((height-(height%2))/2)%2==0
              local filler_w, filler_h = imgs.filler1:getDimensions()
              for i=0,height-1 do
                for j=1,width-1 do
                  draw((use_1 or height<3) and imgs.filler1 or
                    imgs.filler2, draw_x+16*j-8, top_y+16*i, 0, 16/filler_w, 16/filler_h)
                  use_1 = not use_1
                end
              end
              if height%2==1 then
                local face_w, face_h = imgs.face:getDimensions()
                draw(imgs.face, draw_x+8*(width-1), top_y+16*((height-1)/2), 0, 16/face_w, 16/face_h)
              else
                local face_w, face_h = imgs.doubleface:getDimensions()
                draw(imgs.doubleface, draw_x+8*(width-1), top_y+16*((height-2)/2), 0, 16/face_w, 32/face_h)
              end
              local corner_w, corner_h = imgs.topleft:getDimensions()
              local lr_w, lr_h = imgs.left:getDimensions()
              local topbottom_w, topbottom_h = imgs.top:getDimensions()
              draw(imgs.left, draw_x, top_y, 0, 8/lr_w, (1/lr_h)*height*16)
              draw(imgs.right, draw_x+16*(width-1)+8, top_y, 0, 8/lr_w, (1/lr_h)*height*16)
              draw(imgs.top, draw_x, top_y, 0, (1/topbottom_w)*width*16, 2/topbottom_h)
              draw(imgs.bot, draw_x, draw_y+14, 0, (1/topbottom_w)*width*16, 2/topbottom_h)
              draw(imgs.topleft, draw_x, top_y, 0, 8/corner_w, 3/corner_h)
              draw(imgs.topright, draw_x+16*width-8, top_y, 0, 8/corner_w, 3/corner_h)
              draw(imgs.botleft, draw_x, draw_y+13, 0, 8/corner_w, 3/corner_h)
              draw(imgs.botright, draw_x+16*width-8, draw_y+13, 0, 8/corner_w, 3/corner_h)
            end
          end
          if panel.state == "matched" then
            local flash_time = panel.initial_time - panel.timer


            local flashed_w, flashed_h = IMG_metal_flash:getDimensions()
            if flash_time >= self.FRAMECOUNT_FLASH then
              if panel.timer > panel.pop_time then
                if panel.metal then
                  draw(IMG_metal_l, draw_x, draw_y, 0, 8/metall_w, 16/metall_h)
                  draw(IMG_metal_r, draw_x+8, draw_y, 0, 8/metalr_w, 16/metalr_h)
                else
                  local popped_w, popped_h = imgs.pop:getDimensions()
                  draw(imgs.pop, draw_x, draw_y, 0, 16/popped_w, 16/popped_h)
                end
              elseif panel.y_offset == -1 then
                local p_w, p_h = IMG_panels[panel.color][1]:getDimensions()
                draw(IMG_panels[panel.color][1], draw_x, draw_y, 0, 16/p_w, 16/p_h)
              end
            elseif flash_time % 2 == 1 then
              if panel.metal then
                draw(IMG_metal_l, draw_x, draw_y, 0, 8/metall_w, 16/metall_h)
                draw(IMG_metal_r, draw_x+8, draw_y, 0, 8/metalr_w, 16/metalr_h)
              else
                local popped_w, popped_h = imgs.pop:getDimensions()
                draw(imgs.pop, draw_x, draw_y, 0, 16/popped_w, 16/popped_h)
              end
            else
              local flashed_w, flashed_h = imgs.flash:getDimensions()
              draw(imgs.flash, draw_x, draw_y, 0, 16/flashed_w, 16/flashed_h)
            end
          end
          --this adds the drawing of state flags to garbage panels
          if config.debug_mode then
            gprint(panel.state, draw_x*3, draw_y*3)
            if panel.match_anyway ~= nil then
              gprint(tostring(panel.match_anyway), draw_x*3, draw_y*3+10)
              if panel.debug_tag then
                gprint(tostring(panel.debug_tag), draw_x*3, draw_y*3+20)
              end
            end
            gprint(panel.chaining and "chaining" or "nah", draw_x*3, draw_y*3+30)
          end
        else
          if panel.state == "matched" then
            local flash_time = self.FRAMECOUNT_MATCH - panel.timer
            if flash_time >= self.FRAMECOUNT_FLASH then
              draw_frame = 6
            elseif flash_time % 2 == 1 then
              draw_frame = 1
            else
              draw_frame = 5
            end
          elseif panel.state == "popping" then
            draw_frame = 6
          elseif panel.state == "landing" then
            draw_frame = bounce_table[panel.timer + 1]
          elseif panel.state == "swapping" then
            if panel.is_swapping_from_left then
              draw_x = draw_x - panel.timer * 4
            else
              draw_x = draw_x + panel.timer * 4
            end
          elseif panel.state == "dimmed" then
            draw_frame = 7
          elseif panel.fell_from_garbage then
            draw_frame = garbage_bounce_table[panel.fell_from_garbage] or 1
          elseif self.danger_col[col] then
            draw_frame = danger_bounce_table[
              wrap(1,self.danger_timer+1+floor((col-1)/2),#danger_bounce_table)]
          else
            draw_frame = 1
          end
          local panel_w, panel_h = IMG_panels[panel.color][draw_frame]:getDimensions()
          draw(IMG_panels[panel.color][draw_frame], draw_x, draw_y, 0, 16/panel_w, 16/panel_h)
          if config.debug_mode then
            gprint(panel.state, draw_x*3, draw_y*3)
            if panel.match_anyway ~= nil then
              gprint(tostring(panel.match_anyway), draw_x*3, draw_y*3+10)
              if panel.debug_tag then
                gprint(tostring(panel.debug_tag), draw_x*3, draw_y*3+20)
              end
            end
            gprint(panel.chaining and "chaining" or "nah", draw_x*3, draw_y*3+30)
          end
        end
      end
      if config.debug_mode and mx >= draw_x and mx < draw_x + 16 and
          my >= draw_y and my < draw_y + 16 then
        mouse_panel = {row, col, panel}
        draw(IMG_panels[4][1], draw_x+16/3, draw_y+16/3, 0, 0.33333333, 0.3333333)
      end
    end
  end
  draw(IMG_frame, self.pos_x-4, self.pos_y-4)
  draw(IMG_wall, self.pos_x, self.pos_y - shake + self.height*16)
  if self.mode == "puzzle" then
    gprint("Moves: "..self.puzzle_moves, self.score_x, 100)
    gprint("Frame: "..self.CLOCK, self.score_x, 130)
  else
    gprint("Score: "..self.score, self.score_x, 100)
    gprint("Speed: "..self.speed, self.score_x, 130)
    gprint("Frame: "..self.CLOCK, self.score_x, 145)
    if self.mode == "time" then
      local time_left = 120 - (self.game_stopwatch or 120)/60
      local mins = math.floor(time_left/60)
      local secs = math.ceil(time_left% 60)
      if secs == 60 then
        secs = 0
        mins = mins+1
      end
      gprint("Time: "..string.format("%01d:%02d",mins,secs), self.score_x, 160)
    elseif self.level then
      gprint("Level: "..self.level, self.score_x, 160)
    end
    gprint("Health: "..self.health, self.score_x, 175)
    gprint("Shake: "..self.shake_time, self.score_x, 190)
    gprint("Stop: "..self.stop_time, self.score_x, 205)
    gprint("Pre stop: "..self.pre_stop_time, self.score_x, 220)
    if config.debug_mode and self.danger then gprint("danger", self.score_x,235) end
    if config.debug_mode and self.danger_music then gprint("danger music", self.score_x, 250) end
    if config.debug_mode then
      gprint("cleared: "..(self.panels_cleared or 0), self.score_x, 265)
    end
    if config.debug_mode then
      gprint("metal q: "..(self.metal_panels_queued or 0), self.score_x, 280)
    end
    if config.debug_mode and self.input_state then
      -- print(self.input_state)
      -- print(base64decode[self.input_state])
      local iraise, iswap, iup, idown, ileft, iright = unpack(base64decode[self.input_state])
      -- print(tostring(raise))
      local inputs_to_print = "inputs:"
      if iraise then inputs_to_print = inputs_to_print.."\nraise" end --◄▲▼►
      if iswap then inputs_to_print = inputs_to_print.."\nswap" end
      if iup then inputs_to_print = inputs_to_print.."\nup" end
      if idown then inputs_to_print = inputs_to_print.."\ndown" end
      if ileft then inputs_to_print = inputs_to_print.."\nleft" end
      if iright then inputs_to_print = inputs_to_print.."\nright" end
      gprint(inputs_to_print, self.score_x, 295)
    end
    if match_type then gprint(match_type, 375, 10) end
    if P1 and P1.game_stopwatch and tonumber(P1.game_stopwatch) then
      gprint(frames_to_time_string(P1.game_stopwatch, P1.mode == "endless"), 385, 25)
    end
    if not config.debug_mode then
      gprint(join_community_msg or "", 330, 560)
    end
  end
  self:draw_cards()
  self:render_cursor()
  if self.do_countdown then
    self:render_countdown()
  end
  --print("Rendered stack "..self.which.." in "..round(love.timer.getTime()-render_start_time, 6))
end

function scale_letterbox(width, height, w_ratio, h_ratio)
  if height / h_ratio > width / w_ratio then
    local scaled_height = h_ratio * width / w_ratio
    return 0, (height - scaled_height) / 2, width, scaled_height
  end
  local scaled_width = w_ratio * height / h_ratio
  return (width - scaled_width) / 2, 0, scaled_width, height
end

function Stack.render_cursor(self)
  local shake_idx = #shake_arr - self.shake_time
  local shake = ceil((shake_arr[shake_idx] or 0) * 13)
  if self.countdown_timer then
    if self.CLOCK % 2 == 0 then
      draw(IMG_cursor[1],
        (self.cur_col-1)*16+self.pos_x-4,
        (11-(self.cur_row))*16+self.pos_y-4+self.displacement-shake)
    end
  else
    draw(IMG_cursor[(floor(self.CLOCK/16)%2)+1],
      (self.cur_col-1)*16+self.pos_x-4,
      (11-(self.cur_row))*16+self.pos_y-4+self.displacement-shake)
  end
end

function Stack.render_countdown(self)
  if self.do_countdown and self.countdown_CLOCK then
    local ready_x = self.pos_x + 12
    local initial_ready_y = self.pos_y
    local ready_y_drop_speed = 6
    local countdown_x = self.pos_x + 40
    local countdown_y = self.pos_y + 64
    if self.countdown_CLOCK <= 8 then
      local ready_y = initial_ready_y + (self.CLOCK - 1) * ready_y_drop_speed
      draw(IMG_ready, ready_x, ready_y)
      if self.countdown_CLOCK == 8 then
        self.ready_y = ready_y
      end
    elseif self.countdown_CLOCK >= 9 and self.countdown_timer and self.countdown_timer > 0 then
      if self.countdown_timer >= 100 then
        draw(IMG_ready, ready_x, self.ready_y or initial_ready_y + 8 * 6)
      end
      local IMG_number_to_draw = IMG_numbers[math.ceil(self.countdown_timer / 60)]
      if IMG_number_to_draw then
        draw(IMG_number_to_draw, countdown_x, countdown_y)
      end
    end
  end
end

