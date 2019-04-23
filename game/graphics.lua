require("game.input")
require("libs.util")

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
			..tostring(math.floor(i/10))..tostring(i%10)..".png")
	end
	for i=2,13 do
		IMG_cards[true][i] = load_img("chain"
			..tostring(math.floor(i/10))..tostring(i%10)..".png")
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

function scale_letterbox(width, height, w_ratio, h_ratio)
	if height / h_ratio > width / w_ratio then
		local scaled_height = h_ratio * width / w_ratio
		return 0, (height - scaled_height) / 2, width, scaled_height
	end
	local scaled_width = w_ratio * height / h_ratio
	return (width - scaled_width) / 2, 0, scaled_width, height
end
