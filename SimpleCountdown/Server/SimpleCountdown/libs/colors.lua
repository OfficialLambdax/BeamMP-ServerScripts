--[[
	License: None
	Author: Neverless (discord: neverless.)
]]
local M = {}
M._VERSION = "0.2" -- 13.01.2024 (DD.MM.YYYY)

-- -----------------------------------------------------------------------------------------------
-- Init
M.init = function()
	for color, func in pairs(M.colors) do
		M[color] = func
	end
	
	--M.patchClass().createGlobals()
	--local test = "hello world"
	--print(test:Black())
	--print(Fat("hello"))
	--print(("hello"):Black())
	
	--print(M.concatenate(123, 456, 789, "hello"))
	
	--printRaw(M.dateTime() .. " \27[4mhello\27[0m")
	
	--M.SendChatMessage(-1, M.underlined(M.orange("hello world") .. " my name is " .. M.darkRed("Neverless")))
	--M.SendChatMessage(-1, string.format("%s my name is %s", M.orange("Hello World"), M.darkRed("Neverless")))
	--M.SendChatMessage(-2, string.format("%s my name is %s", M.orange("Hello World"), M.darkRed("Neverless")))
end

-- -----------------------------------------------------------------------------------------------
-- Extra
--[[ Patches the String class
	local colors = require("colors").patchStringClass()

	local my_var = "hello world"
	print(my_var:black())
	
	or
	
	print(("hello world"):black())
	
	or
	
	print(string.black("hello world"))
]]
M.patchStringClass = function()
	local colors = M.colors
	function string:black(string) return colors.black(self or string) end
	function string:cyan(string) return colors.cyan(self or string) end
	function string:orange(string) return colors.orange(self or string) end
	function string:grey(string) return colors.grey(self or string) end
	function string:white(string) return colors.white(self or string) end
	
	function string:darkBlue(string) return colors.darkBlue(self or string) end
	function string:darkGreen(string) return colors.darkGreen(self or string) end
	function string:darkRed(string) return colors.darkRed(self or string) end
	function string:darkPurple(string) return colors.darkPurple(self or string) end
	
	function string:lightGreen(string) return colors.lightGreen(self or string) end
	function string:lightCyan(string) return colors.lightCyan(self or string) end
	function string:lightRed(string) return colors.lightRed(self or string) end
	function string:lightPurple(string) return colors.lightPurple(self or string) end
	function string:lightYellow(string) return colors.lightYellow(self or string) end
	
	function string:bold(string) return colors.bold(self or string) end
	function string:crossed(string) return colors.crossed(self or string) end
	function string:underlined(string) return colors.underlined(self or string) end
	function string:italic(string) return colors.italic(self or string) end
	
	return M
end

--[[ makes the functions globals
	local colors = require("colors").withGlobals()

	print(black("hello world"))
]]
M.withGlobals = function()
	for color, func in pairs(M.colors) do
		_G[color] = func
	end

	return M
end

-- -----------------------------------------------------------------------------------------------
-- Utility
M.concatenate = function(...)
	local build_string = ""
	for _, string in pairs({...}) do
		build_string = build_string .. string .. " "
	end
	return build_string:sub(1, -2)
end

M.build = function(string, tag)
	return M.dateTime() .. " [" .. M.convertToConsole(tag or "INFO") .. "] " .. M.convertToConsole(string) .. "\27[0m"
end

M.print = function(string, tag)
	printRaw(M.build(string, tag))
end

M.SendChatMessage = function(player_id, message)
	if player_id == -2 then
		M.print(message, "CHAT")
	else
		MP.SendChatMessage(player_id, message)
	end
end

M.ifServer = function(string, func)
	if MP and MP.TriggerClientEvent then
		return func(string)
	end
	return string
end

-- -----------------------------------------------------------------------------------------------
-- Internal
M.convertToConsole = function(string)
	for search, replace in pairs(M.console_colors) do
		string = string:gsub("%" .. search, replace)
	end
	return string
end

M.cleanseColors = function(string)
	for search, _ in pairs(M.console_colors) do
		string = string:gsub("%" .. search, "")
	end
	return string
end

M.dateTime = function()
	return os.date("[%d/%m/%y %H:%M:%S]")
end

M.color_string = function(color, string, ends)
	return color .. string .. ends
end

M.colors = {
	black = function(string) return M.color_string("^0", string, "^r") end,
	cyan = function(string) return M.color_string("^3", string, "^r") end,
	orange = function(string) return M.color_string("^6", string, "^r") end,
	grey = function(string) return M.color_string("^7", string, "^r") end,
	white = function(string) return M.color_string("^f", string, "^r") end,
	
	darkBlue = function(string) return M.color_string("^1", string, "^r") end,
	darkGreen = function(string) return M.color_string("^2", string, "^r") end,
	darkRed = function(string) return M.color_string("^4", string, "^r") end,
	darkPurple = function(string) return M.color_string("^5", string, "^r") end,
	
	lightGreen = function(string) return M.color_string("^a", string, "^r") end,
	lightCyan = function(string) return M.color_string("^b", string, "^r") end,
	lightRed = function(string) return M.color_string("^c", string, "^r") end,
	lightPurple = function(string) return M.color_string("^d", string, "^r") end,
	lightYellow = function(string) return M.color_string("^e", string, "^r") end,
	
	bold = function(string) return M.color_string("^l", string, "^r") end,
	crossed = function(string) return M.color_string("^m", string, "^r") end,
	underlined = function(string) return M.color_string("^n", string, "^r") end,
	italic = function(string) return M.color_string("^o", string, "^r") end,
	
	--BlackTest = function(string) return M.color_string("^8", string) end,
	--BlueTest = function(string) return M.color_string("^9", string) end,
}

-- https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences?redirectedfrom=MSDN
M.console_colors = { -- client -> console converter
	["^r"] = "\27[0m", -- reset
	["^0"] = "\27[30m", -- black
	["^3"] = "\27[6m", -- cyan
	["^6"] = "\27[93m", -- orange ?? using yellow for the moment
	["^7"] = "\27[39m", -- grey ?? turns back to default foreground color
	["^f"] = "\27[37m", -- white
	
	["^1"] = "\27[94m", -- dark blue
	["^2"] = "\27[32m", -- dark green
	["^4"] = "\27[31m", -- dark red
	["^5"] = "\27[35m", -- dark purple
	
	["^a"] = "\27[92m", -- light green
	["^b"] = "\27[96m", -- light cyan
	["^c"] = "\27[91m", -- light red
	["^d"] = "\27[95m", -- light purple
	["^e"] = "\27[93m", -- light yellow
	
	["^l"] = "\27[1m", -- bold
	["^m"] = "", -- crossed ??
	["^n"] = "\27[4m", -- underlined
	["^o"] = "", -- italic ??
}

M.init()
return M
