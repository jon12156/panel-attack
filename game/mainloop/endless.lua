function main_endless(...)
	consuming_timesteps = true
	replay.endless = {}
	local replay=replay.endless
	replay.pan_buf = ""
	replay.in_buf = ""
	replay.gpan_buf = ""
	replay.mode = "endless"
	P1 = Playfield(1, "endless", ...)
	P1.do_countdown = config.ready_countdown_1P or false
	replay.do_countdown = P1.do_countdown or false
	replay.speed = P1.speed
	replay.difficulty = P1.difficulty
	make_local_panels(P1, "000000")
	make_local_gpanels(P1, "000000")
	P1:starting_state()
	while true do
		P1:render()
		coroutine.yield()
		if P1.game_over then
		-- TODO: proper game over.
			write_replay_file()
			local end_text = "You scored "..P1.score.."\nin "..frames_to_time_string(P1.game_stopwatch, true)
				return main_dumb_transition, {main_select_mode, end_text, 60}
		end
		variable_step(function() P1:local_run() end)
		--groundhogday mode
		--[[if P1.CLOCK == 1001 then
			local prev_states = P1.prev_states
			P1 = prev_states[600]
			P1.prev_states = prev_states
		end--]]
	end
end
