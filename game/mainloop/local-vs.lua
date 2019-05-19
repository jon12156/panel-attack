function main_local_vs()
	-- TODO: replay!
	consuming_timesteps = true
	local end_text = nil
	while true do
		P1:render()
		P2:render()
		coroutine.yield()
		variable_step(function()
				if not P1.game_over and not P2.game_over then
					P1:local_run()
					P2:local_run()
				end
			end)
		if P1.game_over and P2.game_over and P1.CLOCK == P2.CLOCK then
			end_text = "Draw"
		elseif P1.game_over and P1.CLOCK <= P2.CLOCK then
			end_text = "P2 wins ^^"
		elseif P2.game_over and P2.CLOCK <= P1.CLOCK then
			end_text = "P1 wins ^^"
		end
		if end_text then
			return main_dumb_transition, {main_select_mode, end_text, 45}
		end
	end
end
