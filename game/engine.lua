	-- Stuff defined in this file:
	--  . the data structures that store the configuration of
	--    the stack of panels
	--  . the main game routine
	--    (rising, timers, falling, cursor movement, swapping, landing)
	--  . the matches-checking routine

Stack			= require "game.stack"
Panel			= require "game.panel"
GarbageQueue	= require "game.garbagequeue"
Telegraph		= require "game.telegraph"


function winningPlayer()
		if not P2 then
				return P1
		elseif op_win_count > my_win_count then
				return P2
		else return P1
		end
end
