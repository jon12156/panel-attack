main_local_vs_setup = multi_func(function()
	local K = K
	local chosen, maybe = {}, {5,5}
	local P1_level, P2_level = nil, nil
	while chosen[1] == nil or chosen[2] == nil do
		to_print = (chosen[1] and "" or "Choose ") .. "P1 level: "..maybe[1].."\n"
				..(chosen[2] and "" or "Choose ") .. "P2 level: "..(maybe[2])
		gprint(to_print, 300, 280)
		coroutine.yield()
		variable_step(function()
			for i=1,2 do
				local k=K[i]
				if menu_escape(k) then
					if chosen[i] then
						chosen[i] = nil
					else
						return main_select_mode
					end
				elseif menu_enter(k) then
					chosen[i] = maybe[i]
				elseif menu_up(k) or menu_right(k) then
					if not chosen[i] then
						maybe[i] = bound(1,maybe[i]+1,10)
					end
				elseif menu_down(k) or menu_left(k) then
					if not chosen[i] then
						maybe[i] = bound(1,maybe[i]-1,10)
					end
				end
			end
		end)
	end
	to_print = "P1 level: "..maybe[1].."\nP2 level: "..(maybe[2])
	P1 = Playfield(1, "vs", chosen[1])
	P2 = Playfield(2, "vs", chosen[2])
	P1.garbage_target = P2
	P2.garbage_target = P1
	P2.pos_x = 172
	P2.score_x = 410
	-- TODO: this does not correctly implement starting configurations.
	-- Starting configurations should be identical for visible blocks, and
	-- they should not be completely flat.
	--
	-- In general the block-generation logic should be the same as the server's, so
	-- maybe there should be only one implementation.
	make_local_panels(P1, "000000")
	make_local_gpanels(P1, "000000")
	make_local_panels(P2, "000000")
	make_local_gpanels(P2, "000000")
	for i=1,30 do
		gprint(to_print,300, 280)
		coroutine.yield()
	end
	P1:starting_state()
	P2:starting_state()
	return main_local_vs
end)
