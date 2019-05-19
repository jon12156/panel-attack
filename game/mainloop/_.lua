
function fmainloop()
	local func, arg = main_select_mode, nil
	replay = {}
	config = {character="yoshi", level=5, name="defaultname", master_volume=100, SFX_volume=100, music_volume=100, debug_mode=false, ready_countdown_1P = true, save_replays_publicly = "with my name", assets_dir=default_assets_dir, sounds_dir=default_sounds_dir}
	gprint("Reading config file", 300, 280)
	coroutine.yield()
	read_conf_file() -- TODO: stop making new config files
	local x,y, display = love.window.getPosition()
	love.window.setPosition(
		config.window_x or x,
		config.window_y or y,
		config.display or display)
	--gprint("Copying Puzzles Readme")
	--coroutine.yield()
	--copy_file("Custom Puzzles Readme.txt", "puzzles/README.txt")
	gprint("Reading replay file", 300, 280)
	coroutine.yield()
	read_replay_file()
	gprint("Loading graphics...", 300, 280)
	coroutine.yield()
	graphics_init() -- load images and set up stuff
	gprint("Loading sounds... (this takes a few seconds)", 300, 280)
	coroutine.yield()
	sound_init()
	while true do
		leftover_time = 1/120
		consuming_timesteps = false
		func,arg = func(unpack(arg or {}))
		collectgarbage("collect")
	end
end

-- Wrapper for doing something at 60hz
-- The rest of the stuff happens at whatever rate is convenient
function variable_step(f)
	for i=1,4 do
		if leftover_time >= 1/60 then
			joystick_ax()
			f()
			key_counts()
			this_frame_keys = {}
			this_frame_unicodes = {}
			leftover_time = leftover_time - 1/60
		end
	end
end

-- Changes the behavior of menu_foo functions.
-- In a menu that doesn't specifically pertain to multiple players,
-- up, down, left, right should always work.  But in a multiplayer
-- menu, those keys should definitely not move many cursors each.
local multi = false
function multi_func(func)
	return function(...)
		multi = true
		local res = {func(...)}
		multi = false
		return unpack(res)
	end
end

-- Keys that have a fixed function in menus can be bound to other
-- meanings, but should continue working the same way in menus.
local menu_reserved_keys = {}

function repeating_key(key)
	local key_time = keys[key]
	return this_frame_keys[key] or
		(key_time and key_time > 25 and key_time % 3 ~= 0)
end

function normal_key(key) return this_frame_keys[key] end

function menu_key_func(fixed, configurable, rept)
	local query = normal_key
	if rept then
		query = repeating_key
	end
	for i=1,#fixed do
		menu_reserved_keys[#menu_reserved_keys+1] = fixed[i]
	end
	return function(k)
		local res = false
		if multi then
			for i=1,#configurable do
				res = res or query(k[configurable[i]])
			end
		else
			for i=1,#fixed do
				res = res or query(fixed[i])
			end
			for i=1,#configurable do
				local keyname = k[configurable[i]]
				res = res or query(keyname) and
						not menu_reserved_keys[keyname]
			end
		end
		return res
	end
end

menu_up = menu_key_func({"up"}, {"up"}, true)
menu_down = menu_key_func({"down"}, {"down"}, true)
menu_left = menu_key_func({"left"}, {"left"}, true)
menu_right = menu_key_func({"right"}, {"right"}, true)
menu_enter = menu_key_func({"return","kenter","z"}, {"swap1"}, false)
menu_escape = menu_key_func({"escape","x"}, {"swap2"}, false)
menu_backspace = menu_key_func({"backspace"}, {"backspace"}, true)


require "game.mainloop.main-menu"
require "game.mainloop.music-test"
require "game.mainloop.options"

require "game.mainloop.character-select"
require "game.mainloop.select-speed"
require "game.mainloop.endless"

require "game.mainloop.time-attack"

require "game.mainloop.local-vs-setup"
require "game.mainloop.local-vs"
require "game.mainloop.local-vs-yourself-setup"
require "game.mainloop.local-vs-yourself"

require "game.mainloop.net-vs-lobby"
require "game.mainloop.net-vs-setup"
require "game.mainloop.net-vs-room"
require "game.mainloop.net-vs"

require "game.mainloop.puzzle"

require "game.mainloop.replay-endless"
require "game.mainloop.replay-puzzle"
require "game.mainloop.replay-vs"


function update_win_counts(win_counts)
	if (P1 and P1.player_number == 1) or currently_spectating then
		my_win_count = win_counts[1] or 0
		op_win_count = win_counts[2] or 0
	elseif P1.player_number == 2 then
		my_win_count = win_counts[2] or 0
		op_win_count = win_counts[1] or 0
	end
end

function spectator_list_string(list)
	local str = ""
	for k,v in ipairs(list) do
		str = str..v
		if k<#list then
			str = str.."\n"
		end
	end
	if str ~= "" then
		str = "Spectator(s):\n"..str
	end
	return str
end

function fullscreen()
	if love.graphics.getSupported("canvas") then
		love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
	end
	return main_select_mode
end

function main_dumb_transition(next_func, text, timemin, timemax)
	if P1 and P1.character then
		stop_character_sounds(P1.character)
	end
	if P2 and P2.character then
		stop_character_sounds(P2.character)
	end
	love.audio.stop()
	stop_the_music()
	if not SFX_mute and SFX_GameOver_Play == 1 then
		sounds.SFX.game_over:play()
	end
	SFX_GameOver_Play = 0

	text = text or ""
	timemin = timemin or 0
	timemax = timemax or 3600
	local t = 0
	local k = K[1]
	while true do
		-- end
		gprint(text, 300, 280)
		coroutine.yield()
		local ret = nil
		variable_step(function()
			if t >= timemin and (t >=timemax or (menu_enter(k) or menu_escape(k))) then
				ret = {next_func}
			end
			t = t + 1
			if TCP_sock then
			--  do_messages()
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end

function write_char_sel_settings_to_file()
	if not currently_spectating and my_state then
		gprint("saving character select settings...")
		if not closing then
			coroutine.yield()
		end
		config.character = my_state.character
		config.level = my_state.level
		config.ranked = my_state.ranked
		write_conf_file()
	end
end

function love.quit()
	closing = true
	config.window_x, config.window_y, config.display = love.window.getPosition()
	write_conf_file()
	write_char_sel_settings_to_file()
end
