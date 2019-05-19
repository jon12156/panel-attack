function main_net_vs_lobby()
	local active_name, active_idx, active_back = "", 1
	local items
	local unpaired_players = {} -- list
	local willing_players = {} -- set
	local spectatable_rooms = {}
	local k = K[1]
	my_player_number = nil
	op_player_number = nil
	local notice = {[true]="Select a player name to ask for a match.", [false]="You are all alone in the lobby :("}
	local leaderboard_string = ""
	local my_rank
	love.audio.stop()
	stop_the_music()
	match_type = ""
	match_type_message = ""
	--attempt login
	read_user_id_file()
	if not my_user_id then
		my_user_id = "need a new user id"
	end
	json_send({login_request=true, user_id=my_user_id})
	local login_status_message = "   Logging in..."
	local login_status_message_duration = 2
	local login_denied = false
	local prev_act_idx = active_idx
	local showing_leaderboard = false
	local lobby_menu_x = {[true]=100, [false]=300} --will be used to make room in case the leaderboard should be shown.
	local sent_requests = {}
	while true do
			if connection_up_time <= login_status_message_duration then
				gprint(login_status_message, lobby_menu_x[showing_leaderboard], 160)
				for _,msg in ipairs(this_frame_messages) do
						if msg.login_successful then
							current_server_supports_ranking = true
							logged_in = true
							if msg.new_user_id then
								my_user_id = msg.new_user_id
								print("about to write user id file")
								write_user_id_file()
								login_status_message = "Welcome, new user: "..my_name
							elseif msg.name_changed then
								login_status_message = "Welcome, your username has been updated. \n\nOld name:  \""..msg.old_name.."\"\n\nNew name:  \""..msg.new_name.."\""
								login_status_message_duration = 5
							else
								login_status_message = "Welcome back, "..my_name
							end
						elseif msg.login_denied then
								current_server_supports_ranking = true
								login_denied = true
								--TODO: create a menu here to let the user choose "continue unranked" or "get a new user_id"
								--login_status_message = "Login for ranked matches failed.\n"..msg.reason.."\n\nYou may continue unranked,\nor delete your invalid user_id file to have a new one assigned."
								login_status_message_duration = 10
								return main_dumb_transition, {main_select_mode, "Error message received from the server:\n\n"..json.encode(msg),60,600}
						end
				end
				if connection_up_time == 2 and not current_server_supports_ranking then
								login_status_message = "Login for ranked matches timed out.\nThis server probably doesn't support ranking.\n\nYou may continue unranked."
								login_status_message_duration = 7
				end
			end
		for _,msg in ipairs(this_frame_messages) do
			if msg.choose_another_name and msg.choose_another_name.used_names then
				return main_dumb_transition, {main_select_mode, "Error: name is taken :<\n\nIf you had just left the server,\nit may not have realized it yet, try joining again.\n\nThis can also happen if you have two\ninstances of Panel Attack open.\n\nPress Swap or Back to continue.", 60, 600}
			elseif msg.choose_another_name and msg.choose_another_name.reason then
				return main_dumb_transition, {main_select_mode, "Error: ".. msg.choose_another_name.reason, 60}
			end
			if msg.create_room or msg.spectate_request_granted then
				global_initialize_room_msg = msg
				character_select_mode = "2p_net_vs"
				return main_character_select
			end
			if msg.unpaired then
				unpaired_players = msg.unpaired
				-- players who leave the unpaired list no longer have standing invitations to us.\
				-- we also no longer have a standing invitation to them, so we'll remove them from sent_requests
				local new_willing = {}
				local new_sent_requests = {}
				for _,player in ipairs(unpaired_players) do
					new_willing[player] = willing_players[player]
					new_sent_requests[player] = sent_requests[player]
				end
				willing_players = new_willing
				sent_requests = new_sent_requests
			end
			if msg.spectatable then
				spectatable_rooms = msg.spectatable
			end
			if msg.game_request then
				willing_players[msg.game_request.sender] = true
			end
			if msg.leaderboard_report then
				showing_leaderboard = true
				leaderboard_report = msg.leaderboard_report
				for k,v in ipairs(leaderboard_report) do
					if v.is_you then
						my_rank = k
					end
				end
				leaderboard_first_idx_to_show = math.max((my_rank or 1)-8,1)
				leaderboard_last_idx_to_show = math.min(leaderboard_first_idx_to_show + 20,#leaderboard_report)
				leaderboard_string = build_viewable_leaderboard_string(leaderboard_report, leaderboard_first_idx_to_show, leaderboard_last_idx_to_show)
			end
		end
		local to_print = ""
		local arrow = ""
		items = {}
		for _,v in ipairs(unpaired_players) do
			if v ~= config.name then
				items[#items+1] = v
			end
		end
		local lastPlayerIndex = #items --the rest of the items will be spectatable rooms, except the last two items (leaderboard and back to main menu)
		for _,v in ipairs(spectatable_rooms) do
			items[#items+1] = v
		end
		if showing_leaderboard then
			items[#items+1] = "Hide Leaderboard"
		else
			items[#items+1] = "Show Leaderboard"  -- the second to last item is "Leaderboard"
		end
		items[#items+1] = "Back to main menu" -- the last item is "Back to the main menu"
		if active_back then
			active_idx = #items
		elseif showing_leaderboard then
			active_idx = #items - 1 --the position of the "hide leaderboard" menu item
		else
			while active_idx > #items do
				print("active_idx > #items.  Decrementing active_idx")
				active_idx = active_idx - 1
			end
			active_name = items[active_idx]
		end
		for i=1,#items do
			if active_idx == i then
				arrow = arrow .. ">"
			else
				arrow = arrow .. "\n"
			end
			if i <= lastPlayerIndex then
				to_print = to_print .. "   " .. items[i] ..(sent_requests[items[i]] and " (Request sent)" or "").. (willing_players[items[i]] and " (Wants to play with you :o)" or "") .. "\n"
			elseif i < #items - 1 and items[i].name then
				to_print = to_print .. "   spectate " .. items[i].name .. " (".. items[i].state .. ")\n" --printing room names
			elseif i < #items then
				to_print = to_print .. "   " .. items[i] .. "\n"
			else
				to_print = to_print .. "   " .. items[i]
			end
		end
		gprint(notice[#items > 2], lobby_menu_x[showing_leaderboard], 250)
		gprint(arrow, lobby_menu_x[showing_leaderboard], 280)
		gprint(to_print, lobby_menu_x[showing_leaderboard], 280)
		if showing_leaderboard then
			gprint(leaderboard_string, 500, 160)
		end
		gprint(join_community_msg, 20, 560)

		coroutine.yield()
		local ret = nil
		variable_step(function()
			if menu_up(k) then
				if showing_leaderboard then
					if leaderboard_first_idx_to_show>1 then
						leaderboard_first_idx_to_show = leaderboard_first_idx_to_show - 1
						leaderboard_last_idx_to_show = leaderboard_last_idx_to_show - 1
						leaderboard_string = build_viewable_leaderboard_string(leaderboard_report, leaderboard_first_idx_to_show, leaderboard_last_idx_to_show)
					end
				else
					active_idx = wrap(1, active_idx-1, #items)
				end
			elseif menu_down(k) then
				if showing_leaderboard then
					if leaderboard_last_idx_to_show < #leaderboard_report then
						leaderboard_first_idx_to_show = leaderboard_first_idx_to_show + 1
						leaderboard_last_idx_to_show = leaderboard_last_idx_to_show + 1
						leaderboard_string = build_viewable_leaderboard_string(leaderboard_report, leaderboard_first_idx_to_show, leaderboard_last_idx_to_show)
					end
				else
					active_idx = wrap(1, active_idx+1, #items)
				end
			elseif menu_enter(k) then
				spectator_list = {}
				spectators_string = ""
				if active_idx == #items then
					ret = {main_select_mode}
				end
				if active_idx == #items - 1 then
					if not showing_leaderboard then
						json_send({leaderboard_request=true})
					else
						showing_leaderboard = false --toggle it off
					end
				elseif active_idx <= lastPlayerIndex then
					my_name = config.name
					op_name = items[active_idx]
					currently_spectating = false
					sent_requests[op_name] = true
					request_game(items[active_idx])
				else
					my_name = items[active_idx].a
					op_name = items[active_idx].b
					currently_spectating = true
					room_number_last_spectated = items[active_idx].roomNumber
					request_spectate(items[active_idx].roomNumber)
				end
			elseif menu_escape(k) then
				if active_idx == #items then
					ret = {main_select_mode}
				elseif showing_leaderboard then
					showing_leaderboard = false
				else
					active_idx = #items
				end
			end
		end)
		if ret then
			return unpack(ret)
		end
		active_back = active_idx == #items
		if active_idx ~= prev_act_idx then
			print("#items: "..#items.."  idx_old: "..prev_act_idx.."  idx_new: "..active_idx.."  active_back: "..tostring(active_back))
			prev_act_idx = active_idx
		end
		do_messages()
	end
end

function build_viewable_leaderboard_string(report, first_viewable_idx, last_viewable_idx)
	str = "        Leaderboard\n      Rank    Rating   Player\n"
	first_viewable_idx = math.max(first_viewable_idx,1)
	last_viewable_idx = math.min(last_viewable_idx, #report)
	for i=first_viewable_idx,last_viewable_idx do
		if report[i].is_you then
			str = str.."You-> "
		else
			str = str.."      "
		end
		str = str..i.."    "..report[i].rating.."    "..report[i].user_name
		if i < #report then
			str = str.."\n"
		end
	end
	return str
end
