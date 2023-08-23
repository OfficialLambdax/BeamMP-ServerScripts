-- Issues with this Script? Contact Neverless @ BeamMP
local VERSION <const> = "0.1"

local ADMINS = {"Player1","Player2"} -- DEFINES THE PLAYERS THAT HAVE ACCESS TO THIS SCRIPT HERE
local WHITELIST = {}
local COMMANDS = {}
local ENABLED = false -- set to true to enable it by default

--[[
	Provides temporary Vehicle Spawn Permissions that are disabled by default.
	Auto enabled once a player is or all players are whitelisted.
	
	/vsw help
		Shows all available commands
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

local function playerNameToId(playerName)
	local players = MP.GetPlayers()
	for playerId, v in pairs(players) do
		if playerName == v then return playerId end
	end
	return nil
end

local function removeAllPlayerVehicles(playerId)
	local vehicles = MP.GetPlayerVehicles(playerId)
	if not vehicles then return end
	
	for vehicleId, _ in pairs(vehicles) do
		MP.RemoveVehicle(playerId, vehicleId)
	end
	
	MP.SendChatMessage(playerId, "Vehicle Spawn Whitelist has been enabled. You do not have Permissions to Spawn vehicles")
end

-- Commands ------------------------------------------------------------------
local function addPlayer(callerId, message)
	WHITELIST[message[2]] = true
	MP.SendChatMessage(callerId, "Successfully added: " .. message[2])
	
	if not ENABLED then
		ENABLED = true
		
		local players = MP.GetPlayers()
		for playerId, playerName in pairs(players) do
			if not WHITELIST[playerName] then removeAllPlayerVehicles(playerId) end
		end
		
		MP.SendChatMessage(callerId, "Enabled Vehicle Spawn Whitelist")
	end
end

local function remPlayer(callerId, message)
	if not WHITELIST[message[2]] then MP.SendChatMessage(callerId, "This player wasnt whitelisted: " .. message[2]); return end
	WHITELIST[message[2]] = nil
	
	local playerId = playerNameToId(message[2])
	if playerId then removeAllPlayerVehicles(playerId) end
	
	MP.SendChatMessage(callerId, "Successfully removed: " .. message[2])
end

local function help(callerId, message)
	MP.SendChatMessage(callerId, "_ Available Commands for the VehicleSpawnWhitelist _")
	for command, table in pairs(COMMANDS) do
		MP.SendChatMessage(callerId, '=> /vsw ' .. command .. ' ' .. table.syntax)
	end
end

local function disable(callerId, message)
	ENABLED = false
	MP.SendChatMessage(callerId, "Disabled the Vehicle Spawn Whitelist")
end

local function addAll(callerId, message)
	local players = MP.GetPlayers()
	for _, playerName in pairs(players) do
		WHITELIST[playerName] = true
	end
	MP.SendChatMessage(callerId, "All current online players have been whitelisted")
	
	if not ENABLED then
		ENABLED = true
		MP.SendChatMessage(callerId, "Enabled Vehicle Spawn Whitelist")
	end
end

local function wipe(callerId, message)
	WHITELIST = {}
	MP.SendChatMessage(callerId, "Emptied the entire Whitelist. Including admins spawn rights.")
	
	if ENABLED then
		local players = MP.GetPlayers()
		for playerId, playerName in pairs(players) do
			removeAllPlayerVehicles(playerId)
		end
	end
end

local function show(callerId, message)
	MP.SendChatMessage(callerId, "_ Showing all Whitelisted Players _")
	for playerName, _ in pairs(WHITELIST) do
		MP.SendChatMessage(callerId, "=> " .. playerName)
	end
end

-- Events --------------------------------------------------------------------
function onChatMessage(playerId, playerName, message)
	if string.sub(message, 0, 4) ~= "/vsw" then return end
	if ADMINS[playerName] == nil then MP.SendChatMessage(playerId, "Permissions Denied"); return 1 end
	
	local message = messageSplit(message)
	local size = tableSize(message) - 1
	if size < 1 then message[1] = "help" end
	
	if not COMMANDS[message[1]] then MP.SendChatMessage(playerId, "Unknown Command"); return 1 end
	
	if size < COMMANDS[message[1]].args then MP.SendChatMessage(playerId, "Not enough Args. /vsw " .. message[1] .. " " .. COMMANDS[message[1]].syntax); return 1 end
	
	COMMANDS[message[1]].func(playerId, message)
	return 1
end

function onVehicleSpawn(playerId, vehicleId, vehicleData)
	if ENABLED and not WHITELIST[MP.GetPlayerName(playerId)] then MP.SendChatMessage(playerId, "Permissions to spawn a vehicle denied"); return 1 end
end

-- Init ----------------------------------------------------------------------
function onInit()
	local admins = ADMINS
	ADMINS = {}
	for _, playerName in pairs(admins) do
		ADMINS[playerName] = true
		WHITELIST[playerName] = true
	end
	
	COMMANDS.add = {}
	COMMANDS.add.args = 2
	COMMANDS.add.func = addPlayer
	COMMANDS.add.syntax = '"PlayerName"'
	COMMANDS.remove = {}
	COMMANDS.remove.args = 2
	COMMANDS.remove.func = remPlayer
	COMMANDS.remove.syntax = '"PlayerName"'
	COMMANDS.help = {}
	COMMANDS.help.args = 1
	COMMANDS.help.func = help
	COMMANDS.help.syntax = ""
	COMMANDS.disable = {}
	COMMANDS.disable.args = 1
	COMMANDS.disable.func = disable
	COMMANDS.disable.syntax = ""
	COMMANDS.addall = {}
	COMMANDS.addall.args = 1
	COMMANDS.addall.func = addAll
	COMMANDS.addall.syntax = ""
	COMMANDS.wipe = {}
	COMMANDS.wipe.args = 1
	COMMANDS.wipe.func = wipe
	COMMANDS.wipe.syntax = ""
	COMMANDS.show = {}
	COMMANDS.show.args = 1
	COMMANDS.show.func = show
	COMMANDS.show.syntax = ""
	
	MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
	MP.RegisterEvent("onChatMessage", "onChatMessage")
	print("- VehicleSpawnWhitelist loaded --")
	
	-- testing
	--onChatMessage(-1, "beamcruisebot", "/vsw help")
end
