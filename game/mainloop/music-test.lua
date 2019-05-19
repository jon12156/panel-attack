function main_music_test()
	local index = 1
	local tracks = {}
	for k, v in pairs(sounds.music.characters) do
		tracks[#tracks+1] = {
			name = k .. "_normal",
			char = k,
			type = "normal_music",
			start = v.normal_music_start or zero_sound,
			loop = v.normal_music
		}
		tracks[#tracks+1] = {
			name = k .. "_danger",
			char = k,
			type = "danger_music",
			start = v.danger_music_start or zero_sound,
			loop = v.danger_music
		}
	end

	-- debug scroll to music
	while tracks[index].name ~= "yoshi_normal" do index = index + 1 end
	-- initial song starts here
	find_and_add_music(tracks[index].char, tracks[index].type)

	while true do
		tp =  "Currently playing: " .. tracks[index].name
		tp = tp .. (table.getn(currently_playing_tracks) == 1 and "\nPlaying the intro\n" or "\nPlaying main loop\n")
		min_time = math.huge
		for k, _ in pairs(music_t) do if k and k < min_time then min_time = k end end
		tp = tp .. string.format("%d", min_time - love.timer.getTime() )
		tp = tp .. "\n\n\n< and > to play navigate themes\nESC to leave"
		gprint(tp,300, 280)
		coroutine.yield()
		local ret = nil
		variable_step(function()
			if menu_left(K[1]) or menu_right(K[1]) or menu_escape(K[1]) then
				stop_the_music()
			end
			if menu_left(K[1]) then  index = index - 1 end
			if menu_right(K[1]) then index = index + 1 end
			if index > #tracks then index = 1 end
			if index < 1 then index = #tracks end
			if menu_left(K[1]) or menu_right(K[1]) then
				find_and_add_music(tracks[index].char, tracks[index].type)
			end
			if menu_escape(K[1]) then
				ret = {main_select_mode}
			end
		end)
		if ret then
			return unpack(ret)
		end
	end
end
