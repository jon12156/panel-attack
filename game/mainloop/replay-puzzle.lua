function main_replay_puzzle()
	local replay = replay.puzzle
	if replay.in_buf == nil or replay.in_buf == "" then
		return main_dumb_transition,
			{main_select_mode, "I don't have a puzzle replay :("}
	end
	P1 = Playfield(1, "puzzle")
	P1.do_countdown = replay.do_countdown or false
	P1.max_runs_per_frame = 1
	P1.input_buffer = replay.in_buf
	P1:set_puzzle_state(unpack(replay.puzzle))
	local run = true
	while true do
		mouse_panel = nil
		P1:render()
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
				ret =  {main_select_mode}
			end
			if this_frame_keys["return"] then
				run = not run
			end
			if this_frame_keys["\\"] then
				run = false
			end
			if run or this_frame_keys["\\"] then
				if P1.n_active_panels == 0 and
						P1.prev_active_panels == 0 then
					if P1:puzzle_done() then
						ret = {main_dumb_transition, {main_select_mode, "You win!"}}
					elseif P1.puzzle_moves == 0 then
						ret = {main_dumb_transition, {main_select_mode, "You lose :("}}
					end
				end
				P1:foreign_run()
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end
