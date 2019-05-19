function main_options(starting_idx)
	local items, active_idx = {}, starting_idx or 1
	local k = K[1]
	local selected, deselected_this_frame, adjust_active_value = false, false, false
	local function get_items()
	local save_replays_publicly_choices = {"with my name", "anonymously", "not at all"}
	assets_dir_before_options_menu = config.assets_dir or default_assets_dir
	sounds_dir_before_options_menu = config.sounds_dir or default_sounds_dir
	--make so we can get "anonymously" from save_replays_publicly_choices["anonymously"]
	for k,v in ipairs(save_replays_publicly_choices) do
		save_replays_publicly_choices[v] = v
	end
	local raw_assets_dir_list = love.filesystem.getDirectoryItems("assets")
	local asset_sets = {}
	for k,v in ipairs(raw_assets_dir_list) do
		if love.filesystem.getInfo("assets/"..v) and v ~= "Example folder structure" then
			asset_sets[#asset_sets+1] = v
		end
	end
	local raw_sounds_dir_list = love.filesystem.getDirectoryItems("sounds")
	local sound_sets = {}
	for k,v in ipairs(raw_sounds_dir_list) do
		if love.filesystem.getInfo("sounds/"..v) and v ~= "Example folder structure" then
			sound_sets[#sound_sets+1] = v
		end
	end
	print("asset_sets:")
	for k,v in ipairs(asset_sets) do
		print(v)
	end
		items = {
		--options menu table reference:
		--{[1]"Option Name", [2]current or default value, [3]type, [4]min or bool value or choices_table,
		-- [5]max, [6]sound_source, [7]selectable, [8]next_func, [9]play_while selected}
			{"Master Volume", config.master_volume or 100, "numeric", 0, 100, sounds.music.characters["yoshi"].normal_music, true, nil, true},
			{"SFX Volume", config.SFX_volume or 100, "numeric", 0, 100, sounds.SFX.cur_move, true},
			{"Music Volume", config.music_volume or 100, "numeric", 0, 100, sounds.music.characters["yoshi"].normal_music, true, nil, true},
			{"Debug Mode", debug_mode_text[config.debug_mode or false], "bool", false, nil, nil,false},
			{"Save replays publicly",
				save_replays_publicly_choices[config.save_replays_publicly]
					or save_replays_publicly_choices["with my name"],
				"multiple choice", save_replays_publicly_choices},
			{"Graphics set", config.assets_dir or default_assets_dir, "multiple choice", asset_sets},
			{"Sounds set", config.sounds_dir or default_sounds_dir, "multiple choice", sound_sets},
			{"Ready countdown", ready_countdown_1P_text[config.ready_countdown_1P or false], "bool", true, nil, nil,false},
			{"Back", "", nil, nil, nil, nil, false, main_select_mode}
		}
	end
	local function print_stuff()
		local to_print, to_print2, arrow = "", "", ""
		for i=1,#items do
			if active_idx == i then
				arrow = arrow .. ">"
			else
				arrow = arrow .. "\n"
			end
			to_print = to_print .. "   " .. items[i][1] .. "\n"
			to_print2 = to_print2 .. "                  "
			if active_idx == i and selected then
				to_print2 = to_print2 .. "                < "
			else
				to_print2 = to_print2 .. "                  "
			end
			to_print2 = to_print2.. items[i][2]
			if active_idx == i and selected then
				to_print2 = to_print2 .. " >"
			end
			to_print2 = to_print2 .. "\n"
		end
		gprint(arrow, 300, 280)
		gprint(to_print, 300, 280)
		gprint(to_print2, 300, 280)
	end
	local function adjust_left()
		if items[active_idx][3] == "numeric" then
			if items[active_idx][2] > items[active_idx][4] then --value > minimum
				items[active_idx][2] = items[active_idx][2] - 1
			end
		elseif items[active_idx][3] == "multiple choice" then
			adjust_backwards = true
			adjust_active_value = true
		end
		--the following is enough for "bool"
		adjust_active_value = true
		if items[active_idx][6] and not items[active_idx][9] then
		--sound_source for this menu item exists and not play_while_selected
			items[active_idx][6]:stop()
			items[active_idx][6]:play()
		end
	end
	local function adjust_right()
		if items[active_idx][3] == "numeric" then
			if items[active_idx][2] < items[active_idx][5] then --value < maximum
				items[active_idx][2] = items[active_idx][2] + 1
			end
		elseif items[active_idx][3] == "multiple choice" then
			adjust_active_value = true
		end
		--the following is enough for "bool"
		adjust_active_value = true
		if items[active_idx][6] and not items[active_idx][9] then
		--sound_source for this menu item exists and not play_while_selected
			items[active_idx][6]:stop()
			items[active_idx][6]:play()
		end
	end
	get_items()
	local do_menu_function = false
	while true do
		--get_items()
		print_stuff()
		coroutine.yield()
		local ret = nil
		variable_step(function()
			if menu_up(K[1]) and not selected then
				active_idx = wrap(1, active_idx-1, #items)
			elseif menu_down(K[1]) and not selected then
				active_idx = wrap(1, active_idx+1, #items)
			elseif menu_left(K[1]) and (selected or not items[active_idx][7]) then --or not selectable
				adjust_left()
			elseif menu_right(K[1]) and (selected or not items[active_idx][7]) then --or not selectable
				adjust_right()
			elseif menu_enter(K[1]) then
				if items[active_idx][7] then --is selectable
					selected = not selected
					if not selected then
						deselected_this_frame = true
						adjust_active_value = true
					end
				elseif items[active_idx][3] == "bool" or items[active_idx][3] == "multiple choice" then
					adjust_active_value = true
				elseif items[active_idx][3] == "function" then
					do_menu_function = true
				elseif active_idx == #items then
					ret = {exit_options_menu}
				end
			elseif menu_escape(K[1]) then
				if selected then
					selected = not selected
					deselected_this_frame = true
				elseif active_idx == #items then
					ret = {exit_options_menu}
				else
					active_idx = #items
				end
			end
			if adjust_active_value and not ret then
				if items[active_idx][3] == "bool" then
					if active_idx == 4 then
						config.debug_mode = not config.debug_mode
						items[active_idx][2] = debug_mode_text[config.debug_mode or false]
					end
					if items[active_idx][1] == "Ready countdown" then
						config.ready_countdown_1P = not config.ready_countdown_1P
						items[active_idx][2] = ready_countdown_1P_text[config.ready_countdown_1P]
					end
					--add any other bool config updates here
				elseif items[active_idx][3] == "numeric" then
					if config.master_volume ~= items[1][2] then
						config.master_volume = items[1][2]
						love.audio.setVolume(config.master_volume/100)
					end
					if config.SFX_volume ~= items[2][2] then --SFX volume should be updated
						config.SFX_volume = items[2][2]
						items[2][6]:setVolume(config.SFX_volume/100) --do just the one sound effect until we deselect
					end
					if active_idx == 2 and deselected_this_frame then --SFX Volume
						set_volume(sounds.SFX, config.SFX_volume/100)
					end
					if config.music_volume ~= items[3][2] then --music volume should be updated
						config.music_volume = items[3][2]
						items[3][6]:setVolume(config.music_volume/100) --do just the one music source until we deselect
					end
					if active_idx == 3 and deselected_this_frame then --Music Volume
						set_volume(sounds.music, config.music_volume/100)
					end
					--add any other numeric config updates here
				elseif items[active_idx][3] == "multiple choice" then
					local active_choice_num = 1
					--find the key for the currently selected choice
					for k,v in ipairs(items[active_idx][4]) do
						if v == items[active_idx][2] then
							active_choice_num = k
						end
					end
					-- the next line of code means
					-- current_choice_num = choices[wrap(1, next_choice_num, last_choice_num)]
					if adjust_backwards then
						items[active_idx][2] = items[active_idx][4][wrap(1,active_choice_num - 1, #items[active_idx][4])]
						adjust_backwards = nil
					else
						items[active_idx][2] = items[active_idx][4][wrap(1,active_choice_num + 1, #items[active_idx][4])]
					end
					if active_idx == 5 then
						config.save_replays_publicly = items[active_idx][2]
					elseif active_idx == 6 then
						config.assets_dir = items[active_idx][2]
					elseif active_idx == 8 then
						config.sounds_dir = items[active_idx][2]
					end
					--add any other multiple choice config updates here
				end
				adjust_active_value = false
			end
			if items[active_idx][3] == "function" and do_menu_function and not ret then
				ret = {items[active_idx][8], {active_idx}}
			end
			if not ret and selected and items[active_idx][9] and items[active_idx][6] and not items[active_idx][6]:isPlaying() then
			--if selected and play_while_selected and sound source exists and it isn't playing
				items[active_idx][6]:play()
			end
			if not ret and deselected_this_frame then
				if items[active_idx][6] then --sound_source for this menu item exists
					items[active_idx][6]:stop()
					love.audio.stop()
					stop_the_music()
				end
				deselected_this_frame = false
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end

function exit_options_menu()
	gprint("writing config to file...", 300,280)
	coroutine.yield()
	write_conf_file()
	if config.assets_dir ~= assets_dir_before_options_menu then
		gprint("reloading graphics...", 300, 305)
		coroutine.yield()
		graphics_init()
	end
	assets_dir_before_options_menu = nil
	if config.sounds_dir ~= sounds_dir_before_options_menu then
		gprint("reloading sounds...", 300, 305)
		coroutine.yield()
		sound_init()
	end
	sounds_dir_before_options_menu = nil
	return main_select_mode
end


function main_config_input()
	local pretty_names = {"Up", "Down", "Left", "Right", "A", "B", "L", "R"}
	local items, active_idx = {}, 1
	local k = K[1]
	local active_player = 1
	local function get_items()
		items = {[0]={"Player ", ""..active_player}}
		for i=1,#key_names do
			items[#items+1] = {pretty_names[i], k[key_names[i]] or "none"}
		end
		items[#items+1] = {"Set all keys", ""}
		items[#items+1] = {"Back", "", main_select_mode}
	end
	local function print_stuff()
		local to_print, to_print2, arrow = "", "", ""
		for i=0,#items do
			if active_idx == i then
				arrow = arrow .. ">"
			else
				arrow = arrow .. "\n"
			end
			to_print = to_print .. "   " .. items[i][1] .. "\n"
			to_print2 = to_print2 .. "                  " .. items[i][2] .. "\n"
		end
		gprint(arrow, 300, 280)
		gprint(to_print, 300, 280)
		gprint(to_print2, 300, 280)
	end
	local idxs_to_set = {}
	while true do
		get_items()
		if #idxs_to_set > 0 then
			items[idxs_to_set[1]][2] = "___"
		end
		print_stuff()
		coroutine.yield()
		local ret = nil
		variable_step(function()
			if #idxs_to_set > 0 then
				local idx = idxs_to_set[1]
				for key,val in pairs(this_frame_keys) do
					if val then
						k[key_names[idx]] = key
						table.remove(idxs_to_set, 1)
						if #idxs_to_set == 0 then
							write_key_file()
						end
					end
				end
			elseif menu_up(K[1]) then
				active_idx = wrap(1, active_idx-1, #items)
			elseif menu_down(K[1]) then
				active_idx = wrap(1, active_idx+1, #items)
			elseif menu_left(K[1]) then
				active_player = wrap(1, active_player-1, 2)
				k=K[active_player]
			elseif menu_right(K[1]) then
				active_player = wrap(1, active_player+1, 2)
				k=K[active_player]
			elseif menu_enter(K[1]) then
				if active_idx <= #key_names then
					idxs_to_set = {active_idx}
				elseif active_idx == #key_names + 1 then
					idxs_to_set = {1,2,3,4,5,6,7,8}
				else
					ret = {items[active_idx][3], items[active_idx][4]}
				end
			elseif menu_escape(K[1]) then
				if active_idx == #items then
					ret = {items[active_idx][3], items[active_idx][4]}
				else
					active_idx = #items
				end
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end

function main_set_name()
	local name = config.name or ""
	while true do
		local to_print = "Enter your name:\n"..name
		if (love.timer.getTime()*3) % 2 > 1 then
				to_print = to_print .. "|"
		end
		gprint(to_print, 300, 280)
		coroutine.yield()
		local ret = nil
		variable_step(function()
			if this_frame_keys["escape"] then
				ret = {main_select_mode}
			end
			if this_frame_keys["return"] or this_frame_keys["kenter"] then
				config.name = name
				write_conf_file()
				ret = {main_select_mode}
			end
			if menu_backspace(K[1]) then
				name = string.sub(name, 1, #name-1)
			end
			for _,v in ipairs(this_frame_unicodes) do
				name = name .. v
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end
