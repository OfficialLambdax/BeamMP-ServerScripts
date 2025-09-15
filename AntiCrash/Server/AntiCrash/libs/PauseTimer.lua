--[[
	License: None
	Author: Neverless (discord: neverless.)
]]
local M = {}

-- server side compat
local function precisionTimer()
	local timer = {int = {timer = MP.CreateTimer()}}
	function timer:stop()
		return self.int.timer:GetCurrent() * 1000
	end
	function timer:stopAndReset()
		local time = self.int.timer:GetCurrent() * 1000
		self.int.timer:Start()
		return time
	end
	return timer
end

M.new = function()
	local timer = {
		int = {
			-- must have stop(), stopAndReset() and start() interface
			timer = (hptimer or HighPerfTimer or precisionTimer)(),
			time = 0,
			paused = false
		}
	}
	
	timer.int.timer:stopAndReset() -- HighPerfTimer bug troubleshoot

	function timer:stop()
		if self.int.paused then return self.int.time end
		self.int.time = self.int.time + self.int.timer:stopAndReset()
		return self.int.time
	end
	
	function timer:stopAndReset()
		local time = self:stop()
		self.int.time = 0
		return time
	end
	
	function timer:stopIf(ms)
		if self:stop() > ms then
			self.int.time = 0
			return true
		end
		return false
	end
	
	function timer:start()
		self.int.time = 0
		self.int.timer:stopAndReset()
	end
	
	function timer:pause(state)
		self.int.paused = state
		self.int.timer:stopAndReset()
	end
	
	return timer
end

return M
