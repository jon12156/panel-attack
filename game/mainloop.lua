--local wait, resume = coroutine.yield, coroutine.resume

local main_select_mode, main_endless, make_main_puzzle, main_net_vs_setup,
	main_replay_endless, main_replay_puzzle, main_net_vs,
	main_config_input, main_dumb_transition, main_select_puzz,
	menu_up, menu_down, menu_left, menu_right, menu_enter, menu_escape, menu_backspace,
	main_replay_vs, main_local_vs_setup, main_local_vs, menu_key_func,
	multi_func, normal_key, main_set_name, main_character_select, main_net_vs_lobby,
	main_local_vs_yourself_setup, main_local_vs_yourself,
	main_options, exit_options_menu, main_music_test

VERSION = "037"
local PLAYING = "playing"  -- room states
local CHARACTERSELECT = "character select" --room states
local currently_spectating = false
connection_up_time = 0
logged_in = 0
connected_server_ip = nil
my_user_id = nil
leaderboard_report = nil
replay_of_match_so_far = nil
spectator_list = nil
spectators_string = ""
debug_mode_text = {[true]="On", [false]="Off"}
ready_countdown_1P_text = {[true]="On", [false]="Off"}
leftover_time = 0

require "game.mainloop._"
