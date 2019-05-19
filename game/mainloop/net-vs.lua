function main_net_vs()
	--STONER_MODE = true
	local k = K[1]  --may help with spectators leaving games in progress
	local end_text = nil
	consuming_timesteps = true
	local op_name_y = 40
	if string.len(my_name) > 12 then
				op_name_y = 55
	end
	while true do
		-- Uncomment this to cripple your game :D
		-- love.timer.sleep(0.030)
		for _,msg in ipairs(this_frame_messages) do
			if msg.leave_room then
				write_char_sel_settings_to_file()
				return main_net_vs_lobby
			end
		end
		gprint(my_name or "", 315, 40)
		gprint(op_name or "", 410, op_name_y)
		gprint("Wins: "..my_win_count, 315, 70)
		gprint("Wins: "..op_win_count, 410, 70)
		if not config.debug_mode then --this is printed in the same space as the debug details
			gprint(spectators_string, 315, 265)
		end
		if match_type == "Ranked" then
			if global_current_room_ratings[my_player_number]
			and global_current_room_ratings[my_player_number].new then
				local rating_to_print = "Rating: "
				if global_current_room_ratings[my_player_number].new > 0 then
					rating_to_print = rating_to_print.." "..global_current_room_ratings[my_player_number].new
				end
				gprint(rating_to_print, 315, 85)
			end
			if global_current_room_ratings[op_player_number]
			and global_current_room_ratings[op_player_number].new then
				local op_rating_to_print = "Rating: "
				if global_current_room_ratings[op_player_number].new > 0 then
					op_rating_to_print = op_rating_to_print.." "..global_current_room_ratings[op_player_number].new
				end
				gprint(op_rating_to_print, 410, 85)
			end
		end
		if not (P1 and P1.play_to_end) and not (P2 and P2.play_to_end) then
			P1:render()
			P2:render()
			coroutine.yield()
			if currently_spectating and this_frame_keys["escape"] then
				print("spectator pressed escape during a game")
				stop_the_music()
				my_win_count = 0
				op_win_count = 0
				json_send({leave_room=true})
				return main_net_vs_lobby
			end
			do_messages()
		end

		--print(P1.CLOCK, P2.CLOCK)
		if (P1 and P1.play_to_end) or (P2 and P2.play_to_end) then
			if not P1.game_over then
				if currently_spectating then
					P1:foreign_run()
				else
					P1:local_run()
				end
			end
			if not P2.game_over then
				P2:foreign_run()
			end
		else
			variable_step(function()
				if not P1.game_over then
					if currently_spectating then
							P1:foreign_run()
					else
						P1:local_run()
					end
				end
				if not P2.game_over then
					P2:foreign_run()
				end
			end)
		end

		local outcome_claim = nil
		if P1.game_over and P2.game_over and P1.CLOCK == P2.CLOCK then
			end_text = "Draw"
			outcome_claim = 0
		elseif P1.game_over and P1.CLOCK <= P2.CLOCK then
			end_text = op_name.." Wins" .. (currently_spectating and " " or " :(")
			op_win_count = op_win_count + 1 -- leaving these in just in case used with an old server that doesn't keep score.  win_counts will get overwritten after this by the server anyway.
			outcome_claim = P2.player_number
		elseif P2.game_over and P2.CLOCK <= P1.CLOCK then
			end_text = my_name.." Wins" .. (currently_spectating and " " or " ^^")
			my_win_count = my_win_count + 1 -- leave this in
			outcome_claim = P1.player_number

		end
		if end_text then
			undo_stonermode()
			json_send({game_over=true, outcome=outcome_claim})
			local now = os.date("*t",to_UTC(os.time()))
			local sep = "/"
			local path = "replays"..sep.."v"..VERSION..sep..string.format("%04d"..sep.."%02d"..sep.."%02d", now.year, now.month, now.day)
			local rep_a_name, rep_b_name = my_name, op_name
			--sort player names alphabetically for folder name so we don't have a folder "a-vs-b" and also "b-vs-a"
			if rep_b_name <  rep_a_name then
				path = path..sep..rep_b_name.."-vs-"..rep_a_name
			else
				path = path..sep..rep_a_name.."-vs-"..rep_b_name
			end
			local filename = "v"..VERSION.."-"..string.format("%04d-%02d-%02d-%02d-%02d-%02d", now.year, now.month, now.day, now.hour, now.min, now.sec).."-"..rep_a_name.."-L"..P1.level.."-vs-"..rep_b_name.."-L"..P2.level
			if match_type and match_type ~= "" then
				filename = filename.."-"..match_type
			end
			if outcome_claim == 1 or outcome_claim == 2 then
				filename = filename.."-P"..outcome_claim.."wins"
			elseif outcome_claim == 0 then
				filename = filename.."-draw"
			end
			filename = filename..".txt"
			print("saving replay as "..path..sep..filename)
			write_replay_file(path, filename)
			print("also saving replay as replay.txt")
			write_replay_file()
			character_select_mode = "2p_net_vs"
			if currently_spectating then
				return main_dumb_transition, {main_character_select, end_text, 45, 45}
			else
				return main_dumb_transition, {main_character_select, end_text, 45, 180}
			end
		end
	end
end
