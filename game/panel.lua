
Panel = class(function(p)
		p:clear()
	end)

function Panel:clear()
		-- color 0 is an empty panel.
		-- colors 1-7 are normal colors, 8 is [!].
		self.color = 0
		-- A panel's timer indicates for how many more frames it will:
		--  . be swapping
		--  . sit in the MATCHED state before being set POPPING
		--  . sit in the POPPING state before actually being POPPED
		--  . sit and be POPPED before disappearing for good
		--  . hover before FALLING
		-- depending on which one of these states the panel is in.
		self.timer = 0
		-- is_swapping is set if the panel is swapping.
		-- The panel's timer then counts down from 3 to 0,
		-- causing the swap to end 3 frames later.
		-- The timer is also used to offset the panel's
		-- position on the screen.

		self.initial_time = nil
		self.pop_time = nil
		self.pop_index = nil
		self.x_offset = nil
		self.y_offset = nil
		self.width = nil
		self.height = nil
		self.garbage = nil
		self.metal = nil

		-- Also flags
		self:clear_flags()
end

-- states:
-- swapping, matched, popping, popped, hovering,
-- falling, dimmed, landing, normal
-- flags:
-- from_left
-- dont_swap
-- chaining





function Panel:has_flags()
	return (self.state ~= "normal") or self.is_swapping_from_left
			or self.dont_swap or self.chaining
end

function Panel:clear_flags()
	self.combo_index			= nil
	self.combo_size				= nil
	self.chain_index			= nil
	self.is_swapping_from_left	= nil
	self.dont_swap				= nil
	self.chaining				= nil
	-- Animation timer for "bounce" after falling from garbage.
	self.fell_from_garbage		= nil	
	self.state					= "normal"
end


do
	local exclude_hover_set = {matched=true, popping=true, popped=true,
			hovering=true, falling=true}
	function Panel:exclude_hover()
		return exclude_hover_set[self.state] or self.garbage
	end

	local exclude_match_set = {swapping=true, matched=true, popping=true,
			popped=true, dimmed=true, falling=true}
	function Panel:exclude_match()
		return exclude_match_set[self.state] or self.color == 0 or self.color == 9
			or (self.state == "hovering" and not self.match_anyway)
	end

	local exclude_swap_set = {matched=true, popping=true, popped=true,
			hovering=true, dimmed=true}
	function Panel:exclude_swap()
		return exclude_swap_set[self.state] or self.dont_swap or self.garbage
	end

	function Panel:support_garbage()
		return self.color ~= 0 or self.hovering
	end

	-- "Block garbage fall" means
	-- "falling-ness should not propogate up through this panel"
	-- We need this because garbage doesn't hover, it just falls
	-- opportunistically.
	local block_garbage_fall_set = {matched=true, popping=true,
			popped=true, hovering=true, swapping=true}
	function Panel:block_garbage_fall()
		return block_garbage_fall_set[self.state] or self.color == 0
	end

	function Panel:dangerous()
		return self.color ~= 0 and (self.state ~= "falling" or not self.garbage)
	end
end






return Panel
