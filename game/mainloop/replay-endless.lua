function main_replay_endless()
	local replay = replay.endless
	if replay == nil or replay.speed == nil then
		return main_dumb_transition,
			{main_select_mode, "I don't have an endless replay :("}
	end
	P1 = Playfield(1, "endless", replay.speed, replay.difficulty)
	P1.do_countdown = replay.do_countdown or false
	P1.max_runs_per_frame = 1
	P1.input_buffer = table.concat({replay.in_buf})
	P1.panel_buffer = replay.pan_buf
	P1.gpanel_buffer = replay.gpan_buf
	P1.speed = replay.speed
	P1.difficulty = replay.difficulty
	P1:starting_state()
	local run = true
	while true do
		P1:render()
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
				if P1.game_over then
				-- TODO: proper game over.
					local end_text = "You scored "..P1.score.."\nin "..frames_to_time_string(P1.game_stopwatch, true)
					ret = {main_dumb_transition, {main_select_mode, end_text, 30}}
				end
				P1:foreign_run()
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end
