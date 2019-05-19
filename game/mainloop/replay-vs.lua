function main_replay_vs()
	local replay = replay.vs
	P1 = Playfield(1, "vs", replay.P1_level or 5)
	P2 = Playfield(2, "vs", replay.P2_level or 5)
	P1.do_countdown = replay.do_countdown or false
	P2.do_countdown = replay.do_countdown or false
	P1.ice = true
	P1.garbage_target = P2
	P2.garbage_target = P1
	P2.pos_x = 172
	P2.score_x = 410
	P1.input_buffer = replay.in_buf
	P1.panel_buffer = replay.P
	P1.gpanel_buffer = replay.Q
	P2.input_buffer = replay.I
	P2.panel_buffer = replay.O
	P2.gpanel_buffer = replay.R
	P1.max_runs_per_frame = 1
	P2.max_runs_per_frame = 1
	print("more debug bullshit: ", P1.character, P2.character)
	P1.character = stages[replay.P1_char] and replay.P1_char or characters[1]
	P2.character = stages[replay.P2_char] and replay.P2_char or characters[1]
	print("even more debug bullshit: ", P1.character, P2.character)

	my_name = replay.P1_name or "Player 1"
	op_name = replay.P2_name or "Player 2"
	if character_select_mode == "2p_net_vs" then
		if replay.ranked then
			match_type = "Ranked"
		else
			match_type = "Casual"
		end
	end

	P1:starting_state()
	P2:starting_state()
	local end_text = nil
	local run = true
	local op_name_y = 40
	if string.len(my_name) > 12 then
		op_name_y = 55
	end
	while true do
		mouse_panel = nil
		gprint(my_name or "", 315, 40)
		gprint(op_name or "", 410, op_name_y)
		P1:render()
		P2:render()
		if mouse_panel then
			local str = "Panel info:\nrow: "..mouse_panel[1].."\ncol: "..mouse_panel[2]
			for k,v in spairs(mouse_panel[3]) do
				str = str .. "\n".. k .. ": "..tostring(v)
			end
			gprint(str, 350, 400)
		end
		coroutine.yield()
		local ret = nil
		variable_step(function()
			if this_frame_keys["escape"] then
				ret = {main_select_mode}
			end
			if this_frame_keys["return"] then
				run = not run
			end
			if this_frame_keys["\\"] then
				run = false
			end
			if run or this_frame_keys["\\"] then
				if not P1.game_over then
					P1:foreign_run()
				end
				if not P2.game_over then
					P2:foreign_run()
				end
			end
		end)
		if ret then
			return unpack(ret)
		end
		if P1.game_over and P2.game_over and P1.CLOCK == P2.CLOCK then
			end_text = "Draw"
		elseif P1.game_over and P1.CLOCK <= P2.CLOCK then
			if replay.P2_name and replay.P2_name ~= "anonymous" then
				end_text = replay.P2_name.." wins"
			else
				end_text = "P2 wins"
			end
		elseif P2.game_over and P2.CLOCK <= P1.CLOCK then
			if replay.P1_name and replay.P1_name ~= "anonymous" then
				end_text = replay.P1_name.." wins"
			else
				end_text = "P1 wins"
			end
		end
		if end_text then
			return main_dumb_transition, {main_select_mode, end_text}
		end
	end
end
