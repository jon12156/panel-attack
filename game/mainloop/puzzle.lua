function make_main_puzzle(puzzles)
	local awesome_idx, next_func = 1, nil
	function next_func()
		consuming_timesteps = true
		replay.puzzle = {}
		local replay = replay.puzzle
		P1 = Playfield(1, "puzzle")
		P1.do_countdown = config.ready_countdown_1P or false
		local start_delay = 0
		if awesome_idx == nil then
			awesome_idx = math.random(#puzzles)
		end
		P1:set_puzzle_state(unpack(puzzles[awesome_idx]))
		replay.puzzle = puzzles[awesome_idx]
		replay.in_buf = ""
		while true do
			P1:render()
			coroutine.yield()
			local ret = nil
			variable_step(function()
				if this_frame_keys["escape"] then
					ret = {main_select_puzz}
				end
				if P1.n_active_panels == 0 and
						P1.prev_active_panels == 0 then
					if P1:puzzle_done() then
						awesome_idx = (awesome_idx % #puzzles) + 1
						write_replay_file()
						if awesome_idx == 1 then
							ret = {main_dumb_transition, {main_select_puzz, "You win!", 30}}
						else
							ret = {main_dumb_transition, {ret, "You win!", 30}}
						end
					elseif P1.puzzle_moves == 0 then
						write_replay_file()
						ret = {main_dumb_transition, {main_select_puzz, "You lose :(", 30}}
					end
				end
				if P1.n_active_panels ~= 0 or P1.prev_active_panels ~= 0 or
						P1.puzzle_moves ~= 0 then
					P1:local_run()
				end
			end)
			if ret then
				return unpack(ret)
			end
		end
	end
	return next_func
end

do
	local items = {}
	for key,val in spairs(puzzle_sets) do
		items[#items+1] = {key, make_main_puzzle(val)}
	end
	items[#items+1] = {"Back", main_select_mode}
	function main_select_puzz()
		love.audio.stop()
		stop_the_music()
		local active_idx = last_puzzle_idx or 1
		local k = K[1]
		while true do
			local to_print = ""
			local arrow = ""
			for i=1,#items do
				if active_idx == i then
					arrow = arrow .. ">"
				else
					arrow = arrow .. "\n"
				end
				to_print = to_print .. "   " .. items[i][1] .. "\n"
			end
			gprint("Puzzles:", 300, 20)
			gprint("Note: you may place new custom puzzles in\n\n%appdata%\\Panel Attack\\puzzles\n\nSee the README and example puzzle set there\nfor instructions", 20, 500)
			gprint(arrow, 400, 20)
			gprint(to_print, 400, 20)
			coroutine.yield()
			local ret = nil
			variable_step(function()
				if menu_up(k) then
					active_idx = wrap(1, active_idx-1, #items)
				elseif menu_down(k) then
					active_idx = wrap(1, active_idx+1, #items)
				elseif menu_enter(k) then
					last_puzzle_idx = active_idx
					ret = {items[active_idx][2], items[active_idx][3]}
				elseif menu_escape(k) then
					if active_idx == #items then
						ret = {items[active_idx][2], items[active_idx][3]}
					else
						active_idx = #items
					end
				end
			end)
			if ret then
				return unpack(ret)
			end
		end
	end
end
