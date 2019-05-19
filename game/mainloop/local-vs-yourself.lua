function main_local_vs_yourself()
	-- TODO: replay!
	consuming_timesteps = true
	local end_text = nil
	while true do
		P1:render()
		coroutine.yield()
		variable_step(function()
				if not P1.game_over then
					P1:local_run()
				else
					end_text = "Game Over"
				end
			end)
		if end_text then
			return main_dumb_transition, {main_character_select, end_text, 45}
		end
	end
end
