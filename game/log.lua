
local Log = {}

Log.LEVELS	= {
	OFF			= 0,
	ERROR		= 1,
	WARNING		= 2,
	INFO		= 3,
	DEBUG		= 4,
	}

Log.LEVEL_NAMES	= {
	[0]	=
	"OFF",
	"ERROR",
	"WARNING",
	"INFO",
	"DEBUG",
	}

Log.currentLevel	= Log.LEVELS.INFO

function Log:message(level, message, ...)
	if level > self.currentLevel then
		return
	end

	print(string.format("[%s] %s", LOG_LEVEL_NAMES[level], message))
	if (...) then
		if (#{...}) > 1 then
			tprint({...})
		else
			print(...)
		end			
	end

end

function Log:error(m, ...) self:message(self.LEVELS.ERROR, m, ...) end
function Log:warning(m, ...) self:message(self.LEVELS.WARNING, m, ...) end
function Log:info(m, ...) self:message(self.LEVELS.INFO, m, ...) end
function Log:debug(m, ...) self:message(self.LEVELS.DEBUG, m, ...) end

function Log:setLevel(l)
	self.currentLevel = l
end


local function tprint(t, indent, done)
	local function show(val)
		if type(val) == "string" then
			return '"' .. val .. '"'
		else
			return tostring(val)
		end
	end
	if type(t) ~= "table" then
		print("tprint got " .. type(t))
		return
	end

	done = done or {}
	indent = indent or 0
	for key, value in pairs(t) do
		local indents = string.rep(" ", indent) -- indent it
		if type(value) == "table" and not done [value] then
			done [value] = true
			print(indents .. show(key) .. ":");
			tprint(value, indent + 2, done)
		else
			print(indents .. show(key) .. " = " .. show(value))
		end
	end
end

return Log
