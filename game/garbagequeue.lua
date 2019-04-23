
GarbageQueue = class(function(s)
	s.chain_garbage = Queue()
	s.combo_garbage = {0,0,0,0,0,0} --index here represents width, and value represents how many of that width queued
	s.metal = 0
end)

function GarbageQueue:push(garbage)
	local width, height, metal, from_chain = unpack(garbage)
	if metal then
		self.metal = self.metal + 1
	elseif from_chain or height > 1 then
		if not from_chain then
			print("ERROR: garbage with height > 1 was not marked as 'from_chain'")
			print("adding it to the chain garbage queue anyway")
		end
		self.chain_garbage:push(garbage)
	else
		self.combo_garbage[width] = self.combo_garbage[width] + 1
	end
end

function GarbageQueue:pop(just_peeking)
	--check for any chain garbage, and return the first one (chronologically), if any
	if self.chain_garbage:peek() then
		if just_peeking then
			return self.chain_garbage:peek()
		else
			return self.chain_garbage:pop()
		end
	end
	--check for any combo garbage, and return the smallest one, if any
	for k,v in ipairs(self.combo_garbage) do
		if v > 0 then
			if not just_peeking then
				self.combo_garbage[k] = v - 1
			end
				--returning {width, height, is_metal, is_from_chain}
			return {k, 1, false, false}
		end
	end
	--check for any metal garbage, and return one if any
	if self.metal > 0 then
		if not just_peeking then
			self.metal = self.metal - 1
		end
		return {6, 1, true, false}
	end
	return nil
end

function GarbageQueue:peek()
	return self:pop(true) --(just peeking)
end
function GarbageQueue:len()
	local ret = 0
	ret = ret + self.chain_garbage:len()
	for k,v in ipairs(self.combo_garbage) do
		ret = ret + v
	end
	ret = ret + self.metal
	return ret
end

function GarbageQueue:grow_chain()
-- TODO: this should increase the size of the first chain garbage by 1.
-- This is used by the telegraph to increase the size of the chain garbage being built
-- or add a 6-wide if there is not chain garbage yet in the queue
end


return GarbageQueue
