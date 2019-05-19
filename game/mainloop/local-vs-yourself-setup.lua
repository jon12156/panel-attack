function main_local_vs_yourself_setup()
	currently_spectating = false
	my_name = config.name or "Player 1"
	op_name = nil
	op_state = nil
	character_select_mode = "1p_vs_yourself"
	return main_character_select
end
