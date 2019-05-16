
local garbage_bounce_time = #garbage_bounce_table
local GARBAGE_DELAY = 60
local GARBAGE_TRANSIT_TIME = 90
local clone_pool = {}
local current_music_is_casual = false -- must be false so that casual music start playing

local d_col = {up=0, down=0, left=-1, right=1}
local d_row = {up=1, down=-1, left=0, right=0}

Playfield = class(function(s, which, mode, speed, difficulty, player_number)
		s.character = uniformly(characters)
		s.max_health = 1
		s.mode = mode or "endless"
		if mode ~= "puzzle" then
			s.do_first_row = true
		end
		if s.mode == "endless" then
				s.NCOLORS = difficulty_to_ncolors_endless[difficulty]
		end
		if s.mode == "time" then
				s.NCOLORS = difficulty_to_ncolors_1Ptime[difficulty]
		end

		if s.mode == "2ptime" or s.mode == "vs" then
			local level = speed or 5
			s.character = (type(difficulty) == "string") and difficulty or s.character
			s.level = level

			--difficulty			= level_to_difficulty[level]
			speed					= level_to_starting_speed[level]
			s.speed_times			= {15*60, idx=1, delta=15*60}
			s.max_health			= level_to_hang_time[level]
			s.FRAMECOUNT_HOVER		= level_to_hover[s.level]
			s.FRAMECOUNT_GPHOVER	= level_to_garbage_panel_hover[s.level]
			s.FRAMECOUNT_FLASH		= level_to_flash[s.level]
			s.FRAMECOUNT_FACE		= level_to_face[s.level]
			s.FRAMECOUNT_POP		= level_to_pop[s.level]
			s.combo_constant		= level_to_combo_constant[s.level]
			s.combo_coefficient		= level_to_combo_coefficient[s.level]
			s.chain_constant		= level_to_chain_constant[s.level]
			s.chain_coefficient		= level_to_chain_coefficient[s.level]

			if s.mode == "2ptime" then
				s.NCOLORS = level_to_ncolors_time[level]
			else
				s.NCOLORS = level_to_ncolors_vs[level]
			end
		end
		s.health = s.max_health

		s.garbage_cols = {{1,2,3,4,5,6,idx=1},
							{1,3,5,idx=1},
							{1,4,idx=1},
							{1,2,3,idx=1},
							{1,2,idx=1},
							{1,idx=1}}
		s.later_garbage = {}
		s.garbage_q = GarbageQueue()
		-- garbage_to_send[frame] is an array of garbage to send at frame.
		-- garbage_to_send.chain is an array of garbage to send when the chain ends.
		s.garbage_to_send = {}
		s.pos_x = 4   -- Position of the play area on the screen
		s.pos_y = 4
		s.score_x = 315
		s.panel_buffer = ""
		s.gpanel_buffer = ""
		s.input_buffer = ""
		s.panels = {}
		s.width = 6
		s.height = 12
		for i=0,s.height do
			s.panels[i] = {}
			for j=1,s.width do
				s.panels[i][j] = Panel()
			end
		end

		s.CLOCK = 0
		s.game_stopwatch = 0
		s.do_countdown = true
		s.max_runs_per_frame = 3

		s.displacement = 16
		-- This variable indicates how far below the top of the play
		-- area the top row of panels actually is.
		-- This variable being decremented causes the stack to rise.
		-- During the automatic rising routine, if this variable is 0,
		-- it's reset to 15, all the panels are moved up one row,
		-- and a new row is generated at the bottom.
		-- Only when the displacement is 0 are all 12 rows "in play."


		s.danger_col = {false,false,false,false,false,false}
		-- set true if this column is near the top
		s.danger_timer = 0   -- decides bounce frame when in danger

		s.difficulty = difficulty or 2

		s.speed = speed or 1   -- The player's speed level decides the amount of time
						 -- the stack takes to rise automatically
		if s.speed_times == nil then
			s.panels_to_speedup = panels_to_next_speed[s.speed]
		end
		s.rise_timer = 1   -- When this value reaches 0, the stack will rise a pixel
		s.rise_lock = false   -- If the stack is rise locked, it won't rise until it is
							-- unlocked.
		s.has_risen = false   -- set once the stack rises once during the game

		s.stop_time = 0
		s.pre_stop_time = 0

		s.NCOLORS = s.NCOLORS or 5
		s.score = 0         -- der skore
		s.chain_counter = 0   -- how high is the current chain?

		s.panels_in_top_row = false -- boolean, for losing the game
		s.danger = s.danger or false  -- boolean, panels in the top row (danger)
		s.danger_music = s.danger_music or false -- changes music state

		s.n_active_panels = 0
		s.prev_active_panels = 0
		s.n_chain_panels= 0

			 -- These change depending on the difficulty and speed levels:
		s.FRAMECOUNT_HOVER = s.FRAMECOUNT_HOVER or FC_HOVER[s.difficulty]
		s.FRAMECOUNT_FLASH = s.FRAMECOUNT_FLASH or FC_FLASH[s.difficulty]
		s.FRAMECOUNT_FACE  = s.FRAMECOUNT_FACE or FC_FACE[s.difficulty]
		s.FRAMECOUNT_POP   = s.FRAMECOUNT_POP or FC_POP[s.difficulty]
		s.FRAMECOUNT_MATCH = s.FRAMECOUNT_FACE + s.FRAMECOUNT_FLASH
		s.FRAMECOUNT_RISE  = speed_to_rise_time[s.speed]

		s.rise_timer = s.FRAMECOUNT_RISE

			 -- Player input stuff:
		s.manual_raise = false   -- set until raising is completed
		s.manual_raise_yet = false  -- if not set, no actual raising's been done yet
								 -- since manual raise button was pressed
		s.prevent_manual_raise = false
		s.swap_1 = false   -- attempt to initiate a swap on this frame
		s.swap_2 = false

		s.cur_wait_time = 25   -- number of ticks to wait before the cursor begins
							 -- to move quickly... it's based on P1CurSensitivity
		s.cur_timer = 0   -- number of ticks for which a new direction's been pressed
		s.cur_dir = nil     -- the direction pressed
		s.cur_row = 7  -- the row the cursor's on
		s.cur_col = 3  -- the column the left half of the cursor's on
		s.top_cur_row = s.height + (s.mode == "puzzle" and 0 or -1)

		s.move_sound = false  -- this is set if the cursor movement sound should be played
		s.poppedPanelIndex = s.poppedPanelIndex or 1
		s.panels_cleared = s.panels_cleared or 0
		s.metal_panels_queued = s.metal_panels_queued or 0
		s.lastPopLevelPlayed = s.lastPopLevelPlayed or 1
		s.lastPopIndexPlayed = s.lastPopIndexPlayed or 1
		s.game_over = false

		s.card_q = Queue()

		s.which = which or 1 -- Pk.which == k
		s.player_number = player_number or s.which --player number according to the multiplayer server, for game outcome reporting

		s.shake_time = 0

		s.prev_states = {}
	end)

function Playfield:mkcpy(other)
	if other == nil then
		if #clone_pool == 0 then
			other = {}
		else
			other = clone_pool[#clone_pool]
			clone_pool[#clone_pool] = nil
		end
	end
	other.do_swap = self.do_swap
	other.speed = self.speed
	other.health = self.health
	other.garbage_cols = deepcpy(self.garbage_cols)
	--[[if self.garbage_cols then
		other.garbage_idxs = other.garbage_idxs or {}
		local n_g_cols = #(self.garbage_cols or other.garbage_cols)
		for i=1,n_g_cols do
			other.garbage_idxs[i]=self.garbage_cols[i].idx
		end
	else

	end--]]
	other.garbage_q = deepcpy(self.garbage_q)
	other.garbage_to_send = deepcpy(self.garbage_to_send)
	other.input_state = self.input_state
	local height = self.height or other.height
	local width = self.width or other.width
	local height_to_cpy = #self.panels
	other.panels = other.panels or {}
	for i=1,height_to_cpy do
		if other.panels[i] == nil then
			other.panels[i] = {}
			for j=1,width do
				other.panels[i][j] = Panel()
			end
		end
		for j=1,width do
			local opanel = other.panels[i][j]
			local spanel = self.panels[i][j]
			opanel:clear()
			for k,v in pairs(spanel) do
				opanel[k] = v
			end
		end
	end
	for i=height_to_cpy+1,#other.panels do
		for j=1,width do
			other.panels[i][j]:clear()
		end
	end
	other.CLOCK = self.CLOCK
	other.game_stopwatch = self.game_stopwatch
	other.game_stopwatch_running = self.game_stopwatch_running
	other.cursor_lock = self.cursor_lock
	other.displacement = self.displacement
	other.speed_times = deepcpy(self.speed_times)
	other.panels_to_speedup = self.panels_to_speedup
	other.stop_time = self.stop_time
	other.pre_stop_time = self.pre_stop_time
	other.score = self.score
	other.chain_counter = self.chain_counter
	other.n_active_panels = self.n_active_panels
	other.prev_active_panels = self.prev_active_panels
	other.n_chain_panels = self.n_chain_panels
	other.FRAMECOUNT_RISE = self.FRAMECOUNT_RISE
	other.rise_timer = self.rise_timer
	other.manual_raise_yet = self.manual_raise_yet
	other.prevent_manual_raise = self.prevent_manual_raise
	other.cur_timer = self.cur_timer
	other.cur_dir = self.cur_dir
	other.cur_row = self.cur_row
	other.cur_col = self.cur_col
	other.shake_time = self.shake_time
	other.peak_shake_time = self.peak_shake_time
	other.card_q = deepcpy(self.card_q)
	other.do_countdown = self.do_countdown
	other.ready_y = self.ready_y
	return other
end

function Playfield:fromcpy(other)
	Playfield.mkcpy(other,self)
	self:remove_extra_rows()
end



-- ---------------------------------------------------------------------------
-- Engine
-- ---------------------------------------------------------------------------


function Playfield:set_puzzle_state(pstr, n_turns)
	-- Copy the puzzle into our state
	local sz = self.width * self.height
	while string.len(pstr) < sz do
		pstr = "0" .. pstr
	end
	local idx = 1
	local panels = self.panels
	for row=self.height,1,-1 do
		for col=1, self.width do
			panels[row][col]:clear()
			panels[row][col].color = string.sub(pstr, idx, idx) + 0
			idx = idx + 1
		end
	end
	self.puzzle_moves = n_turns
	stop_character_sounds(self.character)
end

function Playfield:puzzle_done()
	local panels = self.panels
	for row=1, self.height do
		for col=1, self.width do
			local color = panels[row][col].color
			if color ~= 0 and color ~= 9 then
				return false
			end
		end
	end
	return true
end

function Playfield:has_falling_garbage()
	for i=1,self.height+3 do --we shouldn't have to check quite 3 rows above height, but just to make sure...
		local prow = self.panels[i]
		for j=1,self.width do
			if prow and prow[j].garbage and prow[j].state == "falling" then
				return true
			end
		end
	end
	return false
end

function Playfield:prep_rollback()
	-- Do stuff for rollback.
	local prev_states = self.prev_states
	-- prev_states will not exist if we're doing a rollback right now
	if prev_states then
		local garbage_target = self.garbage_target
		self.garbage_target = nil
		self.prev_states = nil
		prev_states[self.CLOCK] = self:mkcpy()
		clone_pool[#clone_pool+1] = prev_states[self.CLOCK-400]
		prev_states[self.CLOCK-400] = nil
		self.prev_states = prev_states
		self.garbage_target = garbage_target
	end
end

function Playfield:starting_state(n)
	if self.do_first_row then
		self.do_first_row = nil
		for i=1,(n or 8) do
			self:new_row()
			self.cur_row = self.cur_row-1
		end
	end
	stop_character_sounds(self.character)
end

function Playfield:prep_first_row()
	if self.do_first_row then
		self.do_first_row = nil
		self:new_row()
		self.cur_row = self.cur_row-1
	end
end

--local_run is for the stack that belongs to this client.
function Playfield:local_run()
	self:update_cards()
	self.input_state = self:send_controls()
	self:prep_rollback()
	self:controls()
	self:prep_first_row()
	self:PdP()
end

--foreign_run is for a stack that belongs to another client.
function Playfield:foreign_run()
	local times_to_run = math.min(string.len(self.input_buffer),
			self.max_runs_per_frame)
	if self.play_to_end then
		if string.len(self.input_buffer) < 4 then
			self.play_to_end = nil
			stop_sounds = true
		end
	end
	for i=1,times_to_run do
		self:update_cards()
		self.input_state = string.sub(self.input_buffer,1,1)
		self:prep_rollback()
		self:controls()
		self:prep_first_row()
		self:PdP()
		self.input_buffer = string.sub(self.input_buffer,2)
	end
end

function Playfield:enqueue_card(chain, x, y, n)
	self.card_q:push({frame=1, chain=chain, x=x, y=y, n=n})
end




-- The engine routine.
function Playfield:PdP()

	local panels = self.panels
	local width = self.width
	local height = self.height
	local prow = nil
	local panel = nil
	local swapped_this_frame = nil
	self.game_stopwatch_running = true
	if self.do_countdown then
		self.game_stopwatch_running = nil
		self.rise_lock = true
		if not self.countdown_cursor_state then
			self.countdown_CLOCK = self.CLOCK
			self.starting_cur_row = self.cur_row
			self.starting_cur_col = self.cur_col
			self.cur_row = self.height
			self.cur_col = self.width-1
			self.countdown_cursor_state = "ready_falling"
			self.countdown_cur_speed = 4 --one move every this many frames
			self.cursor_lock = true
		end
		if self.countdown_CLOCK == 8 then
			self.countdown_cursor_state = "moving_down"
			self.countdown_timer = 180 --3 seconds at 60 fps
		elseif self.countdown_cursor_state == "moving_down" then
			--move down
			if self.cur_row == self.starting_cur_row then
				self.countdown_cursor_state = "moving_left"
			elseif self.CLOCK % self.countdown_cur_speed == 0 then
				self.cur_row = self.cur_row - 1
			end
		elseif self.countdown_cursor_state == "moving_left" then
			--move left
			if self.cur_col == self.starting_cur_col then
				self.countdown_cursor_state = "ready"
				self.cursor_lock = nil
			elseif self.CLOCK % self.countdown_cur_speed == 0 then
				self.cur_col = self.cur_col - 1
			end
		end
		if self.countdown_timer then
			if self.countdown_timer == 0 then
				--we are done counting down
				self.do_countdown = nil
				self.countdown_timer = nil
				self.starting_cur_row = nil
				self.starting_cur_col = nil
				self.countdown_CLOCK = nil
				if self.which == 1 then
					SFX_Go_Play=1
				end
			elseif self.countdown_timer and self.countdown_timer % 60 == 0 and self.which == 1 then
				--play beep for timer dropping to next second in 3-2-1 countdown
				if self.which == 1 then
					SFX_Countdown_Play=1
				end
			end
			if self.countdown_timer then
				self.countdown_timer = self.countdown_timer - 1
			end
		end
		if self.countdown_CLOCK then
			self.countdown_CLOCK = self.countdown_CLOCK + 1
		end
	end

	if self.pre_stop_time ~= 0 then
		self.pre_stop_time = self.pre_stop_time - 1
	elseif self.stop_time ~= 0 then
		self.stop_time = self.stop_time - 1
	end

	self.panels_in_top_row = false
	local top_row = self.height--self.displacement%16==0 and self.height or self.height-1
	prow = panels[top_row]
	for idx=1,width do
		if prow[idx]:dangerous() then
			self.panels_in_top_row = true
		end
	end

	-- calculate which columns should bounce
	local prev_danger = self.danger
	self.danger = false
	prow = panels[self.height-1]
	for idx=1,width do
		if prow[idx]:dangerous() then
			self.danger = true
			self.danger_col[idx] = true
		else
			self.danger_col[idx] = false
		end
	end
	if self.danger and self.stop_time == 0 then
		self.danger_timer = self.danger_timer - 1
		if self.danger_timer<0 then
			self.danger_timer=17
		end
	end

	-- determine whether to play danger music
		-- Changed this to play danger when something in top 3 rows
		-- and to play casual when nothing in top 3 rows
		if not self.danger_music then
				-- currently playing casual
				for _, prow in pairs({panels[self.height], panels[self.height-1], panels[self.height-2]}) do
						for idx=1, width do
								if prow[idx].color ~= 0 and prow[idx].state ~= "falling" or prow[idx]:dangerous() then
										self.danger_music = true
										break
								end
						end
				end
				if self.shake_time > 0 then self.danger_music = false end
		else
				--currently playing danger
				local toggle_back = true
				for _, prow in pairs({panels[self.height], panels[self.height-1], panels[self.height-1], panels[self.height-2]}) do
						for idx=1, width do
								if prow[idx].color ~= 0 then
										toggle_back = false
										break
								end
						end
				end
				self.danger_music = not toggle_back
		end




	if self.displacement == 0 and self.has_risen then
		self.top_cur_row = self.height
		self:new_row()
	end

	self.rise_lock = self.n_active_panels ~= 0 or
			self.prev_active_panels ~= 0 or
			self.shake_time ~= 0 or
			self.do_countdown or
			self.do_swap

	-- Increase the speed if applicable
	if self.speed_times then
		local time = self.speed_times[self.speed_times.idx]
		if self.CLOCK == time then
			self.speed = math.min(self.speed + 1, 99)
			if self.speed_times.idx ~= #self.speed_times then
				self.speed_times.idx = self.speed_times.idx + 1
			else
				self.speed_times[self.speed_times.idx] = time + self.speed_times.delta
			end
		end
	elseif self.panels_to_speedup <= 0 then
		self.speed = self.speed + 1
		self.panels_to_speedup = self.panels_to_speedup +
			panels_to_next_speed[self.speed]
		self.FRAMECOUNT_RISE = speed_to_rise_time[self.speed]
	end

	-- Phase 0 //////////////////////////////////////////////////////////////
	-- Stack automatic rising
	if self.speed ~= 0 and not self.manual_raise and self.stop_time == 0
			and not self.rise_lock and self.mode ~= "puzzle" then
		if self.panels_in_top_row then
			self.health = self.health - 1
			if self.health < 1 and self.shake_time < 1 then
				self.game_over = true
			end
		else
			self.rise_timer = self.rise_timer - 1
			if self.rise_timer <= 0 then  -- try to rise
				self.displacement = self.displacement - 1
				if self.displacement == 0 then
					self.prevent_manual_raise = false
					self.top_cur_row = self.height
					self:new_row()
				end
				self.rise_timer = self.rise_timer + self.FRAMECOUNT_RISE
			end
		end
	end

	if not self.panels_in_top_row then
		self.health = self.max_health
	end

	if self.displacement % 16 ~= 0 then
		self.top_cur_row = self.height - 1
	end

	-- Begin the swap we input last frame.
	if self.do_swap then
		self:swap()
		swapped_this_frame = true
		self.do_swap = nil
	end

	-- Look for matches.
	self:check_matches()
	-- Clean up the value we're using to match newly hovering panels
	-- This is pretty dirty :(
	for row=1,#panels do
		for col=1,width do
			panels[row][col].match_anyway = nil
		end
	end


	-- Phase 2. /////////////////////////////////////////////////////////////
	-- Timer-expiring actions + falling
	local propogate_fall = {false,false,false,false,false,false}
	local skip_col = 0
	local fallen_garbage = 0
	local shake_time = 0
	for row=1,#panels do
		for col=1,width do
			local cntinue = false
			if skip_col > 0 then
				skip_col = skip_col - 1
				cntinue=true
			end
			panel = panels[row][col]
			if cntinue then
			elseif panel.garbage then
				if panel.state == "matched" then
					panel.timer = panel.timer - 1
					if panel.timer == panel.pop_time then
					SFX_Garbage_Pop_Play = panel.pop_index
					end
					if panel.timer == 0 then
						if panel.y_offset == -1 then
							local color, chaining = panel.color, panel.chaining
							panel:clear()
							panel.color, panel.chaining = color, chaining
							self:set_hoverers(row, col, self.FRAMECOUNT_GPHOVER, true, true)
							panel.fell_from_garbage = 12
						else
							panel.state = "normal"
						end
					end
				-- try to fall
				elseif (panel.state=="normal" or panel.state=="falling") then
					if panel.x_offset==0 then
						local prow = panels[row-1]
						local supported = false
						if panel.y_offset == 0 then
							for i=col,col+panel.width-1 do
								supported = supported or prow[i]:support_garbage()
							end
						else
							supported = not propogate_fall[col]
						end
						if supported then
							for x=col,col-1+panel.width do
								panels[row][x].state = "normal"
								propogate_fall[x] = false
							end
						else
							skip_col = panel.width-1
							for x=col,col-1+panel.width do
								panels[row-1][x]:clear()
								propogate_fall[x] = true
								panels[row][x].state = "falling"
								panels[row-1][x], panels[row][x] =
									panels[row][x], panels[row-1][x]
							end
						end
					end
					if panel.shake_time and panel.state == "normal" then
						if row <= self.height then
							if panel.height > 3 then
								SFX_GarbageThud_Play = 3
							else SFX_GarbageThud_Play = panel.height
							end
							shake_time = math.max(shake_time, panel.shake_time, self.peak_shake_time or 0)
							--a smaller garbage block landing should renew the largest of the previous blocks' shake times since our shake time was last zero.
							self.peak_shake_time = math.max(shake_time, self.peak_shake_time or 0)
							panel.shake_time = nil
						end
					end
				end
				cntinue = true
			end
			if propogate_fall[col] and not cntinue then
				if panel:block_garbage_fall() then
					propogate_fall[col] = false
				else
					panel.state = "falling"
					panel.timer = 0
				end
			end
			if cntinue then
			elseif panel.state == "falling" then
				-- if it's on the bottom row, it should surely land
				if row == 1 then
					panel.state = "landing"
					panel.timer = 12
					SFX_Land_Play=1;

				-- if there's a panel below, this panel's gonna land
				-- unless the panel below is falling.
				elseif panels[row-1][col].color ~= 0 and
						panels[row-1][col].state ~= "falling" then
					-- if it lands on a hovering panel, it inherits
					-- that panel's hover time.
					if panels[row-1][col].state == "hovering" then
						panel.state = "normal"
						self:set_hoverers(row,col,panels[row-1][col].timer,false,false)
					else
						panel.state = "landing"
						panel.timer = 12
					end
					SFX_Land_Play=1;
				else
					panels[row-1][col], panels[row][col] =
						panels[row][col], panels[row-1][col]
					panels[row][col]:clear()
				end
			elseif panel:has_flags() and panel.timer~=0 then
				panel.timer = panel.timer - 1
				if panel.timer == 0 then
					if panel.state=="swapping" then
						-- a swap has completed here.
						panel.state = "normal"
						panel.dont_swap = nil
						local from_left = panel.is_swapping_from_left
						panel.is_swapping_from_left = nil
						-- Now there are a few cases where some hovering must
						-- be done.
						if panel.color ~= 0 then
							if row~=1 then
								if panels[row-1][col].color == 0 then
									self:set_hoverers(row,col,
											self.FRAMECOUNT_HOVER,false,true,false)
									-- if there is no panel beneath this panel
									-- it will begin to hover.
									-- CRAZY BUG EMULATION:
									-- the space it was swapping from hovers too
									if from_left then
										if panels[row][col-1].state == "falling" then
											self:set_hoverers(row,col-1,
													self.FRAMECOUNT_HOVER,false,true)
										end
									else
										if panels[row][col+1].state == "falling" then
											self:set_hoverers(row,col+1,
													self.FRAMECOUNT_HOVER+1,false,false)
										end
									end
								elseif panels[row-1][col].state
										== "hovering" then
									-- swap may have landed on a hover
									self:set_hoverers(row,col,
											self.FRAMECOUNT_HOVER,false,true,
											panels[row-1][col].match_anyway, "inherited")
								end
							end
						else
							-- an empty space finished swapping...
							-- panels above it hover
							self:set_hoverers(row+1,col,
									self.FRAMECOUNT_HOVER+1,false,false,false,"empty")
						end
					elseif panel.state == "hovering" then
						if panels[row-1][col].state == "hovering" then
							panel.timer = panels[row-1][col].timer
						-- This panel is no longer hovering.
						-- it will now fall without sitting around
						-- for any longer!
						elseif panels[row-1][col].color ~= 0 then
							panel.state = "landing"
							panel.timer = 12
						else
							panel.state = "falling"
							panels[row][col], panels[row-1][col] =
								panels[row-1][col], panels[row][col]
							panel.timer = 0
							-- Not sure if needed:
							panels[row][col]:clear_flags()
						end
					elseif panel.state == "landing" then
						panel.state = "normal"
					elseif panel.state == "matched" then
						-- This panel's match just finished the whole
						-- flashing and looking distressed thing.
						-- It is given a pop time based on its place
						-- in the match.
						panel.state = "popping"
						panel.timer = panel.combo_index*self.FRAMECOUNT_POP
					elseif panel.state == "popping" then
						self.score = self.score + 10;
						-- self.score_render=1;
						-- TODO: What is self.score_render?
						-- this panel just popped
						-- Now it's invisible, but sits and waits
						-- for the last panel in the combo to pop
						-- before actually being removed.

						-- If it is the last panel to pop,
						-- it should be removed immediately!
						if panel.combo_size == panel.combo_index then
							self.panels_cleared = self.panels_cleared + 1
							if self.mode == "vs" and self.panels_cleared % level_to_metal_panel_frequency[self.level] == 0 then
								self.metal_panels_queued = math.min(self.metal_panels_queued + 1, level_to_metal_panel_cap[self.level])
							end
							SFX_Pop_Play = 1
							self.poppedPanelIndex = panel.combo_index
							panel.color=0;
							if(panel.chaining) then
								self.n_chain_panels = self.n_chain_panels - 1
							end
							panel:clear_flags()
							self:set_hoverers(row+1,col,
									self.FRAMECOUNT_HOVER+1,true,false,true, "combo")
						else
							panel.state = "popped"
							panel.timer = (panel.combo_size-panel.combo_index)
									* self.FRAMECOUNT_POP
							self.panels_cleared = self.panels_cleared + 1
							if self.mode == "vs" and self.panels_cleared % level_to_metal_panel_frequency[self.level] == 0 then
								self.metal_panels_queued = math.min(self.metal_panels_queued + 1, level_to_metal_panel_cap[self.level])
							end
							SFX_Pop_Play = 1
							self.poppedPanelIndex = panel.combo_index
						end

					elseif panel.state == "popped" then
						-- It's time for this panel
						-- to be gone forever :'(
						if self.panels_to_speedup then
							self.panels_to_speedup = self.panels_to_speedup - 1
						end
						if panel.chaining then
							self.n_chain_panels = self.n_chain_panels - 1
						end
						panel.color = 0
						panel:clear_flags()
						-- Any panels sitting on top of it
						-- hover and are flagged as CHAINING
						self:set_hoverers(row+1,col,self.FRAMECOUNT_HOVER+1,true,false,true, "popped")
					else
						-- what the heck.
						-- if a timer runs out and the routine can't
						-- figure out what flag it is, tell brandon.
						-- No seriously, email him or something.
						error("something terrible happened")
					end
				-- the timer-expiring action has completed
				end
			end
			-- Advance the fell-from-garbage bounce timer, or clear it and stop animating if the panel isn't hovering or falling.
			if cntinue then
			elseif panel.fell_from_garbage then
				if panel.state ~= "hovering" and panel.state ~= "falling" then
					panel.fell_from_garbage = nil
				else
					panel.fell_from_garbage = panel.fell_from_garbage - 1
				end
			end
		end
	end

	local prev_shake_time = self.shake_time
	self.shake_time = self.shake_time - 1
	self.shake_time = math.max(self.shake_time, shake_time)
	if self.shake_time == 0 then
		self.peak_shake_time = 0
	end


	-- Phase 3. /////////////////////////////////////////////////////////////
	-- Actions performed according to player input

	-- CURSOR MOVEMENT
	self.move_sound = true
	if self.cur_dir and (self.cur_timer == 0 or
		self.cur_timer == self.cur_wait_time) and not self.cursor_lock then
		local prev_row = self.cur_row
		local prev_col = self.cur_col
		self.cur_row = bound(1, self.cur_row + d_row[self.cur_dir],
						self.top_cur_row)
		self.cur_col = bound(1, self.cur_col + d_col[self.cur_dir],
						width - 1)
		if(self.move_sound and
		(self.cur_timer == 0 or self.cur_timer == self.cur_wait_time) and
		(self.cur_row ~= prev_row or self.cur_col ~= prev_col))    then
				SFX_Cur_Move_Play=1
		end
	else
		self.cur_row = bound(1, self.cur_row, self.top_cur_row)
	end
	if self.cur_timer ~= self.cur_wait_time then
		self.cur_timer = self.cur_timer + 1


	end

	-- SWAPPING
	if (self.swap_1 or self.swap_2) and not swapped_this_frame then
		local row = self.cur_row
		local col = self.cur_col
		-- in order for a swap to occur, one of the two panels in
		-- the cursor must not be a non-panel.
		local do_swap = (panels[row][col].color ~= 0 or
							panels[row][col+1].color ~= 0) and
		-- also, both spaces must be swappable.
			(not panels[row][col]:exclude_swap()) and
			(not panels[row][col+1]:exclude_swap()) and
		-- also, neither space above us can be hovering.
			(self.cur_row == #panels or (panels[row+1][col].state ~=
				"hovering" and panels[row+1][col+1].state ~=
				"hovering")) and
		--also, we can't swap if the game countdown isn't finished
			not self.do_countdown and
		--also, don't swap on the first frame
			not (self.CLOCK and self.CLOCK <= 1)
		-- If you have two pieces stacked vertically, you can't move
		-- both of them to the right or left by swapping with empty space.
		-- TODO: This might be wrong if something lands on a swapping panel?
		if panels[row][col].color == 0 or panels[row][col+1].color == 0 then
			do_swap = do_swap and not (self.cur_row ~= self.height and
				(panels[row+1][col].state == "swapping" and
					panels[row+1][col+1].state == "swapping") and
				(panels[row+1][col].color == 0 or
					panels[row+1][col+1].color == 0) and
				(panels[row+1][col].color ~= 0 or
					panels[row+1][col+1].color ~= 0))
			do_swap = do_swap and not (self.cur_row ~= 1 and
				(panels[row-1][col].state == "swapping" and
					panels[row-1][col+1].state == "swapping") and
				(panels[row-1][col].color == 0 or
					panels[row-1][col+1].color == 0) and
				(panels[row-1][col].color ~= 0 or
					panels[row-1][col+1].color ~= 0))
		end

		do_swap = do_swap and (self.puzzle_moves == nil or self.puzzle_moves > 0)

		if do_swap then
			self.do_swap = true
		end
		self.swap_1 = false
		self.swap_2 = false
	end

	-- MANUAL STACK RAISING
	if self.manual_raise and self.mode ~= "puzzle" then
		if not self.rise_lock then
			if self.panels_in_top_row then
				self.game_over = true
			end
			self.has_risen = true
			self.displacement = self.displacement - 1
			if self.displacement == 1 then
				self.manual_raise = false
				self.rise_timer = 1
				if not self.prevent_manual_raise then
					self.score = self.score + 1
				end
				self.prevent_manual_raise = true
			end
			self.manual_raise_yet = true  --ehhhh
			self.stop_time = 0
		elseif not self.manual_raise_yet then
			self.manual_raise = false
		end
		-- if the stack is rise locked when you press the raise button,
		-- the raising is cancelled
	end

	-- if at the end of the routine there are no chain panels, the chain ends.
	if self.chain_counter ~= 0 and self.n_chain_panels == 0 then
		self:set_chain_garbage(self.chain_counter)
		SFX_Fanfare_Play = self.chain_counter
		self.chain_counter=0
	end

	if(self.score>99999) then
		self.score=99999
		-- lol owned
	end

	self.prev_active_panels = self.n_active_panels
	self.n_active_panels = 0
	for row=1,self.height do
		for col=1,self.width do
			local panel = panels[row][col]
			if (panel.garbage and panel.state ~= "normal") or
				 (panel.color ~= 0 and panel.state ~= "landing" and (panel:exclude_hover() or panel.state == "swapping") and not panel.garbage) or
					panel.state == "swapping" then
				self.n_active_panels = self.n_active_panels + 1
			end
		end
	end

	local to_send = self.garbage_to_send[self.CLOCK]
	if to_send then
		self.garbage_to_send[self.CLOCK] = nil

		-- if there's no chain, we can send it
		if self.chain_counter == 0 then
			if #to_send > 0 then
				--[[table.sort(to_send, function(a,b)
						if a[4] or b[4] then
							return a[4] and not b[4]
						elseif a[3] or b[3] then
							return b[3] and not a[3]
						else
							return a[1] < b[1]
						end
					end)--]]
				self:really_send(to_send)
			end
		elseif self.garbage_to_send.chain then
			local waiting_for_chain = self.garbage_to_send.chain
			for i=1,#to_send do
				waiting_for_chain[#waiting_for_chain+1] = to_send[i]
			end
		else
			self.garbage_to_send.chain = to_send
		end
	end

	self:remove_extra_rows()

	local garbage = self.later_garbage[self.CLOCK]
	if garbage then
		for i=1,#garbage do
			self.garbage_q:push(garbage[i])
		end
	end
	self.later_garbage[self.CLOCK-409] = nil

	--double-check panels_in_top_row
	self.panels_in_top_row = false
	local prow = panels[top_row]
	for idx=1,width do
		if prow[idx]:dangerous() then
			self.panels_in_top_row = true
		end
	end
	local garbage_fits_in_populated_top_row
	if self.garbage_q:len() > 0 then
		--even if there are some panels in the top row,
		--check if the next block in the garbage_q would fit anyway
		--ie. 3-wide garbage might fit if there are three empty spaces where it would spawn
		garbage_fits_in_populated_top_row = true
		local next_garbage_block_width, next_garbage_block_height, _metal, from_chain = unpack(self.garbage_q:peek())
		local cols = self.garbage_cols[next_garbage_block_width]
		local spawn_col = cols[cols.idx]
		local spawn_row = #self.panels
		for idx=spawn_col, spawn_col+next_garbage_block_width-1 do
			if prow[idx]:dangerous() then
				garbage_fits_in_populated_top_row = nil
			end
		end
		local drop_it =
			(not self.panels_in_top_row or garbage_fits_in_populated_top_row)
			and not self:has_falling_garbage()
			and (
				(from_chain and next_garbage_block_height > 1) or
				(self.n_active_panels == 0 and
				self.prev_active_panels == 0)
			)
		if drop_it and self.garbage_q:len() > 0 then
			self:drop_garbage(unpack(self.garbage_q:pop()))
		end
	end
	--Play Sounds / music
	if not music_mute and not (P1 and P1.play_to_end) and not (P2 and P2.play_to_end) then

		if self.do_countdown then
			if SFX_Go_Play == 1 then
				sounds.SFX.go:stop()
				sounds.SFX.go:play()
				SFX_Go_Play=0
			elseif SFX_Countdown_Play == 1 then
				sounds.SFX.countdown:stop()
				sounds.SFX.countdown:play()
				SFX_Go_Play=0
			end

		elseif (self.danger_music or (self.garbage_target and self.garbage_target.danger_music)) then --may have to rethink this bit if we do more than 2 players
			if (current_music_is_casual or table.getn(currently_playing_tracks) == 0) then
				print("Music is now critical")
				if table.getn(currently_playing_tracks) == 0 then print("There were no sounds playing") end
				stop_the_music()
				find_and_add_music(winningPlayer().character, "danger_music")
				current_music_is_casual = false
			end
		else --we should be playing normal_music or normal_music_start
			if (not current_music_is_casual or table.getn(currently_playing_tracks) == 0) then
				print("Music is now casual")
				if table.getn(currently_playing_tracks) == 0 then print("There were no sounds playing") end
				stop_the_music()
				find_and_add_music(winningPlayer().character, "normal_music")
				current_music_is_casual = true
			end
		end
	end
	if not SFX_mute and not (P1 and P1.play_to_end) and not (P2 and P2.play_to_end) then
		if SFX_Swap_Play == 1 then
				sounds.SFX.swap:stop()
				sounds.SFX.swap:play()
				SFX_Swap_Play=0
		end
		if SFX_Cur_Move_Play == 1 then
				if not (self.mode == "vs" and sounds.SFX.swap:isPlaying())
				and not self.do_countdown then
						sounds.SFX.cur_move:stop()
						sounds.SFX.cur_move:play()
				end
				SFX_Cur_Move_Play=0
		end
		if SFX_Land_Play == 1 then
				sounds.SFX.land:stop()
				sounds.SFX.land:play()
				SFX_Land_Play=0
		end
		if SFX_Countdown_Play == 1 then
				if self.which == 1 then
						sounds.SFX.countdown:stop()
						sounds.SFX.countdown:play()
				end
				SFX_Countdown_Play=0
		end
		if SFX_Go_Play == 1 then
				if self.which == 1 then
						sounds.SFX.go:stop()
						sounds.SFX.go:play()
				end
				SFX_Go_Play=0
		end
		if SFX_Buddy_Play and SFX_Buddy_Play ~= 0 then
				sounds.SFX.land:stop()
				sounds.SFX.pops[self.lastPopLevelPlayed][self.lastPopIndexPlayed]:stop()
				sounds.SFX.characters[self.character]["chain"]:stop()
				sounds.SFX.characters[self.character]["combo"]:stop()
				sounds.SFX.characters[self.character]["chain2"]:stop()
				sounds.SFX.characters[self.character]["chain_echo"]:stop()
				sounds.SFX.characters[self.character]["chain2_echo"]:stop()
				if sounds.SFX.characters[self.character][SFX_Buddy_Play] then
					sounds.SFX.characters[self.character][SFX_Buddy_Play]:play()
				end
				SFX_Buddy_Play=0
		end
		if SFX_garbage_match_play then
			if sounds.SFX.characters[self.character]["garbage_match"] then
				sounds.SFX.characters[self.character]["garbage_match"]:stop()
				sounds.SFX.characters[self.character]["garbage_match"]:play()
			end
			SFX_garbage_match_play = nil
		end
		if SFX_Fanfare_Play == 0 then
		--do nothing
		elseif SFX_Fanfare_Play >= 6 then
				sounds.SFX.pops[self.lastPopLevelPlayed][self.lastPopIndexPlayed]:stop()
				sounds.SFX.fanfare3:play()
		elseif SFX_Fanfare_Play >= 5 then
				sounds.SFX.pops[self.lastPopLevelPlayed][self.lastPopIndexPlayed]:stop()
				sounds.SFX.fanfare2:play()
		elseif SFX_Fanfare_Play >= 4 then
				sounds.SFX.pops[self.lastPopLevelPlayed][self.lastPopIndexPlayed]:stop()
				sounds.SFX.fanfare1:play()
		end
		SFX_Fanfare_Play=0
		if SFX_GarbageThud_Play >= 1 and SFX_GarbageThud_Play <= 3 then
				local interrupted_thud = nil
				for i=1,3 do
						if sounds.SFX.garbage_thud[i]:isPlaying() and self.shake_time > prev_shake_time then
								sounds.SFX.garbage_thud[i]:stop()
								interrupted_thud = i
						end
				end
				if interrupted_thud and interrupted_thud > SFX_GarbageThud_Play then
						sounds.SFX.garbage_thud[interrupted_thud]:play()
				else sounds.SFX.garbage_thud[SFX_GarbageThud_Play]:play()
				end
				SFX_GarbageThud_Play = 0
		end
		if SFX_Pop_Play or SFX_Garbage_Pop_Play then
				local popLevel = math.min(math.max(self.chain_counter,1),4)
				local popIndex = 1
				if SFX_Garbage_Pop_Play then
						popIndex = SFX_Garbage_Pop_Play
				else
						popIndex = math.min(self.poppedPanelIndex,10)
				end
				--stop the previous pop sound
				sounds.SFX.pops[self.lastPopLevelPlayed][self.lastPopIndexPlayed]:stop()
				--play the appropriate pop sound
				sounds.SFX.pops[popLevel][popIndex]:play()
				self.lastPopLevelPlayed = popLevel
				self.lastPopIndexPlayed = popIndex
				SFX_Pop_Play = nil
				SFX_Garbage_Pop_Play = nil
		end
		if stop_sounds then
			love.audio.stop()
			stop_the_music()
			stop_sounds = nil
		end
		if self.game_over or (self.garbage_target and self.garbage_target.game_over) then
				SFX_GameOver_Play = 1
		end
	end

	self.CLOCK = self.CLOCK + 1
	if self.game_stopwatch_running then
		self.game_stopwatch = (self.game_stopwatch or -1) + 1
	end
end



function Playfield:swap()
	local panels = self.panels
	local row = self.cur_row
	local col = self.cur_col
	if self.puzzle_moves then
		self.puzzle_moves = self.puzzle_moves - 1
	end
	panels[row][col], panels[row][col+1] =
		panels[row][col+1], panels[row][col]
	local tmp_chaining = panels[row][col].chaining
	panels[row][col]:clear_flags()
	panels[row][col].state = "swapping"
	panels[row][col].chaining = tmp_chaining
	tmp_chaining = panels[row][col+1].chaining
	panels[row][col+1]:clear_flags()
	panels[row][col+1].state = "swapping"
	panels[row][col+1].is_swapping_from_left = true
	panels[row][col+1].chaining = tmp_chaining

	panels[row][col].timer = 4
	panels[row][col+1].timer = 4

	SFX_Swap_Play=1;

	-- If you're swapping a panel into a position
	-- above an empty space or above a falling piece
	-- then you can't take it back since it will start falling.
	if self.cur_row ~= 1 then
		if (panels[row][col].color ~= 0) and (panels[row-1][col].color
				== 0 or panels[row-1][col].state == "falling") then
			panels[row][col].dont_swap = true
		end
		if (panels[row][col+1].color ~= 0) and (panels[row-1][col+1].color
				== 0 or panels[row-1][col+1].state == "falling") then
			panels[row][col+1].dont_swap = true
		end
	end

	-- If you're swapping a blank space under a panel,
	-- then you can't swap it back since the panel should
	-- start falling.
	if self.cur_row ~= self.height then
		if panels[row][col].color == 0 and
				panels[row+1][col].color ~= 0 then
			panels[row][col].dont_swap = true
		end
		if panels[row][col+1].color == 0 and
				panels[row+1][col+1].color ~= 0 then
			panels[row][col+1].dont_swap = true
		end
	end
end

function Playfield:remove_extra_rows()
	local panels = self.panels
	local width = self.width
	for row=#panels,self.height+1,-1 do
		local nonempty = false
		local prow = panels[row]
		for col=1,width do
			nonempty = nonempty or (prow[col].color ~= 0)
		end
		if nonempty then
			break
		else
			panels[row]=nil
		end
	end
end

-- drops a width x height garbage.
function Playfield:drop_garbage(width, height, metal)
	local spawn_row = #self.panels
	for i=#self.panels+1,#self.panels+height+1 do
		self.panels[i] = {}
		for j=1,self.width do
			self.panels[i][j] = Panel()
		end
	end
	local cols = self.garbage_cols[width]
	local spawn_col = cols[cols.idx]
	cols.idx = wrap(1, cols.idx+1, #cols)
	local shake_time = garbage_to_shake_time[width * height]
	for y=spawn_row,spawn_row+height-1 do
		for x=spawn_col,spawn_col+width-1 do
			local panel = self.panels[y][x]
			panel.garbage = true
			panel.color = 9
			panel.width = width
			panel.height = height
			panel.y_offset = y-spawn_row
			panel.x_offset = x-spawn_col
			panel.shake_time = shake_time
			panel.state = "falling"
			if metal then
				panel.metal = metal
			end
		end
	end
end

-- prepare to send some garbage!
-- also, delay any combo garbage that wasn't sent out yet
-- and set it to be sent at the same time as this garbage.
function Playfield:set_combo_garbage(n_combo, n_metal)
	local stuff_to_send = {}
	for i=3,n_metal do
		stuff_to_send[#stuff_to_send+1] = {6, 1, true, false}
	end
	local combo_pieces = combo_garbage[n_combo]
	for i=1,#combo_pieces do
		stuff_to_send[#stuff_to_send+1] = {combo_pieces[i], 1, false, false}
	end
	for k,v in pairs(self.garbage_to_send) do
		if type(k) == "number" then
			for i=1,#v do
				stuff_to_send[#stuff_to_send+1] = v[i]
			end
			self.garbage_to_send[k]=nil
		end
	end
	self.garbage_to_send[self.CLOCK + GARBAGE_TRANSIT_TIME] = stuff_to_send
end

-- the chain is over!
-- let's send it and the stuff waiting on it.
function Playfield:set_chain_garbage(n_chain)
	local tab = self.garbage_to_send[self.CLOCK]
	if not tab then
		tab = {}
		self.garbage_to_send[self.CLOCK] = tab
	end
	local to_add = self.garbage_to_send.chain
	if to_add then
		for i=1,#to_add do
			tab[#tab+1] = to_add[i]
		end
		self.garbage_to_send.chain = nil
	end
	tab[#tab+1] = {6, n_chain-1, false, true}
end

function Playfield:really_send(to_send)
	if self.garbage_target then
		self.garbage_target:recv_garbage(self.CLOCK + GARBAGE_DELAY, to_send)
	end
end

function Playfield:recv_garbage(time, to_recv)
	if self.CLOCK > time then
		local prev_states = self.prev_states
		local next_self = prev_states[time+1]
		while next_self and (next_self.prev_active_panels ~= 0 or
				next_self.n_active_panels ~= 0) do
			time = time + 1
			next_self = prev_states[time+1]
		end
		if self.CLOCK - time > 200 then
			error("Latency is too high :(")
		else
			local CLOCK = self.CLOCK
			local old_self = prev_states[time]
			--MAGICAL ROLLBACK!?!?
			self.in_rollback = true
			print("attempting magical rollback with difference = "..self.CLOCK-time..
					" at time "..self.CLOCK)

			-- The garbage that we send this time might (rarely) not be the same
			-- as the garbage we sent before.  Wipe out the garbage we sent before...
			local first_wipe_time = time + GARBAGE_DELAY
			local other_later_garbage = self.garbage_target.later_garbage
			for k,v in pairs(other_later_garbage) do
				if k >= first_wipe_time then
					other_later_garbage[k] = nil
				end
			end
			-- and record the garbage that we send this time!

			-- We can do it like this because the sender of the garbage
			-- and self.garbage_target are the same thing.
			-- Since we're in this code at all, we know that self.garbage_target
			-- is waaaaay behind us, so it couldn't possibly have processed
			-- the garbage that we sent during the frames we're rolling back.
			--
			-- If a mode with >2 players is implemented, we can continue doing
			-- the same thing as long as we keep all of the opponents'
			-- stacks in sync.

			self:fromcpy(prev_states[time])
			self:recv_garbage(time, to_recv)

			for t=time,CLOCK-1 do
				self.input_state = prev_states[t].input_state
				self:mkcpy(prev_states[t])
				self:controls()
				self:PdP()
			end
			self.in_rollback = nil
		end
	end
	local garbage = self.later_garbage[time] or {}
	for i=1,#to_recv do
		garbage[#garbage+1] = to_recv[i]
	end
	self.later_garbage[time] = garbage
end

function Playfield:check_matches()
	local row = 0
	local col = 0
	local count = 0
	local old_color = 0
	local is_chain = false
	local first_panel_row = 0
	local first_panel_col = 0
	local combo_index, garbage_index = 0, 0
	local combo_size, garbage_size = 0, 0
	local something = 0
	local whatever = 0
	local panels = self.panels
	local q, garbage = Queue(), {}
	local seen, seenm = {}, {}
	local metal_count = 0

	for col=1,self.width do
		for row=1,self.height do
			panels[row][col].matching = nil
		end
	end

	for row=1,self.height do
		for col=1,self.width do
			if row~=1 and row~=self.height and
				--check vertical match centered here.
				(not (panels[row-1][col]:exclude_match() or
										panels[row][col]:exclude_match() or
										panels[row+1][col]:exclude_match()))
							and panels[row][col].color ==
									panels[row-1][col].color
							and panels[row][col].color ==
									panels[row+1][col].color then
				for m_row = row-1, row+1 do
					local panel = panels[m_row][col]
					if not panel.matching then
						combo_size = combo_size + 1
						panel.matching = true
					end
					if panel.match_anyway and panel.chaining then
						panel.chaining = nil
						self.n_chain_panels = self.n_chain_panels - 1
					end
					is_chain = is_chain or panel.chaining
				end
				q:push({row,col,true,true})
			end
			if col~=1 and col~=self.width and
				--check horiz match centered here.
				(not (panels[row][col-1]:exclude_match() or
										panels[row][col]:exclude_match() or
										panels[row][col+1]:exclude_match()))
							and panels[row][col].color ==
									panels[row][col-1].color
							and panels[row][col].color ==
									panels[row][col+1].color then
				for m_col = col-1, col+1 do
					local panel = panels[row][m_col]
					if not panel.matching then
						combo_size = combo_size + 1
						panel.matching = true
					end
					if panel.match_anyway and panel.chaining then
						panel.chaining = nil
						self.n_chain_panels = self.n_chain_panels - 1
					end
					is_chain = is_chain or panel.chaining
				end
				q:push({row,col,true,true})
			end
		end
	end

	-- This is basically two flood fills at the same time.
	-- One for clearing normal garbage, one for metal.
	while q:len() ~= 0 do
		local y,x,normal,metal = unpack(q:pop())
		local panel = panels[y][x]
		if ((panel.garbage and panel.state=="normal") or panel.matching)
				and ((normal and not seen[panel]) or
						 (metal and not seenm[panel])) then
			if ((metal and panel.metal) or (normal and not panel.metal))
				and panel.garbage and not garbage[panel] then
				garbage[panel] = true
				SFX_garbage_match_play = true
				if y <= self.height then
					garbage_size = garbage_size + 1
				end
			end
			seen[panel] = seen[panel] or normal
			seenm[panel] = seenm[panel] or metal
			if panel.garbage then
				normal = normal and not panel.metal
				metal = metal and panel.metal
			end
			if normal or metal then
				if y~=1 then q:push({y-1, x, normal, metal}) end
				if y~=#panels then q:push({y+1, x, normal, metal}) end
				if x~=1 then q:push({y, x-1, normal, metal}) end
				if x~=self.width then q:push({y,x+1, normal, metal}) end
			end
		end
	end

	if is_chain then
		if self.chain_counter ~= 0 then
			self.chain_counter = self.chain_counter + 1
		else
			self.chain_counter = 2
		end
	end

	local pre_stop_time = self.FRAMECOUNT_MATCH +
			self.FRAMECOUNT_POP * (combo_size + garbage_size)
	local garbage_match_time = self.FRAMECOUNT_MATCH +
			self.FRAMECOUNT_POP * (combo_size + garbage_size)
	garbage_index=garbage_size-1
	combo_index=combo_size
	for row=1,#panels do
		local gpan_row = nil
		for col=self.width,1,-1 do
			local panel = panels[row][col]
			if garbage[panel] then
				panel.state = "matched"
				panel.timer = garbage_match_time + 1
				panel.initial_time = garbage_match_time
				panel.pop_time = self.FRAMECOUNT_POP * garbage_index
				panel.pop_index = math.min(math.max(garbage_size - garbage_index,1),10)
				panel.y_offset = panel.y_offset - 1
				panel.height = panel.height - 1
				if panel.y_offset == -1 then
					if gpan_row == nil then
						gpan_row = string.sub(self.gpanel_buffer, 1, 6)
						self.gpanel_buffer = string.sub(self.gpanel_buffer,7)
						if string.len(self.gpanel_buffer) <= 10*self.width then
							ask_for_gpanels(string.sub(self.panel_buffer,-6), self)
						end
					end
					panel.color = string.sub(gpan_row, col, col) + 0
					if is_chain then
						panel.chaining = true
						self.n_chain_panels = self.n_chain_panels + 1
					end
				end
				garbage_index = garbage_index - 1
			elseif row <= self.height then
				if panel.matching then
					if panel.color == 8 then
						metal_count = metal_count + 1
					end
					panel.state = "matched"
					panel.timer = self.FRAMECOUNT_MATCH + 1
					if is_chain and not panel.chaining then
						panel.chaining = true
						self.n_chain_panels = self.n_chain_panels + 1
					end
					panel.combo_index = combo_index
					panel.combo_size = combo_size
					panel.chain_index = self.chain_counter
					combo_index = combo_index - 1
					if combo_index == 0 then
						first_panel_col = col
						first_panel_row = row
					end
				else
					-- if a panel wasn't matched but was eligible,
					-- we might have to remove its chain flag...!
					-- It can't actually chain the first frame it hovers,
					-- so it can keep its chaining flag in that case.
					if not (panel.match_anyway or panel:exclude_match()) then
						if row~=1 then
							-- no swapping panel below
							-- so this panel loses its chain flag
							if panels[row-1][col].state ~= "swapping" and
									panel.chaining then
							--if panel.chaining then
								panel.chaining = nil
								self.n_chain_panels = self.n_chain_panels - 1
							end
						-- a panel landed on the bottom row, so it surely
						-- loses its chain flag.
						elseif(panel.chaining) then
							panel.chaining = nil
							self.n_chain_panels = self.n_chain_panels - 1
						end
					end
				end
			end
		end
	end

	if(combo_size~=0) then
		if(combo_size>3) then
			if(score_mode == SCOREMODE_TA) then
				if(combo_size > 30) then
					combo_size = 30
				end
				self.score = self.score + score_combo_TA[combo_size]
			elseif(score_mode == SCOREMODE_PDP64) then
				if(combo_size<41) then
					self.score = self.score + score_combo_PdP64[combo_size]
				else
					self.score = self.score + 20400+((combo_size-40)*800)
				end
			end

			self:enqueue_card(false, first_panel_col, first_panel_row, combo_size)
			--EnqueueConfetti(first_panel_col<<4+P1StackPosX+4,
			--          first_panel_row<<4+P1StackPosY+self.displacement-9);
			--TODO: this stuff ^
			first_panel_row = first_panel_row + 1 -- offset chain cards
		end
		if(is_chain) then
			self:enqueue_card(true, first_panel_col, first_panel_row,
					self.chain_counter)
			--EnqueueConfetti(first_panel_col<<4+P1StackPosX+4,
			--          first_panel_row<<4+P1StackPosY+self.displacement-9);
		end
		something = self.chain_counter
		if(score_mode == SCOREMODE_TA) then
			if(self.chain_counter>13) then
				something=0
			end
			self.score = self.score + score_chain_TA[something]
		end
		if((combo_size>3) or is_chain) then
			local stop_time
			if self.panels_in_top_row and is_chain then
				if self.level then
					local length = (self.chain_counter > 4) and 6 or self.chain_counter
					stop_time = -8 * self.level + 168 +
											(self.chain_counter - 1) * (-2*self.level+22)
				else
					stop_time = stop_time_danger[self.difficulty]
				end
			elseif self.panels_in_top_row then
				if self.level then
					local length = (combo_size < 9) and 2 or 3
					stop_time = self.chain_coefficient * length + self.chain_constant
				else
					stop_time = stop_time_danger[self.difficulty]
				end
			elseif is_chain then
				if self.level then
					local length = math.min(self.chain_counter, 13)
					stop_time = self.chain_coefficient * length + self.chain_constant
				else
					stop_time = stop_time_chain[self.difficulty]
				end
			else
				if self.level then
					stop_time = self.combo_coefficient * combo_size + self.combo_constant
				else
					stop_time = stop_time_combo[self.difficulty]
				end
			end
			self.stop_time = math.max(self.stop_time, stop_time)
			self.pre_stop_time = math.max(self.pre_stop_time, pre_stop_time)
			--MrStopState=1;
			--MrStopTimer=MrStopAni[self.stop_time];
			--TODO: Mr Stop ^
			-- @CardsOfTheHeart says there are 4 chain sfx: --x2/x3, --x4, --x5 is x2/x3 with an echo effect, --x6+ is x4 with an echo effect
			if is_chain then
				local length = math.min(self.chain_counter, 13)
				if length < 4 then
					SFX_Buddy_Play = "chain"
				elseif length == 4 then
					SFX_Buddy_Play = "chain2"
				elseif length == 5 then
					SFX_Buddy_Play = "chain_echo"
				elseif length >= 6 then
					SFX_Buddy_Play = "chain2_echo"
				end
			elseif combo_size > 3 then
				SFX_Buddy_Play = "combo"
			end
			SFX_Land_Play=0
		end
		--if garbage_size > 0 then
			self.pre_stop_time = math.max(self.pre_stop_time, pre_stop_time)
		--end

		self.manual_raise=false
		--self.score_render=1;
		--Nope.
		if metal_count > 5 then
			SFX_Buddy_Play = "combo_echo"
		elseif metal_count > 2 then
			SFX_Buddy_Play = "combo"
		end
		self:set_combo_garbage(combo_size, metal_count)
	end
end

function Playfield:set_hoverers(row, col, hover_time, add_chaining,
		extra_tick, match_anyway, debug_tag)
	assert(type(match_anyway) ~= "string")
	-- the extra_tick flag is for use during Phase 1&2,
	-- when panels above the first should be given an extra tick of hover time.
	-- This is because their timers will be decremented once on the same tick
	-- they are set, as Phase 1&2 iterates backward through the stack.
	local not_first = 0   -- if 1, the current panel isn't the first one
	local hovers_time = hover_time
	local brk = row > #self.panels
	local panels = self.panels
	while not brk do
		local panel = panels[row][col]
		if panel.color == 0 or panel:exclude_hover() or
			panel.state == "hovering" and panel.timer <= hover_time then
			brk = true
		else
			if panel.state == "swapping" then
				hovers_time = hovers_time + panels[row][col].timer - 1
			else
				local chaining = panel.chaining
				panel:clear_flags()
				panel.state = "hovering"
				panel.match_anyway = match_anyway
				panel.debug_tag = debug_tag
				local adding_chaining = (not chaining) and panel.color~=9 and
						add_chaining
				if chaining or adding_chaining then
					panel.chaining = true
				end
				panel.timer = hovers_time
				if extra_tick then
					panel.timer = panel.timer + not_first
				end
				if adding_chaining then
					self.n_chain_panels = self.n_chain_panels + 1
				end
			end
			not_first = 1
		end
		row = row + 1
		brk = brk or row > #self.panels
	end
end

function Playfield:new_row()
	local panels = self.panels
	-- move cursor up
	self.cur_row = bound(1, self.cur_row + 1, self.top_cur_row)
	-- move panels up
	for row=#panels+1,1,-1 do
		panels[row] = panels[row-1]
	end
	panels[0]={}
	-- put bottom row into play
	for col=1,self.width do
		panels[1][col].state = "normal"
	end

	if string.len(self.panel_buffer) < self.width then
		error("Ran out of buffered panels.  Is the server down?")
	end
	-- generate a new row
	local metal_panels_this_row = 0
	if self.metal_panels_queued > 3 then
		self.metal_panels_queued = self.metal_panels_queued - 2
		metal_panels_this_row = 2
	elseif self.metal_panels_queued > 0 then
		self.metal_panels_queued = self.metal_panels_queued - 1
		metal_panels_this_row = 1
	end
	for col=1,self.width do
		local panel = Panel()
		panels[0][col] = panel
		this_panel_color = string.sub(self.panel_buffer,col,col)
		--a capital letter for the place where the first shock block should spawn (if earned), and a lower case letter is where a second should spawn (if earned).  (color 8 is metal)
		if tonumber(this_panel_color) then
			--do nothing special
		elseif this_panel_color >= "A" and this_panel_color <= "Z" then
			if metal_panels_this_row > 0 then
				this_panel_color = 8
			else
				this_panel_color = panel_color_to_number[this_panel_color]
			end
		elseif this_panel_color >= "a" and this_panel_color <= "z" then
			if metal_panels_this_row > 1 then
				this_panel_color = 8
			else
				this_panel_color = panel_color_to_number[this_panel_color]
			end
		end
		panel.color = this_panel_color+0
		panel.state = "dimmed"
	end
	self.panel_buffer = string.sub(self.panel_buffer,7)
	if string.len(self.panel_buffer) <= 10*self.width then
		ask_for_panels(string.sub(self.panel_buffer,-6), self)
	end
	self.displacement = 16
end

-- ---------------------------------------------------------------------------
-- Graphics
-- ---------------------------------------------------------------------------


function Playfield:render_cursor()
	local shake_idx = #shake_arr - self.shake_time
	local shake = math.ceil((shake_arr[shake_idx] or 0) * 13)
	if self.countdown_timer then
		if self.CLOCK % 2 == 0 then
			draw(IMG_cursor[1],
				(self.cur_col-1)*16+self.pos_x-4,
				(11-(self.cur_row))*16+self.pos_y-4+self.displacement-shake)
		end
	else
		draw(IMG_cursor[(math.floor(self.CLOCK/16)%2)+1],
			(self.cur_col-1)*16+self.pos_x-4,
			(11-(self.cur_row))*16+self.pos_y-4+self.displacement-shake)
	end
end

function Playfield:render_countdown()
	if self.do_countdown and self.countdown_CLOCK then
		local ready_x = self.pos_x + 12
		local initial_ready_y = self.pos_y
		local ready_y_drop_speed = 6
		local countdown_x = self.pos_x + 40
		local countdown_y = self.pos_y + 64
		if self.countdown_CLOCK <= 8 then
			local ready_y = initial_ready_y + (self.CLOCK - 1) * ready_y_drop_speed
			draw(IMG_ready, ready_x, ready_y)
			if self.countdown_CLOCK == 8 then
				self.ready_y = ready_y
			end
		elseif self.countdown_CLOCK >= 9 and self.countdown_timer and self.countdown_timer > 0 then
			if self.countdown_timer >= 100 then
				draw(IMG_ready, ready_x, self.ready_y or initial_ready_y + 8 * 6)
			end
			local IMG_number_to_draw = IMG_numbers[math.ceil(self.countdown_timer / 60)]
			if IMG_number_to_draw then
				draw(IMG_number_to_draw, countdown_x, countdown_y)
			end
		end
	end
end


function Playfield:update_cards()
	for i=self.card_q.first,self.card_q.last do
		local card = self.card_q[i]
		if card_animation[card.frame] then
			card.frame = card.frame + 1
			if(card_animation[card.frame]==nil) then
				self.card_q:pop()
			end
		else
			card.frame = card.frame + 1
		end
	end
end

function Playfield:draw_cards()
	for i=self.card_q.first,self.card_q.last do
		local card = self.card_q[i]
		if card_animation[card.frame] then
			local draw_x = (card.x-1) * 16 + self.pos_x
			local draw_y = (11-card.y) * 16 + self.pos_y + self.displacement
					- card_animation[card.frame]
			draw(IMG_cards[card.chain][card.n], draw_x, draw_y)
		end
	end
end

function Playfield:render()
	local mx,my
	if config.debug_mode then
		mx,my = love.mouse.getPosition()
		mx = mx / GFX_SCALE
		my = my / GFX_SCALE
	end
	local portrait_w, portrait_h = IMG_garbage[self.character].portrait:getDimensions()
	if P1 == self then
		draw(IMG_garbage[self.character].portrait, self.pos_x, self.pos_y, 0, 96/portrait_w, 192/portrait_h)
	else
		draw(IMG_garbage[self.character].portrait, self.pos_x+96, self.pos_y, 0, (96/portrait_w)*-1, 192/portrait_h)
	end
	local metal_w, metal_h = IMG_metal:getDimensions()
	local metall_w, metall_h = IMG_metal_l:getDimensions()
	local metalr_w, metalr_h = IMG_metal_r:getDimensions()
	local shake_idx = #shake_arr - self.shake_time
	local shake = math.ceil((shake_arr[shake_idx] or 0) * 13)
	for row=0,self.height do
		for col=1,self.width do
			local panel = self.panels[row][col]
			local draw_x = (col-1) * 16 + self.pos_x
			local draw_y = (11-(row)) * 16 + self.pos_y + self.displacement - shake
			if panel.color ~= 0 and panel.state ~= "popped" then
				local draw_frame = 1
				if panel.garbage then
					local imgs = {flash=IMG_metal_flash}
					if not panel.metal then
						imgs = IMG_garbage[self.garbage_target.character]
					end
					if panel.x_offset == 0 and panel.y_offset == 0 then
						-- draw the entire block!
						if panel.metal then
							draw(IMG_metal_l, draw_x, draw_y, 0, 8/metall_w, 16/metall_h)
							draw(IMG_metal_r, draw_x+16*(panel.width-1)+8,draw_y, 0, 8/metalr_w, 16/metalr_h)
							for i=1,2*(panel.width-1) do
								draw(IMG_metal, draw_x+8*i, draw_y, 0, 8/metal_w, 16/metal_h)
							end
						else
							local height, width = panel.height, panel.width
							local top_y = draw_y - (height-1) * 16
							local use_1 = ((height-(height%2))/2)%2==0
							local filler_w, filler_h = imgs.filler1:getDimensions()
							for i=0,height-1 do
								for j=1,width-1 do
									draw((use_1 or height<3) and imgs.filler1 or
										imgs.filler2, draw_x+16*j-8, top_y+16*i, 0, 16/filler_w, 16/filler_h)
									use_1 = not use_1
								end
							end
							if height%2==1 then
								local face_w, face_h = imgs.face:getDimensions()
								draw(imgs.face, draw_x+8*(width-1), top_y+16*((height-1)/2), 0, 16/face_w, 16/face_h)
							else
								local face_w, face_h = imgs.doubleface:getDimensions()
								draw(imgs.doubleface, draw_x+8*(width-1), top_y+16*((height-2)/2), 0, 16/face_w, 32/face_h)
							end
							local corner_w, corner_h = imgs.topleft:getDimensions()
							local lr_w, lr_h = imgs.left:getDimensions()
							local topbottom_w, topbottom_h = imgs.top:getDimensions()
							draw(imgs.left, draw_x, top_y, 0, 8/lr_w, (1/lr_h)*height*16)
							draw(imgs.right, draw_x+16*(width-1)+8, top_y, 0, 8/lr_w, (1/lr_h)*height*16)
							draw(imgs.top, draw_x, top_y, 0, (1/topbottom_w)*width*16, 2/topbottom_h)
							draw(imgs.bot, draw_x, draw_y+14, 0, (1/topbottom_w)*width*16, 2/topbottom_h)
							draw(imgs.topleft, draw_x, top_y, 0, 8/corner_w, 3/corner_h)
							draw(imgs.topright, draw_x+16*width-8, top_y, 0, 8/corner_w, 3/corner_h)
							draw(imgs.botleft, draw_x, draw_y+13, 0, 8/corner_w, 3/corner_h)
							draw(imgs.botright, draw_x+16*width-8, draw_y+13, 0, 8/corner_w, 3/corner_h)
						end
					end
					if panel.state == "matched" then
						local flash_time = panel.initial_time - panel.timer


						local flashed_w, flashed_h = IMG_metal_flash:getDimensions()
						if flash_time >= self.FRAMECOUNT_FLASH then
							if panel.timer > panel.pop_time then
								if panel.metal then
									draw(IMG_metal_l, draw_x, draw_y, 0, 8/metall_w, 16/metall_h)
									draw(IMG_metal_r, draw_x+8, draw_y, 0, 8/metalr_w, 16/metalr_h)
								else
									local popped_w, popped_h = imgs.pop:getDimensions()
									draw(imgs.pop, draw_x, draw_y, 0, 16/popped_w, 16/popped_h)
								end
							elseif panel.y_offset == -1 then
								local p_w, p_h = IMG_panels[panel.color][1]:getDimensions()
								draw(IMG_panels[panel.color][1], draw_x, draw_y, 0, 16/p_w, 16/p_h)
							end
						elseif flash_time % 2 == 1 then
							if panel.metal then
								draw(IMG_metal_l, draw_x, draw_y, 0, 8/metall_w, 16/metall_h)
								draw(IMG_metal_r, draw_x+8, draw_y, 0, 8/metalr_w, 16/metalr_h)
							else
								local popped_w, popped_h = imgs.pop:getDimensions()
								draw(imgs.pop, draw_x, draw_y, 0, 16/popped_w, 16/popped_h)
							end
						else
							local flashed_w, flashed_h = imgs.flash:getDimensions()
							draw(imgs.flash, draw_x, draw_y, 0, 16/flashed_w, 16/flashed_h)
						end
					end
					--this adds the drawing of state flags to garbage panels
					if config.debug_mode then
						gprint(panel.state, draw_x*3, draw_y*3)
						if panel.match_anyway ~= nil then
							gprint(tostring(panel.match_anyway), draw_x*3, draw_y*3+10)
							if panel.debug_tag then
								gprint(tostring(panel.debug_tag), draw_x*3, draw_y*3+20)
							end
						end
						gprint(panel.chaining and "chaining" or "nah", draw_x*3, draw_y*3+30)
					end
				else
					if panel.state == "matched" then
						local flash_time = self.FRAMECOUNT_MATCH - panel.timer
						if flash_time >= self.FRAMECOUNT_FLASH then
							draw_frame = 6
						elseif flash_time % 2 == 1 then
							draw_frame = 1
						else
							draw_frame = 5
						end
					elseif panel.state == "popping" then
						draw_frame = 6
					elseif panel.state == "landing" then
						draw_frame = bounce_table[panel.timer + 1]
					elseif panel.state == "swapping" then
						if panel.is_swapping_from_left then
							draw_x = draw_x - panel.timer * 4
						else
							draw_x = draw_x + panel.timer * 4
						end
					elseif panel.state == "dimmed" then
						draw_frame = 7
					elseif panel.fell_from_garbage then
						draw_frame = garbage_bounce_table[panel.fell_from_garbage] or 1
					elseif self.danger_col[col] then
						draw_frame = danger_bounce_table[
							wrap(1,self.danger_timer+1+math.floor((col-1)/2),#danger_bounce_table)]
					else
						draw_frame = 1
					end
					local panel_w, panel_h = IMG_panels[panel.color][draw_frame]:getDimensions()
					draw(IMG_panels[panel.color][draw_frame], draw_x, draw_y, 0, 16/panel_w, 16/panel_h)
					if config.debug_mode then
						gprint(panel.state, draw_x*3, draw_y*3)
						if panel.match_anyway ~= nil then
							gprint(tostring(panel.match_anyway), draw_x*3, draw_y*3+10)
							if panel.debug_tag then
								gprint(tostring(panel.debug_tag), draw_x*3, draw_y*3+20)
							end
						end
						gprint(panel.chaining and "chaining" or "nah", draw_x*3, draw_y*3+30)
					end
				end
			end
			if config.debug_mode and mx >= draw_x and mx < draw_x + 16 and
					my >= draw_y and my < draw_y + 16 then
				mouse_panel = {row, col, panel}
				draw(IMG_panels[4][1], draw_x+16/3, draw_y+16/3, 0, 0.33333333, 0.3333333)
			end
		end
	end
	draw(IMG_frame, self.pos_x-4, self.pos_y-4)
	draw(IMG_wall, self.pos_x, self.pos_y - shake + self.height*16)
	if self.mode == "puzzle" then
		gprint("Moves: "..self.puzzle_moves, self.score_x, 100)
		gprint("Frame: "..self.CLOCK, self.score_x, 130)
	else
		gprint("Score: "..self.score, self.score_x, 100)
		gprint("Speed: "..self.speed, self.score_x, 130)
		gprint("Frame: "..self.CLOCK, self.score_x, 145)
		if self.mode == "time" then
			local time_left = 120 - (self.game_stopwatch or 120)/60
			local mins = math.floor(time_left/60)
			local secs = math.ceil(time_left% 60)
			if secs == 60 then
				secs = 0
				mins = mins+1
			end
			gprint("Time: "..string.format("%01d:%02d",mins,secs), self.score_x, 160)
		elseif self.level then
			gprint("Level: "..self.level, self.score_x, 160)
		end
		gprint("Health: "..self.health, self.score_x, 175)
		gprint("Shake: "..self.shake_time, self.score_x, 190)
		gprint("Stop: "..self.stop_time, self.score_x, 205)
		gprint("Pre stop: "..self.pre_stop_time, self.score_x, 220)
		if config.debug_mode and self.danger then gprint("danger", self.score_x,235) end
		if config.debug_mode and self.danger_music then gprint("danger music", self.score_x, 250) end
		if config.debug_mode then
			gprint("cleared: "..(self.panels_cleared or 0), self.score_x, 265)
		end
		if config.debug_mode then
			gprint("metal q: "..(self.metal_panels_queued or 0), self.score_x, 280)
		end
		if config.debug_mode and self.input_state then
			-- print(self.input_state)
			-- print(base64decode[self.input_state])
			local iraise, iswap, iup, idown, ileft, iright = unpack(base64decode[self.input_state])
			-- print(tostring(raise))
			local inputs_to_print = "inputs:"
			if iraise then inputs_to_print = inputs_to_print.."\nraise" end --◄▲▼►
			if iswap then inputs_to_print = inputs_to_print.."\nswap" end
			if iup then inputs_to_print = inputs_to_print.."\nup" end
			if idown then inputs_to_print = inputs_to_print.."\ndown" end
			if ileft then inputs_to_print = inputs_to_print.."\nleft" end
			if iright then inputs_to_print = inputs_to_print.."\nright" end
			gprint(inputs_to_print, self.score_x, 295)
		end
		if match_type then gprint(match_type, 375, 10) end
		if P1 and P1.game_stopwatch and tonumber(P1.game_stopwatch) then
			gprint(frames_to_time_string(P1.game_stopwatch, P1.mode == "endless"), 385, 25)
		end
		if not config.debug_mode then
			gprint(join_community_msg or "", 330, 560)
		end
	end
	self:draw_cards()
	self:render_cursor()
	if self.do_countdown then
		self:render_countdown()
	end
end


-- ---------------------------------------------------------------------------
-- Input
-- ---------------------------------------------------------------------------

function Playfield:controls()
	local new_dir = nil
	local sdata = self.input_state
	local raise, swap, up, down, left, right = unpack(base64decode[sdata])
	if (raise) and (not self.prevent_manual_raise) then
		self.manual_raise = true
		self.manual_raise_yet = false
	end

	self.swap_1 = swap
	self.swap_2 = swap

	if up then
		new_dir = "up"
	elseif down then
		new_dir = "down"
	elseif left then
		new_dir = "left"
	elseif right then
		new_dir = "right"
	end

	if new_dir == self.cur_dir then
		if self.cur_timer ~= self.cur_wait_time then
			self.cur_timer = self.cur_timer + 1
		end
	else
		self.cur_dir = new_dir
		self.cur_timer = 0
	end
end


-- ---------------------------------------------------------------------------
-- Networking
-- ---------------------------------------------------------------------------

function Playfield:send_controls()
	local k = K[self.which]
	local to_send = base64encode[
		((keys[k.raise1] or keys[k.raise2] or this_frame_keys[k.raise1]
			or this_frame_keys[k.raise2]) and 32 or 0) +
		((this_frame_keys[k.swap1] or this_frame_keys[k.swap2]) and 16 or 0) +
		((keys[k.up] or this_frame_keys[k.up]) and 8 or 0) +
		((keys[k.down] or this_frame_keys[k.down]) and 4 or 0) +
		((keys[k.left] or this_frame_keys[k.left]) and 2 or 0) +
		((keys[k.right] or this_frame_keys[k.right]) and 1 or 0)+1]
	if TCP_sock then
		net_send("I"..to_send)
	end
	local replay = replay[self.mode]
	if replay and replay.in_buf then
		replay.in_buf = replay.in_buf .. to_send
	end
	return to_send
end


return Playfield
