require("mainloop")
do
 
	local function get_directory_contents(path)

		local path		= (path and path or "")
		local results	= love.filesystem.getDirectoryItems(path)

		return results

	end

	local selection		= nil
	local base_path		= "replays"
	local current_path	= "/"
	local path_contents	= {}
	local cursor_pos	= 0
	local filename		= nil

	local menu_y		= 100
	local menu_h		= 14

	local function replay_browser_menu()
		if current_path ~= "/" then
			gprint("< up >", 300, menu_y)
		else
			gprint("< root >", 300, menu_y)
		end

		for i,p in pairs(path_contents) do
			gprint(p, 300, menu_y + i * menu_h)
		end

		gprint(">", 284 + math.sin(love.timer.getTime() * 8) * 5, menu_y + cursor_pos * menu_h)
	end

	local function replay_browser_cursor(move)
		cursor_pos	= wrap(0, cursor_pos + move, #path_contents)
	end

	local function replay_browser_update(new_path)
		if new_path then
			cursor_pos	= 0
			if new_path == "" then
				new_path	= "/"
			end
			current_path	= new_path
		end
		path_contents	= get_directory_contents(base_path .. current_path)
	end

	local function replay_browser_go_up()
		replay_browser_update(current_path:gsub("(.*/).*/$","%1"))
	end


	local function replay_browser_load_details(path)

		filename	= path
		local file, error_msg	= love.filesystem.read(filename)

		if file == nil then
			print("Error loading replay: ".. error_msg)
			return false
		end

		replay = json.decode(file)
		if type(replay.in_buf) == "table" then
			replay.in_buf = table.concat(replay.in_buf)
		end
		return true

	end


	local function replay_browser_select()
		if cursor_pos == 0 then
			replay_browser_go_up()

		else
			local selection	= base_path .. current_path .. path_contents[cursor_pos]
			local file_info	= love.filesystem.getInfo(selection)
			if file_info then
				if file_info.type == "file" then
					return replay_browser_load_details(selection)
				elseif file_info.type == "directory" then
					replay_browser_update(current_path .. path_contents[cursor_pos] .."/")
				else
					print("i have no idea what a ".. file_info.type .." is!! ".. selection)
				end
			else
				print("not found (what!?) ".. selection)
			end
		end
	end



	function main_replay_browser()

		-- This is stupid and I hate it
		local k = K[1]
		local state	= "browser"
		replay_browser_update()

		while true do

			if state == "browser" then

				gprint("~ replay browser ~\n".. base_path .. current_path, 100, menu_y - 30)
				replay_browser_menu()

				if menu_up(k) then
					replay_browser_cursor(-1)
				end
				if menu_down(k) then
					replay_browser_cursor(1)
				end
				if menu_enter(k) then
					if replay_browser_select() then
						state	= "info"
					end
				end
				if menu_backspace(k) then
					replay_browser_go_up()
				end
				if menu_escape(k) then
					return main_select_mode
				end

			elseif state == "info" then
				gprint("~ replay information ~\n".. filename, 100, menu_y - 30)

				if replay.vs then
					gprint("2P Versus Replay", 100, menu_y + 20)

					gprint("1P", 100, menu_y + 50)
					gprint("Name: " .. replay.vs.P1_name, 100, menu_y + 65)
					gprint("Level: " .. replay.vs.P1_level, 100, menu_y + 80)
					gprint("Character: " .. replay.vs.P1_char, 100, menu_y + 95)

					gprint("2P", 400, menu_y + 50)
					gprint("Name: " .. replay.vs.P2_name, 400, menu_y + 65)
					gprint("Level: " .. replay.vs.P2_level, 400, menu_y + 80)
					gprint("Character: " .. replay.vs.P2_char, 400, menu_y + 95)

					if replay.vs.ranked then
						gprint("Ranked match", 250, menu_y + 120)
					end

					if menu_enter(k) then
						just_update_the_god_damn_buttons()
						return main_replay_vs
					end

				elseif replay.endless then
					gprint("1P Endless Replay", 100, menu_y + 20)

					gprint("Speed: " .. replay.endless.speed, 100, menu_y + 50)
					gprint("Difficulty: ", replay.endless.difficulty, 100, menu_y + 65)

					if menu_enter(k) then
						just_update_the_god_damn_buttons()
						return main_replay_endless
					end


				elseif replay.puzzle then
					gprint("1P Puzzle Replay", 100, menu_y + 20)

					gprint("No information available...", 100, menu_y + 50)

					if menu_enter(k) then
						just_update_the_god_damn_buttons()
						return main_replay_puzzle
					end


				else
					gprint("Unknown replay type -- sorry.", 100, menu_y + 20)

				end

				if menu_backspace(k) or menu_escape(k) then
					state	= "browser"
				end

			end

			-- Yes you have to call this AFTER the code to check buttons
			just_update_the_god_damn_buttons()
			coroutine.yield()

		end

	end


end