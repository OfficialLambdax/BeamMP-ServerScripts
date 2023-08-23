-- Issues with this Script? Contact Neverless @ BeamMP
local VERSION <const> = "0.2"

local ADMINS = {"Player1","Player2"} -- ADD YOUR PLAYERS THAT HAVE ACCESS TO THIS HERE
local COMMANDS = {}

--[[
	You can define Complex flags in the "Func Commands" Section
	You can define Simple flags in the "onInit" Function
]]

-- Basic functions -----------------------------------------------------------
local function messageSplit(message)
	local messageSplit = {}
	local nCount = 0
	for i in string.gmatch(message, "%S+") do
		messageSplit[nCount] = i
		nCount = nCount + 1
	end
	
	return messageSplit
end

local function tableSize(table)
	if type(table) ~= "table" then return 0 end
	local len = 0
	for k, v in pairs(table) do
		len = len + 1
	end
	return len
end

-- case insensitive, also supports playerid's as names
local function playerNameToId(playerName)
	local playerName = string.lower(playerName)
	local players = MP.GetPlayers()
	for playerId, name in pairs(players) do
		if string.lower(name) == playerName then return playerId end
	end
	local playerId = tonumber(playerName) or -1
	if MP.GetPlayerName(playerId) == "" then return nil end
	return playerId
end

-- Events --------------------------------------------------------------------
function onChatMessage(playerId, playerName, message)
	if string.sub(message, 0, 1) ~= "/" then return end
	local message = messageSplit(message)
	
	local exec = COMMANDS[string.sub(message[0], 2, -1)]
	if not exec then return end -- not a flag command
	if not ADMINS[playerName] then MP.SendChatMessage(playerId, "Permissions Denied"); return 1 end -- no perms
	if type(exec) == "table" then -- if simple command
		local toId = -1
		if message[1] then toId = playerNameToId(message[1]) end
		if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return 1 end
		if exec.c then
			MP.SendChatMessage(toId, exec.c)
		end
		if exec.e then
			MP.TriggerClientEvent(toId, "displayCountdown", exec.e)
		end
	else -- if complex command
		if not exec(playerId, playerName, message) then return 1 end
	end
	MP.SendChatMessage(playerId, "Flag Executed")
	return 1
end

-- Func Commands -------------------------------------------------------------
function COMMANDS.lights(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	MP.TriggerClientEvent(toId, "displayCountdown", "🟥⬛⬛⬛⬛|3|true")
	MP.TriggerClientEvent(toId, "displayCountdown", "🟥🟥⬛⬛⬛|3|true")
	MP.TriggerClientEvent(toId, "displayCountdown", "🟥🟥🟥⬛⬛|3|true")
	MP.TriggerClientEvent(toId, "displayCountdown", "🟥🟥🟥🟥⬛|3|true")
	MP.TriggerClientEvent(toId, "displayCountdown", "🟥🟥🟥🟥🟥|3|true")
	MP.TriggerClientEvent(toId, "displayCountdown", "🟩🟩🟩🟩🟩|3|true")
	return true
end

function COMMANDS.short(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	MP.TriggerClientEvent(-1, "displayCountdown", "🟥⬛⬛|3|true")
	MP.TriggerClientEvent(-1, "displayCountdown", "🟥🟥⬛|3|true")
	MP.TriggerClientEvent(-1, "displayCountdown", "🟥🟥🟥|3|true")
	MP.TriggerClientEvent(-1, "displayCountdown", "🟩🟩🟩|3|true")
	return true
end

function COMMANDS.flags(playerId, playerName, message)
	MP.SendChatMessage(playerId, "_ Displaying all available Flags _")
	for flag, _ in pairs(COMMANDS) do
		MP.SendChatMessage(playerId, "=> " .. flag)
	end
end

-- Init ----------------------------------------------------------------------
function onInit()
	local admins = ADMINS
	ADMINS = {}
	for _, playerName in pairs(admins) do
		ADMINS[playerName] = true
	end
	
	-- simple commands
	COMMANDS.black = {}
	COMMANDS.black["c"] = "⬛BLACK FLAG⬛"
	COMMANDS.black["e"] = "⬛BLACK FLAG⬛|3|true"
	COMMANDS.yellow = {}
	COMMANDS.yellow["c"] = "🟨YELLOW FLAG🟨"
	COMMANDS.yellow["e"] = "🟨YELLOW FLAG🟨|3|true"
	COMMANDS.blue = {}
	COMMANDS.blue["c"] = "🟦BLUE FLAG🟦"
	COMMANDS.blue["e"] = "🟦BLUE FLAG🟦|3|true"
	COMMANDS.red = {}
	COMMANDS.red["c"] = "🟥RED FLAG🟥"
	COMMANDS.red["e"] = "🟥RED FLAG🟥|3|true"
	COMMANDS.green = {}
	COMMANDS.green["c"] = "🟩GREEN FLAG🟩"
	COMMANDS.green["e"] = "🟩GREEN FLAG🟩|3|true"
	COMMANDS.sc = {}
	COMMANDS.sc["c"] = "⚠️Safety Car⚠️"
	COMMANDS.sc["e"] = "⚠️Safety Car⚠️|3|true"
	COMMANDS.checkered = {}
	COMMANDS.checkered["c"] = "🏁Checkered🏁"
	COMMANDS.checkered["e"] = "🏁Checkered🏁|3|true"
	COMMANDS.white = {}
	COMMANDS.white["c"] = "🏳️Caution🏳️"
	COMMANDS.white["e"] = "🏳️Caution🏳️|3|true"
	COMMANDS.lastlap = {}
	COMMANDS.lastlap["c"] = "🏳️Last Lap🏳️"
	COMMANDS.lastlap["e"] = "🏳️Last Lap🏳️|3|true"
	
	MP.RegisterEvent("onChatMessage","onChatMessage")
	print("------- Flag Script loaded ------")

	-- testing
	--onChatMessage(-1, "beamcruisebot", "/flags")
end
