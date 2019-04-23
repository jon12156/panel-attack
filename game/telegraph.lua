
Telegraph = class(function(self, sender, recipient)
	self.garbage_queue = new GarbageQueue()
	self.stopper = { garbage_type, size, frame_to_release}
	self.sender = sender
	self.recipient = recipient
end)

function Telegraph:push(attack_type, attack_size)
	self.stopper = {garbage_type=attack_type, attack_size, frame_to_release=self.stack.CLOCK+GARBAGE_TRANSIT_TIME+GARBAGE_DELAY}
	if attack_type == "chain" then
		self.garbage_queue:grow_chain()
	elseif attack_type == "combo" then
		local garbage = {--[[TODO: pull this code from sharpobject's existing code for changing combos to garbage]]}
		self.garbage_queue:push(garbage)
	end
end

function Telegraph:pop_all_ready_garbage()
	local ready_garbage = {}
	if self.stopper and self.stopper.frame_to_release <= self.recipient.CLOCK then
		self.stopper = nil
	end
	if not self.stopper then
		local next_block = {}
		local number_of_blocks = self.garbage_queue:len()
		for i=1, number_of_blocks do
			ready_garbage[i] = self.garbage_queue:pop()
		end
		return ready_garbage
	elseif self.stopper and self.stopper.garbage_type == "chain" then
		return {} --waiting on sender chain to end
	elseif self.stopper and self.stopper.garbage_type == "combo" and stopper.garbage then
		local next_block_type = "combo"
		local next_in_queue = self.garbage_queue:peek()
		while not next_in_queue[4]--[[is_from_chain]] and next_in_queue[1]--[[width]] < self.stopper.size do
			ready_garbage[#ready_garbage+1] = self.garbage_queue:pop()
			next_in_queue = self.garbage_queue:peek()
		end
		return ready_garbage
	end
end
function Telegraph:sender_chain_ended()
	self.stopper = nil
end

return Telegraph
