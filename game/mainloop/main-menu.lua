
do
	local active_idx = 1
	function main_select_mode()
		love.audio.stop()
		currently_spectating = false
		stop_the_music()
		close_socket()
		logged_in = 0
		connection_up_time = 0
		connected_server_ip = ""
		current_server_supports_ranking = false
		match_type = ""
		match_type_message = ""
		local items = {
				{"1P endless", main_select_speed_99, {main_endless}},
				{"1P puzzle", main_select_puzz},
				{"1P time attack", main_select_speed_99, {main_time_attack}},
				{"1P vs yourself", main_local_vs_yourself_setup},
				{"2P vs online at Jon's server", main_net_vs_setup, {"18.188.43.50"}},
				{"2P vs local game", main_local_vs_setup},
				{"Replay of 1P endless", main_replay_endless},
				{"Replay of 1P puzzle", main_replay_puzzle},
				{"Replay of 2P vs", main_replay_vs},
				{"Configure input", main_config_input},
				{"Set name", main_set_name},
				{"Options", main_options},
				{"Music test", main_music_test},
				{"Replay Browser", main_replay_browser},
		}
		if love.graphics.getSupported("canvas") then
			items[#items+1] = {"Fullscreen (LAlt+Enter)", fullscreen}
		else
			items[#items+1] = {"Your graphics card doesn't support canvases for fullscreen", main_select_mode}
		end
		items[#items+1] = {"Quit", os.exit}
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
			gprint(arrow, 300, 280)
			gprint(to_print, 300, 280)
			coroutine.yield()
			local ret = nil
			variable_step(function()
				if menu_up(k) then
					active_idx = wrap(1, active_idx-1, #items)
				elseif menu_down(k) then
					active_idx = wrap(1, active_idx+1, #items)
				elseif menu_enter(k) then
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
