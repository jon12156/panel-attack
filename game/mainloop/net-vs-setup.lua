function main_net_vs_setup(ip)
	if not config.name then
		return main_set_name
		else my_name = config.name
	end
	P1, P1_level, P2_level, got_opponent = nil
	P2 = {panel_buffer="", gpanel_buffer=""}
	gprint("Setting up connection...", 300, 280)
	coroutine.yield()
	network_init(ip)
	local timeout_counter = 0
	while not connection_is_ready() do
		gprint("Connecting...", 300, 280)
		coroutine.yield()
		do_messages()
	end
	connected_server_ip = ip
	logged_in = false
	if true then return main_net_vs_lobby end
	local my_level, to_print, fake_P2 = 5, nil, P2
	local k = K[1]
	while got_opponent == nil do
		gprint("Waiting for opponent...", 300, 280)
		coroutine.yield()
		do_messages()
	end
	while P1_level == nil or P2_level == nil do
		to_print = (P1_level and "L" or"Choose l") .. "evel: "..my_level..
				"\nOpponent's level: "..(P2_level or "???")
		gprint(to_print, 300, 280)
		coroutine.yield()
		do_messages()
		variable_step(function()
			if P1_level then
			elseif menu_enter(k) then
				P1_level = my_level
				net_send("L"..(({[10]=0})[my_level] or my_level))
			elseif menu_up(k) or menu_right(k) then
				my_level = bound(1,my_level+1,10)
			elseif menu_down(k) or menu_left(k) then
				my_level = bound(1,my_level-1,10)
			end
		end)
	end
	P1 = Playfield(1, "vs", P1_level)
	P2 = Playfield(2, "vs", P2_level)
	if currently_spectating then
		P1.panel_buffer = fake_P1.panel_buffer
		P1.gpanel_buffer = fake_P1.gpanel_buffer
	end
	P2.panel_buffer = fake_P2.panel_buffer
	P2.gpanel_buffer = fake_P2.gpanel_buffer
	P1.garbage_target = P2
	P2.garbage_target = P1
	P2.pos_x = 172
	P2.score_x = 410
	replay.vs = {P="",O="",I="",Q="",R="",in_buf="",
							P1_level=P1_level,P2_level=P2_level,
							ranked=false, P1_name=my_name, P2_name=op_name,
							P1_char=P1.character, P2_char=P2.character,
							do_countdown = true}
	ask_for_gpanels("000000")
	ask_for_panels("000000")
	if not currently_spectating then
		to_print = "Level: "..my_level.."\nOpponent's level: "..(P2_level or "???")
	else
		to_print = "P1 Level: "..my_level.."\nP2 level: "..(P2_level or "???")
	end
	for i=1,30 do
		gprint(to_print,300, 280)
		do_messages()
		coroutine.yield()
	end
	while P1.panel_buffer == "" or P2.panel_buffer == ""
		or P1.gpanel_buffer == "" or P2.gpanel_buffer == "" do
		gprint(to_print,300, 280)
		do_messages()
		coroutine.yield()
	end
	P1:starting_state()
	P2:starting_state()
	return main_net_vs
end
