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
    img = love.image.newImageData("assets/"..default_assets_dir.."/"..path_and_name)
  end
  local ret = love.graphics.newImage(img)
  ret:setFilter("nearest","nearest")
  return ret
end

function setScissor(x, y, width, height)
  if x then
    gfx_q:push({love.graphics.setScissor, {x*GFX_SCALE, y*GFX_SCALE, width*GFX_SCALE, height*GFX_SCALE}})
  else
    gfx_q:push({love.graphics.setScissor, {}})
  end
end

function draw(img, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  gfx_q:push({love.graphics.draw, {img, x*GFX_SCALE, y*GFX_SCALE,
    rot, x_scale*GFX_SCALE, y_scale*GFX_SCALE}})
end


function drawQuad(img, quad, x, y, rot, x_scale,y_scale)
  rot = rot or 0
  x_scale = x_scale or 1
  y_scale = y_scale or 1
  gfx_q:push({love.graphics.draw, {img, quad, x*GFX_SCALE, y*GFX_SCALE,
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

function graphics_init()
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
  IMG_particles = {}
  particle_quads = {}
  
  texture = load_img("lakitu/particles.png")
  local w = texture:getWidth()
  local h = texture:getHeight()
  local char_particles = {}
    
  particle_quads[1] = love.graphics.newQuad(0, 0, 48, 48, 256, 256)
  particle_quads[2] = love.graphics.newQuad(48, 0, 48, 48, 256, 256)
  particle_quads[3] = love.graphics.newQuad(96, 0, 48, 48, 256, 256)
  particle_quads[4] = love.graphics.newQuad(144, 0, 48, 48, 256, 256)
  particle_quads[5] = love.graphics.newQuad(0, 48, 48, 48, 256, 256)
  particle_quads[6] = love.graphics.newQuad(48, 48, 48, 48, 256, 256)
  particle_quads[7] = love.graphics.newQuad(96, 48, 48, 48, 256, 256)
  particle_quads[8] = love.graphics.newQuad(144, 48, 48, 48, 256, 256)
  particle_quads[9] = love.graphics.newQuad(0, 96, 48, 48, 256, 256)
  particle_quads[10] = love.graphics.newQuad(48, 96, 48, 48, 256, 256)
  particle_quads[11] = love.graphics.newQuad(96, 96, 48, 48, 256, 256)
  particle_quads[12] = love.graphics.newQuad(144, 96, 48, 48, 256, 256)
  particle_quads[13] = particle_quads[12]
  particle_quads[14] = love.graphics.newQuad(0, 144, 48, 48, 256, 256)
  particle_quads[15] = particle_quads[14]
  particle_quads[16] = love.graphics.newQuad(48, 144, 48, 48, 256, 256)
  particle_quads[17] = particle_quads[16]
  particle_quads[18] = love.graphics.newQuad(96, 144, 48, 48, 256, 256)
  particle_quads[19] = particle_quads[18]
  particle_quads[20] = particle_quads[18]
  particle_quads[21] = love.graphics.newQuad(144, 144, 48, 48, 256, 256)
  particle_quads[22] = particle_quads[21]
  particle_quads[23] = particle_quads[21]
  particle_quads[24] = particle_quads[21]
  IMG_telegraph_garbage = {} --values will be accessed by IMG_telegraph_garbage[garbage_height][garbage_width]
  IMG_telegraph_attack = {}
  for _,v in ipairs(characters) do
    local imgs = {}
    IMG_garbage[v] = imgs
    for _,part in ipairs(g_parts) do
      imgs[part] = load_img(""..v.."/"..part..".png")
    end
    for h=1,14 do
      IMG_telegraph_garbage[h] = {}
      IMG_telegraph_garbage[h][6] = load_img("".."telegraph/"..h.."-tall.png")
    end
    for w=3,6 do
      IMG_telegraph_garbage[1][w] = load_img("".."telegraph/"..w.."-wide.png")
    end
    IMG_telegraph_attack[v] = load_img(""..v.."/attack.png")
    IMG_particles[v] = load_img(""..v.."/particles.png")
  end
  IMG_telegraph_metal = load_img("telegraph/6-wide-metal.png")

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
  setScissor(self.pos_x-100, self.pos_y-4, IMG_frame:getWidth()+300, IMG_frame:getHeight())
  local mx,my
  if config.debug_mode then
    mx,my = love.mouse.getPosition()
    mx = mx / GFX_SCALE
    my = my / GFX_SCALE
  end
  if P1 == self then
    draw(IMG_garbage[self.character].portrait, self.pos_x, self.pos_y)
  else
    draw(IMG_garbage[self.character].portrait, self.pos_x+96, self.pos_y, 0, -1)
  end
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
              draw(IMG_metal_l, draw_x, draw_y)
              draw(IMG_metal_r, draw_x+16*(panel.width-1)+8,draw_y)
              for i=1,2*(panel.width-1) do
                draw(IMG_metal, draw_x+8*i, draw_y)
              end
            else
              local height, width = panel.height, panel.width
              local top_y = draw_y - (height-1) * 16
              local use_1 = ((height-(height%2))/2)%2==0
              for i=0,height-1 do
                for j=1,width-1 do
                  draw((use_1 or height<3) and imgs.filler1 or
                    imgs.filler2, draw_x+16*j-8, top_y+16*i)
                  use_1 = not use_1
                end
              end
              if height%2==1 then
                draw(imgs.face, draw_x+8*(width-1), top_y+16*((height-1)/2))
              else
                draw(imgs.doubleface, draw_x+8*(width-1), top_y+16*((height-2)/2))
              end
              draw(imgs.left, draw_x, top_y, 0, 1, height*16)
              draw(imgs.right, draw_x+16*(width-1)+8, top_y, 0, 1, height*16)
              draw(imgs.top, draw_x, top_y, 0, width*16)
              draw(imgs.bot, draw_x, draw_y+14, 0, width*16)
              draw(imgs.topleft, draw_x, top_y)
              draw(imgs.topright, draw_x+16*width-8, top_y)
              draw(imgs.botleft, draw_x, draw_y+13)
              draw(imgs.botright, draw_x+16*width-8, draw_y+13)
            end
          end
          if panel.state == "matched" then
            local flash_time = panel.initial_time - panel.timer
            if flash_time >= self.FRAMECOUNT_FLASH then
              if panel.timer > panel.pop_time then
                if panel.metal then
                  draw(IMG_metal_l, draw_x, draw_y)
                  draw(IMG_metal_r, draw_x+8, draw_y)
                else
                  draw(imgs.pop, draw_x, draw_y)
                end
              elseif panel.y_offset == -1 then
                draw(IMG_panels[panel.color][
                    garbage_bounce_table[panel.timer] or 1], draw_x, draw_y)
              end
            elseif flash_time % 2 == 1 then
              if panel.metal then
                draw(IMG_metal_l, draw_x, draw_y)
                draw(IMG_metal_r, draw_x+8, draw_y)
              else
                draw(imgs.pop, draw_x, draw_y)
              end
            else
              draw(imgs.flash, draw_x, draw_y)
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
          elseif self.danger_col[col] then
            draw_frame = danger_bounce_table[
              wrap(1,self.danger_timer+1+floor((col-1)/2),#danger_bounce_table)]
          else
            draw_frame = 1
          end
          draw(IMG_panels[panel.color][draw_frame], draw_x, draw_y)
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
        print("setting mouse_panel")
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
  setScissor()
  --self:render_gfx()
  if self.do_countdown then
    self:render_countdown()
  end
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

function Stack.render_gfx(self)
  for key, gfx_item in pairs(self.gfx) do
    drawQuad(IMG_particles[self.character], particle_quads[gfx_item["age"]], gfx_item["x"], gfx_item["y"])
  end
end

function Stack.render_telegraph(self)
  local telegraph_to_render 
  
  --if self.foreign then
    --print("rendering foreign Player "..self.which.."'s self.garbage_target.telegraph")
    --telegraph_to_render = self.garbage_target.telegraph
  --else
    --if self.garbage_target == self then
      --print("rendering Player "..self.which.."'s self.telegraph")
      telegraph_to_render = self.telegraph
    --else
      --print("rendering Player "..self.which.."'s self.incoming_telegraph")
      --telegraph_to_render = self.incoming_telegraph
      -- if self.which == 2 then
        -- print("\ntelegraph_stoppers: "..json.encode(telegraph_to_render.stoppers))
        -- print("telegraph garbage queue:")
        -- print(telegraph_to_render.garbage_queue:to_string())
        -- print("telegraph g_q chain in progress: "..tostring(true and telegraph_to_render.sender.chains.current))
      -- end
    --end
  --end
  -- print("\nrendering telegraph for player "..self.which)
  -- if self.which == 1 then 
    -- print(telegraph_to_render.garbage_queue:to_string())
  -- end
  local render_x = telegraph_to_render.pos_x
  for frame_earned, attacks_this_frame in pairs(telegraph_to_render.attacks) do
    -- print("frame_earned:")
    -- print(frame_earned)
    -- print(#card_animation)
    -- print(self.CLOCK)
    -- print(GARBAGE_TRANSIT_TIME)
    local frames_since_earned = self.CLOCK - frame_earned
    if frames_since_earned >= #card_animation and frames_since_earned <= GARBAGE_TRANSIT_TIME then
      if frames_since_earned <= #card_animation then
        --don't draw anything yet
      elseif frames_since_earned < #card_animation + #telegraph_attack_animation_speed then
        for _, attack in ipairs(attacks_this_frame) do
          for _k, garbage_block in ipairs(attack.stuff_to_send) do
            if not garbage_block.destination_x then 
              print("ZZZZZZZ")
              garbage_block.destination_x = telegraph_to_render.pos_x + TELEGRAPH_BLOCK_WIDTH * telegraph_to_render.garbage_queue:get_idx_of_garbage(unpack(garbage_block))
            end
            if not garbage_block.x or not garbage_block.y then
              garbage_block.x = (attack.origin_col-1) * 16 +telegraph_to_render.sender.pos_x
              garbage_block.y = (11-attack.origin_row) * 16 + telegraph_to_render.sender.pos_y + telegraph_to_render.sender.displacement - card_animation[#card_animation]
              garbage_block.origin_x = garbage_block.x
              garbage_block.origin_y = garbage_block.y
              garbage_block.direction = garbage_block.direction or sign(garbage_block.destination_x - garbage_block.origin_x) --should give -1 for left, or 1 for right
              
              for frame=1, frames_since_earned - #card_animation do
                print("YYYYYYYYYYYY")
                garbage_block.x = garbage_block.x + telegraph_attack_animation[garbage_block.direction][frame].dx
                garbage_block.y = garbage_block.y + telegraph_attack_animation[garbage_block.direction][frame].dy
              end
            else
              garbage_block.x = garbage_block.x + telegraph_attack_animation[garbage_block.direction][frames_since_earned-#card_animation].dx
              garbage_block.y = garbage_block.y + telegraph_attack_animation[garbage_block.direction][frames_since_earned-#card_animation].dy
            end
            --print("DRAWING******")
            --print(garbage_block.x..","..garbage_block.y)
            draw(IMG_telegraph_attack[telegraph_to_render.sender.character], garbage_block.x, garbage_block.y)
          end
        end
      elseif frames_since_earned >= #card_animation + #telegraph_attack_animation_speed and frames_since_earned < GARBAGE_TRANSIT_TIME - 1 then 
        --move toward destination
        for _, attack in ipairs(attacks_this_frame) do
          for _k, garbage_block in ipairs(attack.stuff_to_send) do
            --update destination
            --garbage_block.frame_earned = frame_earned --this will be handy when we want to draw the telegraph garbage blocks
            garbage_block.destination_x = render_x + TELEGRAPH_BLOCK_WIDTH * telegraph_to_render.garbage_queue:get_idx_of_garbage(unpack(garbage_block))
            garbage_block.destination_y = garbage_block.destination_y or telegraph_to_render.pos_y - TELEGRAPH_HEIGHT - TELEGRAPH_PADDING 
            
            if not garbage_block.x or not garbage_block.y then
              garbage_block.x = (attack.origin_col-1) * 16 +telegraph_to_render.sender.pos_x
              garbage_block.y = (11-attack.origin_row) * 16 + telegraph_to_render.sender.pos_y + telegraph_to_render.sender.displacement - card_animation[#card_animation]
              garbage_block.origin_x = garbage_block.x
              garbage_block.origin_y = garbage_block.y
              garbage_block.direction = garbage_block.direction or sign(garbage_block.destination_x - garbage_block.origin_x) --should give -1 for left, or 1 for right
              
              for frame=1, bound(1, frames_since_earned - #card_animation, #telegraph_attack_animation[garbage_block.direction]) do
                print("YYYYYYYYYYYY")
                garbage_block.x = garbage_block.x + telegraph_attack_animation[garbage_block.direction][frame].dx
                garbage_block.y = garbage_block.y + telegraph_attack_animation[garbage_block.direction][frame].dy
              end
            end
            
            local distance_to_destination = math.sqrt(math.pow(garbage_block.x-garbage_block.destination_x,2)+math.pow(garbage_block.y-garbage_block.destination_y,2))
            if frames_since_earned == #card_animation + #telegraph_attack_animation_speed then
              garbage_block.speed = distance_to_destination / (GARBAGE_TRANSIT_TIME-frames_since_earned)
            end

            if distance_to_destination <= (garbage_block.speed or TELEGRAPH_ATTACK_MAX_SPEED) then
              --just move it to it's destination
              garbage_block.x, garbage_block.y = garbage_block.destination_x, garbage_block.destination_y
            else
              garbage_block.x = garbage_block.x - ((garbage_block.speed or TELEGRAPH_ATTACK_MAX_SPEED)*(garbage_block.x-garbage_block.destination_x))/distance_to_destination
              garbage_block.y = garbage_block.y - ((garbage_block.speed or TELEGRAPH_ATTACK_MAX_SPEED)*(garbage_block.y-garbage_block.destination_y))/distance_to_destination
            end
            if self.which == 1 then
              print("rendering P1's telegraph's attack animation")
            end
            draw(IMG_telegraph_attack[telegraph_to_render.sender.character], garbage_block.x, garbage_block.y)
          end
        end
      elseif frames_since_earned == GARBAGE_TRANSIT_TIME then
        for _, attack in ipairs(attacks_this_frame) do
          for _k, garbage_block in ipairs(attack.stuff_to_send) do
            local last_chain_in_queue = telegraph_to_render.garbage_queue.chain_garbage[telegraph_to_render.garbage_queue.chain_garbage.last]
            if garbage_block[4]--[[from_chain]] and last_chain_in_queue and garbage_block[2]--[[height]] == last_chain_in_queue[2]--[[height]] then
              print("setting ghost_chain")
              telegraph_to_render.garbage_queue.ghost_chain = garbage_block[2]--[[height]]
            end
              --draw(IMG_telegraph_attack[self.character], garbage_block.desination_x, garbage_block.destination_y)
          end
        end
      end
    end
    --then draw the telegraph's garbage queue, leaving an empty space until such a time as the attack arrives (earned_frame-GARBAGE_TRANSIT_TIME)
    -- print("BBBBBB")
    -- print("telegraph_to_render.garbage_queue.ghost_chain: "..(telegraph_to_render.garbage_queue.ghost_chain or "nil"))
    local g_queue_to_draw = telegraph_to_render.garbage_queue:mkcpy()
    -- print("g_queue_to_draw.ghost_chain: "..(g_queue_to_draw.ghost_chain or "nil"))
    local current_block = g_queue_to_draw:pop()
    local draw_x = telegraph_to_render.pos_x
    local draw_y = telegraph_to_render.pos_y
    if telegraph_to_render.garbage_queue.ghost_chain then
      draw(IMG_telegraph_garbage[telegraph_to_render.garbage_queue.ghost_chain][6], draw_x, draw_y)
    end
    while current_block do
      --TODO: create a way to draw telegraphs from right to left
      if self.CLOCK - current_block.frame_earned >= GARBAGE_TRANSIT_TIME then
        if not current_block[3]--[[is_metal]] then
          draw(IMG_telegraph_garbage[current_block[2]--[[height]]][current_block[1]--[[width]]], draw_x, draw_y)
        else
          draw(IMG_telegraph_metal, draw_x, draw_y)
        end
      end
      draw_x = draw_x + TELEGRAPH_BLOCK_WIDTH
      current_block = g_queue_to_draw:pop()
    end
  end

end


--[[void FadingPanels_1P(int draw_frame, int lightness)
  int col, row, panel;
  int drawpanel, draw_x, draw_y;

  for(row=0;row<12;row++)
  {
    panel=row<<3;
    for(col=0;col<6;col++)
    {
      drawpanel=P1StackPanels[panel];
      if(drawpanel)
      {
        draw_x=self.pos_x+(col<<4);
        draw_y=self.pos_y+self.displacement+(row<<4);
        GrabRegion(draw_frame<<4,0,draw_frame<<4+15,15,draw_x,draw_y,
          Graphics_Panels[drawpanel],screen);
        if(lightness~=100)
        {
          SetLucent(lightness);
          RectFill(draw_x,draw_y,draw_x+15,draw_y+15,0,screen);
          SetLucent(0);
        }
      }
      panel++;
    }
  }
}--]]


--[[
void Render_Info_1P()
{
  int col, something, draw_x;
  if(GameTimeRender)
  {
    GameTimeRender=0;
    something=GameTime;
    GameTimeDigits[0]=something/36000;
    something=something%36000;
    GameTimeDigits[1]=something/3600;
    something=something%3600;

    GameTimeDigits[2]=something/600;
    something=something%600;
    GameTimeDigits[3]=something/60;
    something=something%60;

    GameTimeDigits[4]=10;
    GameTimeDigits[5]=something/10;
    GameTimeDigits[6]=something%10;

    RectFill(0,0,64,16,rgb(255,0,255),GameTimeDisplay);

    if(GameTimeDigits[0]) draw_x=0;
    else draw_x=0-8;
    something=0;
    for(col=0;col<2;col++)
    {  if(GameTimeDigits[col])
      {  GrabRegion(GameTimeDigits[col]<<3,0,(GameTimeDigits[col]<<3)+7,15,draw_x,0,Font_NumRed,GameTimeDisplay);
        something=1;
      }
      else
      {  if(something) GrabRegion(GameTimeDigits[col]<<3,0,(GameTimeDigits[col]<<3)+7,15,draw_x,0,Font_NumRed,GameTimeDisplay);
      }
      draw_x+=8;
    }
    if(something) GrabRegion(80,0,87,15,draw_x,0,Font_NumRed,GameTimeDisplay);
    draw_x+=8;
    if(something || GameTimeDigits[2])
      GrabRegion(GameTimeDigits[2]<<3,0,(GameTimeDigits[2]<<3)+7,15,draw_x,0,Font_NumRed,GameTimeDisplay);
    draw_x+=8;
    for(col=3;col<7;col++)
    {  GrabRegion(GameTimeDigits[col]<<3,0,(GameTimeDigits[col]<<3)+7,15,draw_x,0,Font_NumRed,GameTimeDisplay);
      draw_x+=8;
    }
  }

  TBlit(48,39,GameTimeDisplay,screen);



  if(P1ScoreRender)
  {
    P1ScoreRender=0;
    something=P1Score;
    P1ScoreDigits[0]=something/10000;
    something=something%10000;
    P1ScoreDigits[1]=something/1000;
    something=something%1000;
    P1ScoreDigits[2]=something/100;
    something=something%100;
    P1ScoreDigits[3]=something/10;
    P1ScoreDigits[4]=something%10;

    RectFill(0,0,40,16,rgb(255,0,255),P1ScoreDisplay);
    draw_x=0;
    something=0;
    for(col=0;col<4;col++)
    {
      if(P1ScoreDigits[col])
      {
        GrabRegion(P1ScoreDigits[col]<<3,0,(P1ScoreDigits[col]<<3)+7,15,draw_x,0,Font_NumBlue,P1ScoreDisplay);
        something=1;
      }
      else
      {
        if(something) GrabRegion(P1ScoreDigits[col]<<3,0,(P1ScoreDigits[col]<<3)+7,15,draw_x,0,Font_NumBlue,P1ScoreDisplay);
      }
      draw_x+=8;
    }
    col=4;
    GrabRegion(P1ScoreDigits[col]<<3,0,(P1ScoreDigits[col]<<3)+7,15,draw_x,0,Font_NumBlue,P1ScoreDisplay);
  }

  TBlit(232,63,P1ScoreDisplay,screen);


  if(P1StopTime)
  {
    MrStopTimer--;
    if(MrStopTimer<=0)
    {
      MrStopTimer=MrStopAni[P1StopTime];
      if(MrStopState) MrStopState=0;
      else MrStopState=1;
      P1SpeedLVRender=1;
    }
  }
  if(P1SpeedLVRender)
  {
    RectFill(0,0,48,48,rgb(255,0,255),P1SpeedLVDisplay);
    if(P1StopTime)
    {
      Blit(0,0,Graphics_MrStop[MrStopState],P1SpeedLVDisplay);
      if(MrStopState)
      {
        P1SpeedLVDigits[0]=P1StopTime/10;
        P1SpeedLVDigits[1]=P1StopTime%10;
        GrabRegion(P1SpeedLVDigits[0]<<3,0,(P1SpeedLVDigits[0]<<3)+7,15, 0,0,Font_NumRed,P1SpeedLVDisplay);
        GrabRegion(P1SpeedLVDigits[1]<<3,0,(P1SpeedLVDigits[1]<<3)+7,15, 8,0,Font_NumRed,P1SpeedLVDisplay);
      }
    }
    else
    {
      P1SpeedLVDigits[0]=P1SpeedLV/10;
      P1SpeedLVDigits[1]=P1SpeedLV%10;
      if(P1SpeedLVDigits[0]) GrabRegion(P1SpeedLVDigits[0]<<3,0,(P1SpeedLVDigits[0]<<3)+7,15, 32,2,Font_NumBlue,P1SpeedLVDisplay);
      GrabRegion(P1SpeedLVDigits[1]<<3,0,(P1SpeedLVDigits[1]<<3)+7,15, 40,2,Font_NumBlue,P1SpeedLVDisplay);
      Blit(1,25,Graphics_level,P1SpeedLVDisplay);
      Blit(1,35,Graphics_Difficulty[P1DifficultyLV],P1SpeedLVDisplay);
    }
  }

  TBlit(224,95,P1SpeedLVDisplay,screen);
}--]]

