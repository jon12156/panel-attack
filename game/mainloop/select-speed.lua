function main_select_speed_99(next_func, ...)
	local difficulties = {"Easy", "Normal", "Hard"}
	local items = {{"Speed"},
								{"Difficulty"},
								{"Go!", next_func},
								{"Back", main_select_mode}}
	speed = config.endless_speed or 1
	difficulty = config.endless_difficulty or 1
	active_idx = 1
	local k = K[1]
	local ret = nil
	local next_func_args = {speed, difficulty, ...}
	while true do
		local to_print, to_print2, arrow = "", "", ""
		for i=1,#items do
			if active_idx == i then
				arrow = arrow .. ">"
			else
				arrow = arrow .. "\n"
			end
			to_print = to_print .. "   " .. items[i][1] .. "\n"
		end
		to_print2 = "                  " .. speed .. "\n                  "
			.. difficulties[difficulty]
		gprint(arrow, 300, 280)
		gprint(to_print, 300, 280)
		gprint(to_print2, 300, 280)
		coroutine.yield()
		variable_step(function()
			if menu_up(k) then
				active_idx = wrap(1, active_idx-1, #items)
			elseif menu_down(k) then
				active_idx = wrap(1, active_idx+1, #items)
			elseif menu_right(k) then
				if active_idx==1 then speed = bound(1,speed+1,99)
				elseif active_idx==2 then difficulty = bound(1,difficulty+1,3) end
			elseif menu_left(k) then
				if active_idx==1 then speed = bound(1,speed-1,99)
				elseif active_idx==2 then difficulty = bound(1,difficulty-1,3) end
			elseif menu_enter(k) then
				if active_idx == 3 then
					if config.endless_speed ~= speed or config.endless_difficulty ~= difficulty then
						config.endless_speed = speed
						config.endless_difficulty = difficulty
						gprint("saving settings...", 300,280)
						coroutine.yield()
						write_conf_file()
					end
					ret = {items[active_idx][2], next_func_args}
				elseif active_idx == 4 then
					ret = {items[active_idx][2], items[active_idx][3]}
				else
					active_idx = wrap(1, active_idx + 1, #items)
				end
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
