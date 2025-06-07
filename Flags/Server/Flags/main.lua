-- Issues with this Script? Contact Neverless @ BeamMP

local TriggerClientEvent = require("libs/TriggerClientEvent")
local VERSION = "0.3" -- 03.06.2025 (DD.MM.YYYY)

local ADMINS = {"player_1","player_2"} -- ADD YOUR PLAYERS THAT HAVE ACCESS TO THIS HERE
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

local function random(min, max)
	local random = math.random() * max
	if random < min then random = min end
	return random
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
			TriggerClientEvent:send(toId, "displayCountdown", exec.e)
		end
	else -- if complex command
		if not exec(playerId, playerName, message) then return 1 end
	end
	MP.SendChatMessage(playerId, "Flag Executed")
	return 1
end

function onPlayerJoin(player_id)
	TriggerClientEvent:set_synced(player_id)
end

function onPlayerDisconnect(player_id)
	TriggerClientEvent:remove(player_id)
end

-- Func Commands -------------------------------------------------------------
function COMMANDS.lights(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🔴⚫⚫⚫⚫|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴⚫⚫⚫|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴🔴⚫⚫|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴🔴🔴⚫|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴🔴🔴🔴|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🟢🟢🟢🟢🟢|1|true")
	return true
end

function COMMANDS.short(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🔴⚫⚫|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴⚫|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴🔴|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🟢🟢🟢|1|true")
	return true
end

function COMMANDS.quick(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🔴|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🟢|1|true")
	return true
end

function COMMANDS.rolling(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🔴🔴🔴🔴|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🟢🟢🟢🟢|1|true")
	return true
end

function COMMANDS.vscend(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "⚠️VSC ENDING⚠️|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🟩GREEN FLAG🟩|1|true")
	return true
end

function COMMANDS.fcyend(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "⚠️FCY ENDING⚠️|2|true")
	TriggerClientEvent:send(toId, "displayCountdown", "🟩GREEN FLAG🟩|1|true")
	return true
end

function COMMANDS.green(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🟩GREEN FLAG🟩|3|true")
	TriggerClientEvent:send(toId, "hazard_lightoverwrite", 1)
	MP.SendChatMessage(toId, "🟩GREEN FLAG🟩")
	return true
end

function COMMANDS.yellow(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🟨YELLOW FLAG🟨|3|true")
	TriggerClientEvent:send(toId, "hazard_lightoverwrite", 2)
	MP.SendChatMessage(toId, "🟨YELLOW FLAG🟨")
	return true
end

function COMMANDS.red(playerId, playerName, message)
	local toId = -1
	if message[1] then toId = playerNameToId(message[1]) end
	if toId == nil then MP.SendChatMessage(playerId, "Unknown Player: " .. message[1]); return nil end
	
	TriggerClientEvent:send(toId, "displayCountdown", "🟥RED FLAG🟥|3|true")
	TriggerClientEvent:send(toId, "hazard_lightoverwrite", 4)
	MP.SendChatMessage(toId, "🟥RED FLAG🟥")
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
	COMMANDS.abort = {}
	COMMANDS.abort["c"] = "🟠START ABORTED🟠"
	COMMANDS.abort["e"] = "🟠⚫🟠⚫🟠|5|true"
	COMMANDS.formation = {}
	COMMANDS.formation["c"] = "🟢FORMATION LAP🟢"
	COMMANDS.formation["e"] = "⚫🟢⚫🟢⚫|5|true"
	COMMANDS.black = {}
	COMMANDS.black["c"] = "⬛BLACK FLAG⬛"
	COMMANDS.black["e"] = "⬛BLACK FLAG⬛|3|true"
	--COMMANDS.yellow = {}
	--COMMANDS.yellow["c"] = "🟨YELLOW FLAG🟨"
	--COMMANDS.yellow["e"] = "🟨YELLOW FLAG🟨|3|true"
	COMMANDS.caution = {}
	COMMANDS.caution["c"] = "🟨CAUTION🟨"
	COMMANDS.caution["e"] = "🟨CAUTION🟨|3|true"
	COMMANDS.cautionend = {}
	COMMANDS.cautionend["c"] = "🟨CAUTION ENDING🟨"
	COMMANDS.cautionend["e"] = "🟨ENDING🟨|3|true"
	COMMANDS.blue = {}
	COMMANDS.blue["c"] = "🟦BLUE FLAG🟦"
	COMMANDS.blue["e"] = "🟦BLUE FLAG🟦|3|true"
	--COMMANDS.red = {}
	--COMMANDS.red["c"] = "🟥RED FLAG"
	--COMMANDS.red["e"] = "🟥RED FLAG🟥|3|true"
	--COMMANDS.green = {}
	--COMMANDS.green["c"] = "🟩GREEN FLAG🟩"
	--COMMANDS.green["e"] = "🟩GREEN FLAG🟩|3|true"
	COMMANDS.sc = {}
	COMMANDS.sc["c"] = "⚠️SAFETY CAR DEPLOYED⚠️"
	COMMANDS.sc["e"] = "⚠️SAFETY CAR⚠️|3|true"
	COMMANDS.scin = {}
	COMMANDS.scin["c"] = "⚠️SAFETY CAR ENDING⚠️"
	COMMANDS.scin["e"] = "⚠️SC ENDING⚠️|3|true"
	COMMANDS.vsc = {}
	COMMANDS.vsc["c"] = "⚠️VIRTUAL SAFETY CAR⚠️"
	COMMANDS.vsc["e"] = "⚠️VSC⚠️|3|true"
	COMMANDS.fcy = {}
	COMMANDS.fcy["c"] = "⚠️FULL COURSE YELLOW⚠️"
	COMMANDS.fcy["e"] = "⚠️FCY⚠️|3|true"
	COMMANDS.checkered = {}
	COMMANDS.checkered["c"] = "🏁CHECKERED FLAG🏁"
	COMMANDS.checkered["e"] = "🏁CHECKERED🏁|3|true"
	COMMANDS.white = {}
	COMMANDS.white["c"] = "⬜WHITE FLAG⬜"
	COMMANDS.white["e"] = "⬜WHITE FLAG⬜|3|true"
	COMMANDS.lastlap = {}
	COMMANDS.lastlap["c"] = "⬜LAST LAP⬜"
	COMMANDS.lastlap["e"] = "⬜LAST LAP⬜|3|true"
	COMMANDS.technical = {}
	COMMANDS.technical["c"] = "🟧TECHNICAL FLAG🟧"
	COMMANDS.technical["e"] = "🟧TECHNICAL🟧|3|true"
	COMMANDS.warning = {}
	COMMANDS.warning["c"] = "🏳️WARNING FLAG🏳️"
	COMMANDS.warning["e"] = "🏳️WARNING🏳️|3|true"
	
	MP.RegisterEvent("onChatMessage","onChatMessage")
	MP.RegisterEvent("onPlayerJoin","onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect","onPlayerDisconnect")
	
	for player_id, _ in pairs(MP.GetPlayers() or {}) do
		onPlayerJoin(player_id)
	end
	
	print("------- Flag Script loaded ------")

	-- testing
	--onChatMessage(-1, "beamcruisebot", "/flags")
end
