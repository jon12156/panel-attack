function main_time_attack(...)
	consuming_timesteps = true
	P1 = Playfield(1, "time", ...)
	make_local_panels(P1, "000000")
	P1:starting_state()
	while true do
		P1:render()
		coroutine.yield()
		if P1.game_over or (P1.game_stopwatch and P1.game_stopwatch == 120*60) then
		-- TODO: proper game over.
			local end_text = "You scored "..P1.score.."\nin "..frames_to_time_string(P1.game_stopwatch)
				return main_dumb_transition, {main_select_mode, end_text, 30}
		end
		variable_step(function()
			if (not P1.game_over)  and P1.game_stopwatch and P1.game_stopwatch < 120 * 60 then
				P1:local_run() end end)
	end
end
