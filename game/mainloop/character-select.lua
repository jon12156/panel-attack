function main_character_select()
	love.audio.stop()
	stop_the_music()
	local map = {}

	-- -------------------------------------------------------
	-- 2P Network VS
	-- -------------------------------------------------------

	if character_select_mode == "2p_net_vs" then
		local opponent_connected = false
		local retries, retry_limit = 0, 250
		while not global_initialize_room_msg and retries < retry_limit do
			for _,msg in ipairs(this_frame_messages) do
				if msg.create_room or msg.character_select or msg.spectate_request_granted then
					global_initialize_room_msg = msg
				end
			end
			gprint("Waiting for room initialization...", 300, 280)
			coroutine.yield()
			do_messages()
			retries = retries + 1
		end
		if not global_initialize_room_msg then
			return main_dumb_transition, {main_select_mode, "Failed to connect.\n\nReturning to main menu", 60, 300}
		end
		msg = global_initialize_room_msg
		global_initialize_room_msg = nil
		if msg.ratings then
				global_current_room_ratings = msg.ratings
		end
		global_my_state = msg.a_menu_state
		global_op_state = msg.b_menu_state
		if msg.your_player_number then
			my_player_number = msg.your_player_number
		elseif currently_spectating then
			my_player_number = 1
		elseif my_player_number and my_player_number ~= 0 then
			print("We assumed our player number is still "..my_player_number)
		else
			error("We never heard from the server as to what player number we are")
			print("Error: The server never told us our player number.  Assuming it is 1")
			my_player_number = 1
		end
		if msg.op_player_number then
			op_player_number = msg.op_player_number or op_player_number
		elseif currently_spectating then
			op_player_number = 2
		elseif op_player_number and op_player_number ~= 0 then
			print("We assumed op player number is still "..op_player_number)
		else
			error("We never heard from the server as to what player number we are")
			print("Error: The server never told us our player number.  Assuming it is 2")
			op_player_number = 2
		end
		if msg.win_counts then
			update_win_counts(msg.win_counts)
		end
		if msg.replay_of_match_so_far then
			replay_of_match_so_far = msg.replay_of_match_so_far
		end
		if msg.ranked then
			match_type = "Ranked"
			match_type_message = ""
		else
			match_type = "Casual"
		end
		if currently_spectating then
			P1 = {panel_buffer="", gpanel_buffer=""}
			print("we reset P1 buffers at start of main_character_select()")
		end
		P2 = {panel_buffer="", gpanel_buffer=""}
		print("we reset P2 buffers at start of main_character_select()")
		print("current_server_supports_ranking: "..tostring(current_server_supports_ranking))
		local cursor,op_cursor,X,Y
		if current_server_supports_ranking then
			map = {{"match type desired", "match type desired", "match type desired", "match type desired", "level", "level", "ready"},
						 {"random", "yoshi", "hookbill", "navalpiranha", "kamek", "bowser", "leave"}}
		else
			map = {{"level", "level", "level", "level", "level", "level", "ready"},
						 {"random", "windy", "sherbet", "thiana", "ruby", "lip", "elias"},
						 {"flare", "neris", "seren", "phoenix", "dragon", "thanatos", "cordelia"},
						 {"lakitu", "bumpty", "poochy", "wiggler", "froggy", "blargg", "lungefish"},
						 {"raphael", "yoshi", "hookbill", "navalpiranha", "kamek", "bowser", "leave"}}
		end
	end


	-- -------------------------------------------------------
	-- 1P Solo VS
	-- -------------------------------------------------------

	if character_select_mode == "1p_vs_yourself" then
		map = {{"level", "level", "level", "level", "level", "level", "ready"},
					 {"random", "windy", "sherbet", "thiana", "ruby", "lip", "elias"},
					 {"flare", "neris", "seren", "phoenix", "dragon", "thanatos", "cordelia"},
					 {"lakitu", "bumpty", "poochy", "wiggler", "froggy", "blargg", "lungefish"},
					 {"raphael", "yoshi", "hookbill", "navalpiranha", "kamek", "bowser", "leave"}}
	end


	-- -------------------------------------------------------
	-- what the fuck
	-- -------------------------------------------------------

	local op_state = global_op_state or {character="yoshi", level=5, cursor="level", ready=false}
	global_op_state = nil
	cursor,op_cursor,X,Y = {1,1},{1,1},5,7
	local k = K[1]
	local up,down,left,right = {-1,0}, {1,0}, {0,-1}, {0,1}
	my_state = global_my_state or {character=config.character, level=config.level, cursor="level", ready=false}
	global_my_state = nil
	my_win_count = my_win_count or 0
	local prev_state = shallowcpy(my_state)
	op_win_count = op_win_count or 0


	-- -------------------------------------------------------
	-- 2P Network VS again
	-- -------------------------------------------------------

	if character_select_mode == "2p_net_vs" then
		global_current_room_ratings = global_current_room_ratings or {{new=0,old=0,difference=0},{new=0,old=0,difference=0}}
		my_expected_win_ratio = nil
		op_expected_win_ratio = nil
		print("my_player_number = "..my_player_number)
		print("op_player_number = "..op_player_number)
		if global_current_room_ratings[my_player_number].new
		and global_current_room_ratings[my_player_number].new ~= 0
		and global_current_room_ratings[op_player_number]
		and global_current_room_ratings[op_player_number].new ~= 0 then
			my_expected_win_ratio = (100*round(1/(1+10^
						((global_current_room_ratings[op_player_number].new
								-global_current_room_ratings[my_player_number].new)
							/RATING_SPREAD_MODIFIER))
						,2))
			op_expected_win_ratio = (100*round(1/(1+10^
						((global_current_room_ratings[my_player_number].new
								-global_current_room_ratings[op_player_number].new)
							/RATING_SPREAD_MODIFIER))
						,2))
		end
	end

	-- -------------------------------------------------------
	-- WHAT IS HAPPENING WHY IS THIS A DIFFERENT BLOCK
	-- -------------------------------------------------------

	if character_select_mode == "2p_net_vs" then
		match_type = match_type or "Casual"
		if match_type == "" then match_type = "Casual" end
	end


	-- -------------------------------------------------------
	-- probably something for the character select menu
	-- -------------------------------------------------------

	match_type_message = match_type_message or ""
	local selected = false
	local active_str = "level"
	local selectable = {level=true, ready=true}
	local function move_cursor(direction)
		local dx,dy = unpack(direction)
		local can_x,can_y = wrap(1, cursor[1]+dx, X), wrap(1, cursor[2]+dy, Y)
		while can_x ~= cursor[1] or can_y ~= cursor[2] do
			if map[can_x][can_y] and map[can_x][can_y] ~= map[cursor[1]][cursor[2]] then
				break
			end
			can_x,can_y = wrap(1, can_x+dx, X), wrap(1, can_y+dy, Y)
		end
		cursor[1],cursor[2] = can_x,can_y
	end
	local function do_leave()
		my_win_count = 0
		op_win_count = 0
		write_char_sel_settings_to_file()
		return json_send({leave_room=true})
	end


	-- -------------------------------------------------------
	-- why
	-- -------------------------------------------------------

	local name_to_xy = {}
	print("character_select_mode = "..(character_select_mode or "nil"))
	print("map[1][1] = "..(map[1][1] or "nil"))

	for i=1,X do
		for j=1,Y do
			if map[i] and map[i][j] then
				name_to_xy[map[i][j]] = {i,j}
			end
		end
	end

	local function draw_button(x,y,w,h,str)
		local menu_width = Y*100
		local menu_height = X*80
		local spacing = 8
		local x_padding = math.floor((819-menu_width)/2)
		local y_padding = math.floor((612-menu_height)/2)
		set_color(unpack(colors.white))
		render_x = x_padding+(y-1)*100+spacing
		render_y = y_padding+(x-1)*100+spacing
		button_width = w*100-2*spacing
		button_height = h*100-2*spacing
		grectangle("line", render_x, render_y, button_width, button_height)
		if IMG_character_icons[str] then
			local orig_w, orig_h = IMG_character_icons[str]:getDimensions()
			menu_draw(IMG_character_icons[str], render_x, render_y, 0, button_width/orig_w, button_height/orig_h )
		end
		local y_add,x_add = 10,30
		local pstr = str:gsub("^%l", string.upper)

		-- why is this a button in here
		if str == "level" then
			if selected and active_str == "level" then
				pstr = my_name.."'s level: < "..my_state.level.." >"
			else
				pstr = my_name.."'s level: "..my_state.level
			end
			if character_select_mode == "2p_net_vs" then
				pstr = pstr .. "\n"..op_name.."'s level: "..op_state.level
			end
			y_add,x_add = 9,180
		end

		-- whY ARE YOU DOING THIS
		if str == "match type desired" then
			local my_type_selection, op_type_selection = "[casual]  ranked", "[casual]  ranked"
			if my_state.ranked then
				my_type_selection = " casual  [ranked]"
			end
			if op_state.ranked then
				op_type_selection = " casual  [ranked]"
			end
			pstr = my_name..": "..my_type_selection.."\n"..op_name..": "..op_type_selection
			y_add,x_add = 9,180
		end

		-- oh my god why are you comparing the cursor to the string of the button
		-- why
		-- aaaaag
		if my_state.cursor == str then pstr = pstr.."\n"..my_name end
		if op_state and op_name and op_state.cursor == str then pstr = pstr.."\n"..op_name end
		local cur_blink_frequency = 4
		local cur_pos_change_frequency = 8
		local player_num
		local draw_cur_this_frame = false
		local cursor_frame = 1

		-- -------------------------------------------------------
		-- special bullshit for 2P modes
		-- -------------------------------------------------------

		if (character_select_mode == "2p_net_vs" or character_select_mode == "2p_local_vs")
		and op_state and op_state.cursor and (op_state.cursor == str or op_state.cursor == str) then
			player_num = 2
			if op_state.ready then
				if (math.floor(menu_clock/cur_blink_frequency)+player_num)%2+1 == player_num then
					draw_cur_this_frame = true
					cursor_frame = 1
				else
					draw_cur_this_frame = false
				end
			else
				draw_cur_this_frame = true
				cursor_frame = (math.floor(menu_clock/cur_pos_change_frequency)+player_num)%2+1
				cur_img = IMG_char_sel_cursors[player_num][cursor_frame]
			end
			if draw_cur_this_frame then
				cur_img = IMG_char_sel_cursors[player_num][cursor_frame]
				cur_img_left = IMG_char_sel_cursor_halves.left[player_num][cursor_frame]
				cur_img_right = IMG_char_sel_cursor_halves.right[player_num][cursor_frame]
				local cur_img_w, cur_img_h = cur_img:getDimensions()
				local cursor_scale = (button_height+(spacing*2))/cur_img_h
				menu_drawq(cur_img, cur_img_left, render_x-spacing, render_y-spacing, 0, cursor_scale , cursor_scale)
				menu_drawq(cur_img, cur_img_right, render_x+button_width+spacing-cur_img_w*cursor_scale/2, render_y-spacing, 0, cursor_scale, cursor_scale)
			end
		end

		-- WHAT IS THIS?????????????
		-- WHY IS THIS "...AND ( A == B or A == B)"
		-- WHY WOULD YOU DO THIS?????????
		if my_state and my_state.cursor and (my_state.cursor == str or my_state.cursor == str) then
			player_num = 1
			if my_state.ready then
				if (math.floor(menu_clock/cur_blink_frequency)+player_num)%2+1 == player_num then
					draw_cur_this_frame = true
					cursor_frame = 1
				else
					draw_cur_this_frame = false
				end
			else
				draw_cur_this_frame = true
				cursor_frame = (math.floor(menu_clock/cur_pos_change_frequency)+player_num)%2+1
				cur_img = IMG_char_sel_cursors[player_num][cursor_frame]
			end
			if draw_cur_this_frame then
				cur_img = IMG_char_sel_cursors[player_num][cursor_frame]
				cur_img_left = IMG_char_sel_cursor_halves.left[player_num][cursor_frame]
				cur_img_right = IMG_char_sel_cursor_halves.right[player_num][cursor_frame]
				local cur_img_w, cur_img_h = cur_img:getDimensions()
				local cursor_scale = (button_height+(spacing*2))/cur_img_h
				menu_drawq(cur_img, cur_img_left, render_x-spacing, render_y-spacing, 0, cursor_scale , cursor_scale)
				menu_drawq(cur_img, cur_img_right, render_x+button_width+spacing-cur_img_w*cursor_scale/2, render_y-spacing, 0, cursor_scale, cursor_scale)
			end
		end
		gprint(pstr, render_x+6, render_y+y_add)
	end

	-- why is that function called draw_button when it has so much fucking logic in it
	-- what is going on. why would you do this. why. why. whyyyyyyy

	-- what does LOC even MEAN
	print("got to LOC before net_vs_room character select loop")
	menu_clock = 0
	while true do
		if character_select_mode == "2p_net_vs" then
			for _,msg in ipairs(this_frame_messages) do
				if msg.win_counts then
					update_win_counts(msg.win_counts)
				end
				if msg.menu_state then
					if currently_spectating then
						if msg.player_number == 2 then
							op_state = msg.menu_state
						elseif msg.player_number == 1 then
							my_state = msg.menu_state
						end
					else
						op_state = msg.menu_state
					end
				end
				if msg.ranked_match_approved then
					match_type = "Ranked"
					match_type_message = ""
					if msg.caveats then
						match_type_message = match_type_message..(msg.caveats[1] or "")
					end
				elseif msg.ranked_match_denied then
					match_type = "Casual"
					match_type_message = "Not ranked. "
					if msg.reasons then
						match_type_message = match_type_message..(msg.reasons[1] or "Reason unknown")
					end
				end
				if msg.leave_room then
					my_win_count = 0
					op_win_count = 0
					write_char_sel_settings_to_file()
					return main_net_vs_lobby
				end
				if msg.match_start or replay_of_match_so_far then
					local fake_P1 = P1
					print("currently_spectating: "..tostring(currently_spectating))
					local fake_P2 = P2

					local p1char	= stages[msg.player_settings.character] and msg.player_settings.character or characters[1]
					local p2char	= stages[msg.opponent_settings.character] and msg.opponent_settings.character or characters[1]

					P1 = Playfield(1, "vs", msg.player_settings.level, p1char, msg.player_settings.player_number)
					P2 = Playfield(2, "vs", msg.opponent_settings.level, p2char, msg.opponent_settings.player_number)
					if currently_spectating then
						P1.panel_buffer = fake_P1.panel_buffer
						P1.gpanel_buffer = fake_P1.gpanel_buffer
					end
					P2.panel_buffer = fake_P2.panel_buffer
					P2.gpanel_buffer = fake_P2.gpanel_buffer
					P1.garbage_target = P2
					P2.garbage_target = P1
					P2.pos_x = 172
					P2.score_x = 410
					replay.vs = {P="",O="",I="",Q="",R="",in_buf="",
											P1_level=P1.level,P2_level=P2.level,
											P1_name=my_name, P2_name=op_name,
											P1_char=P1.character,P2_char=P2.character,
											ranked=msg.ranked, do_countdown=true}
					print("stupid debug bullshit: ", P1.character, P2.character)
					if currently_spectating and replay_of_match_so_far then --we joined a match in progress
						replay.vs = replay_of_match_so_far.vs
						P1.input_buffer = replay_of_match_so_far.vs.in_buf
						P1.panel_buffer = replay_of_match_so_far.vs.P
						P1.gpanel_buffer = replay_of_match_so_far.vs.Q
						P2.input_buffer = replay_of_match_so_far.vs.I
						P2.panel_buffer = replay_of_match_so_far.vs.O
						P2.gpanel_buffer = replay_of_match_so_far.vs.R
						if replay.vs.ranked then
							match_type = "Ranked"
							match_type_message = ""
						else
							match_type = "Casual"
						end
						replay_of_match_so_far = nil
						P1.play_to_end = true  --this makes foreign_run run until caught up
						P2.play_to_end = true
					end
					if not currently_spectating then
							ask_for_gpanels("000000")
							ask_for_panels("000000")
					end
					to_print = "Game is starting!\n".."Level: "..P1.level.."\nOpponent's level: "..P2.level
					if P1.play_to_end or P2.play_to_end then
						to_print = "Joined a match in progress.\nCatching up..."
					end
					for i=1,30 do
						gprint(to_print,300, 280)
						do_messages()
						coroutine.yield()
					end
					local game_start_timeout = 0
					while P1.panel_buffer == "" or P2.panel_buffer == ""
						or P1.gpanel_buffer == "" or P2.gpanel_buffer == "" do
						--testing getting stuck here at "Game is starting"
						game_start_timeout = game_start_timeout + 1
						print("game_start_timeout = "..game_start_timeout)
						print("P1.panel_buffer = "..P1.panel_buffer)
						print("P2.panel_buffer = "..P2.panel_buffer)
						print("P1.gpanel_buffer = "..P1.gpanel_buffer)
						print("P2.gpanel_buffer = "..P2.gpanel_buffer)
						gprint(to_print,300, 280)
						do_messages()
						coroutine.yield()
						if game_start_timeout > 250 then
							return main_dumb_transition, {main_select_mode,
															"game start timed out.\n This is a known bug, but you may post it in #panel-attack-bugs-features \nif you'd like.\n"
															.."\n".."msg.match_start = "..(tostring(msg.match_start) or "nil")
															.."\n".."replay_of_match_so_far = "..(tostring(replay_of_match_so_far) or "nil")
															.."\n".."P1.panel_buffer = "..P1.panel_buffer
															.."\n".."P2.panel_buffer = "..P2.panel_buffer
															.."\n".."P1.gpanel_buffer = "..P1.gpanel_buffer
															.."\n".."P2.gpanel_buffer = "..P2.gpanel_buffer,
															180}
						end
					end
					P1:starting_state()
					P2:starting_state()
					return main_net_vs
				end
			end
		end

		-- you could just skip drawing the ranking button
		-- but also why is it based on the title of the button
		-- why is any of this a thing
		if current_server_supports_ranking then
			draw_button(1,1,4,1,"match type desired")
			draw_button(1,5,2,1,"level")
		else
			draw_button(1,1,6,1,"level")
		end

		draw_button(1,7,1,1,"ready")

		-- can someone please explain to me what the purpose of
		-- "a or a" is here
		-- like what were you trying to accomplish
		-- just. why. why. whyyyyyyyyyyyyyYYYYYYYYYYYYYYY
		for i=2,X do
			for j=1,Y do
				draw_button(i,j,1,1,map[i][j] or map[i][j])
			end
		end

		-- why is rating calculation just here instead of somewhere useful
		local my_rating_difference = ""
		local op_rating_difference = ""
		if current_server_supports_ranking and not global_current_room_ratings[my_player_number].placement_match_progress then
			if global_current_room_ratings[my_player_number].difference then
				if global_current_room_ratings[my_player_number].difference>= 0 then
					my_rating_difference = "(+"..global_current_room_ratings[my_player_number].difference..") "
				else
					my_rating_difference = "("..global_current_room_ratings[my_player_number].difference..") "
				end
			end
			if global_current_room_ratings[op_player_number].difference then
				if global_current_room_ratings[op_player_number].difference >= 0 then
					op_rating_difference = "(+"..global_current_room_ratings[op_player_number].difference..") "
				else
					op_rating_difference = "("..global_current_room_ratings[op_player_number].difference..") "
				end
			end
		end
		local state = ""

		-- ok so the first thing they do here is add the name.
		-- if you know that why not just make local state = my_name?

		state = state..my_name
		if current_server_supports_ranking then
			state = state..":  Rating: "..(global_current_room_ratings[my_player_number].league or "")
			if not global_current_room_ratings[my_player_number].placement_match_progress then
				state = state.." "..my_rating_difference..global_current_room_ratings[my_player_number].new
			elseif global_current_room_ratings[my_player_number].placement_match_progress
			and global_current_room_ratings[my_player_number].new
			and global_current_room_ratings[my_player_number].new == 0 then
				state = state.." "..global_current_room_ratings[my_player_number].placement_match_progress
			end
		end
		if character_select_mode == "2p_net_vs" or character_select_mode == "2p_local_vs" then
			state = state.."  Wins: "..my_win_count
		end
		if current_server_supports_ranking or my_win_count + op_win_count > 0 then
			state = state.."  Win Ratio:"
		end
		if my_win_count + op_win_count > 0 then
			state = state.."  actual: "..(100*round(my_win_count/(op_win_count+my_win_count),2)).."%"
		end
		if current_server_supports_ranking and my_expected_win_ratio then
			state = state.."  expected: "
				..my_expected_win_ratio.."%"
		end
		state = state.."  Char: "..my_state.character .."  Ready: "..tostring(my_state.ready or false)

		-- draw 2p stuff here i guess. ok.
		if op_state and op_name then
			state = state.."\n"
			state = state..op_name
			if current_server_supports_ranking then
				state = state..":  Rating: "..(global_current_room_ratings[op_player_number].league or "")
				if not global_current_room_ratings[op_player_number].placement_match_progress then
					state = state.." "..op_rating_difference..global_current_room_ratings[op_player_number].new
				elseif global_current_room_ratings[op_player_number].placement_match_progress
				and global_current_room_ratings[op_player_number].new
				and global_current_room_ratings[op_player_number].new == 0 then
					state = state.." "..global_current_room_ratings[op_player_number].placement_match_progress
				end
			end

			state = state.."  Wins: "..op_win_count
			if current_server_supports_ranking or my_win_count + op_win_count > 0 then
				state = state.."  Win Ratio:"
			end
			if my_win_count + op_win_count > 0 then
				state = state.."  actual: "..(100*round(op_win_count/(op_win_count+my_win_count),2)).."%"
			end
			if current_server_supports_ranking and op_expected_win_ratio then
				state = state.."  expected: "
					..op_expected_win_ratio.."%"
			end
			state = state.."  Char: "..op_state.character.."  Ready: "..tostring(op_state.ready or false)
			--state = state.." "..json.encode(op_state)
		end

		gprint(state, 50, 50)

		-- ok more 2p stuff here.
		if character_select_mode == "2p_net_vs" then
			if not my_state.ranked and not op_state.ranked then
				match_type_message = ""
			end
			gprint(match_type, 375, 15)
			gprint(match_type_message,100,85)
		end
		coroutine.yield()
		local ret = nil
		variable_step(function()
			menu_clock = menu_clock + 1
			if not currently_spectating then
				if menu_up(k) then
					if not selected then move_cursor(up) end
				elseif menu_down(k) then
					if not selected then move_cursor(down) end
				elseif menu_left(k) then
					if selected and active_str == "level" then
						config.level = bound(1, config.level-1, 10)
					end
					if not selected then move_cursor(left) end
				elseif menu_right(k) then
					if selected and active_str == "level" then
						config.level = bound(1, config.level+1, 10)
					end
					if not selected then move_cursor(right) end
				elseif menu_enter(k) then
					if selectable[active_str] then
						selected = not selected
					elseif active_str == "leave" then
						if character_select_mode == "2p_net_vs" then
							if not do_leave() then
								ret = {main_dumb_transition, {main_select_mode, "Error when leaving online"}}
							end
						else
							ret = {main_select_mode}
						end
					elseif active_str == "random" then
						config.character = uniformly(characters)
					elseif active_str == "match type desired" then
						config.ranked = not config.ranked
					else
						config.character = stages[active_str] and active_str or characters[1]
						--When we select a character, move cursor to "ready"
						active_str = "ready"
						cursor = shallowcpy(name_to_xy["ready"])
					end
				elseif menu_escape(k) then
					if active_str == "leave" then
						if character_select_mode == "2p_net_vs" then
							if not do_leave() then
								ret = {main_dumb_transition, {main_select_mode, "Error when leaving online"}}
							end
						else
							ret = {main_select_mode}
						end
					end
					selected = false
					cursor = shallowcpy(name_to_xy["leave"])
				end
				active_str = map[cursor[1]][cursor[2]]
				my_state = {character=config.character, level=config.level, cursor=active_str, ranked=config.ranked,
										ready=(selected and active_str=="ready")}
				if character_select_mode == "2p_net_vs" and not content_equal(my_state, prev_state) and not currently_spectating then
					json_send({menu_state=my_state})
				end
				prev_state = my_state
			else -- (we are are spectating)
				if menu_escape(k) then
					do_leave()
					ret = {main_net_vs_lobby}
				end
			end
		end)
		if ret then
			return unpack(ret)
		end
		if my_state.ready and character_select_mode == "1p_vs_yourself" then
			P1 = Playfield(1, "vs", my_state.level, my_state.character)
			P1.garbage_target = P1
			make_local_panels(P1, "000000")
			make_local_gpanels(P1, "000000")
			P1:starting_state()
			return main_dumb_transition, {main_local_vs_yourself, "Game is starting...", 30, 30}
		end
		if character_select_mode == "2p_net_vs" then
			do_messages()
		end
	end
end
