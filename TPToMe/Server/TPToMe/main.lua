-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local VERSION = "0.1" -- 27.03.2025 (DD.MM.YYYY)
local SCRIPT_REF = "CircleTP"

package.loaded[".libs/TriggerClientEvent"] = nil

local Colors = require("./libs/colors")
local TriggerClientEvent = require(".libs/TriggerClientEvent")


---------------------------------------------------------------------------------------------
-- Settings
local SETTINGS = {}

-- Admins are never affected from join limits or kicks
SETTINGS.admins = {"player 1", "player 2"}

---------------------------------------------------------------------------------------------
-- Basics
local function tableSize(table)
	if type(table) ~= "table" then return 0 end
	local len = 0
	for k, v in pairs(table) do
		len = len + 1
	end
	return len
end

local function messageSplit(message)
	local messageSplit = {}
	local nCount = 0
	for i in string.gmatch(message, "%S+") do
		messageSplit[nCount] = i
		nCount = nCount + 1
	end
	
	return messageSplit
end

local function tableInvert(table)
	local temp = {}
	for _, v in pairs(table) do
		temp[v] = true
	end
	return temp
end

---------------------------------------------------------------------------------------------
-- MP Overwrites
local function SendChatMessage(player_id, message)
	Colors.SendChatMessage(player_id, message)
	--if player_id == -2 then
	--	print(message)
	--else
	--	MP.SendChatMessage(player_id, message)
	--end
end

---------------------------------------------------------------------------------------------
-- MP Events
function onConsoleInput(cmd)
	onChatMessage(-2, "", cmd, true)
end

local COMMANDS = {}
function onChatMessage(player_id, player_name, message, is_console)
	if message:sub(1, 3) ~= "/tp" then return nil end
	if not SETTINGS.admins[player_name] and is_console ~= true then return 1 end
	local message = messageSplit(message)
	if tableSize(message) < 2 then message[1] = "help" end
	message[1] = message[1]:lower()
	
	
	if message[1] == "help" then
		SendChatMessage(player_id, "^l^e===-. Global Commands .-===")
		for cmd_name, cmd in pairs(COMMANDS) do
			if cmd[2] == "global" then
				SendChatMessage(player_id, '-> ^l/tp ' .. cmd_name .. ' ' .. cmd[3] .. '^r - ' .. cmd[4])
			end
		end
		
		return 1
	end
	
	if COMMANDS[message[1]] == nil then
		SendChatMessage(player_id, "^l^eUnknown Command")
		return 1
	end
	
	--if SETTINGS.type ~= nil or SETTINGS.type ~= COMMANDS[message[1]][2] then
	--	SendChatMessage(player_id, '^l^eCommand is for a different type. Current: "' .. tostring(SETTINGS.type) .. '" Command: "' .. COMMANDS[message[1]][2] .. '"')
	--	return 1
	--end
	
	COMMANDS[message[1]][1]({from_playerid = player_id, message = message})
	return 1
end

function onPlayerJoin(player_id)
	TriggerClientEvent:set_synced(player_id)
end

function onPlayerDisconnect(player_id)
	TriggerClientEvent:remove(player_id)
end

---------------------------------------------------------------------------------------------
-- init
function onInit()
	print("====. Loading CircleTP .====")
	
	-- invert admins
	local temp = {}
	local admins = ""
	for _, player_name in pairs(SETTINGS.admins) do
		temp[player_name] = true
		admins = admins .. player_name .. " "
	end
	SETTINGS.admins = temp
	print(" > " .. tableSize(SETTINGS.admins) .. " admins have been defined")
	print(" > " .. admins)
	
	-- check commands
	print("--->   Verifying Commands   <---")
	for command_name, cmd in pairs(COMMANDS) do
		local error = false
		if type(cmd[1]) ~= "function" then
			print(' > ERROR: "' .. command_name .. '" has no function at [1]')
			error = true
		end
		if type(cmd[2]) ~= "string" or (cmd[2] ~= "race" and cmd[2] ~= "quali" and cmd[2] ~= "global") then
			print(' > ERROR: "' .. command_name .. '" is not assigned to a group')
			error = true
		end
		if type(cmd[3]) ~= "string" then
			print(' > ERROR: "' .. command_name .. '" arguments are not of type string')
			error = true
		end
		if type(cmd[4]) ~= "string" or cmd[4]:len() == 0 then
			print(' > ERROR: "' .. command_name .. '" describtion is of an invalid format')
			error = true
		end
		if error then COMMANDS[command_name] = nil else
			print(' > Ok: Type "' .. cmd[2] .. '" <- "' .. command_name .. '"')
		end
	end

	-- mp own events
	print("--->   Registering Events   <---")
	MP.RegisterEvent("onChatMessage", "onChatMessage")
	MP.RegisterEvent("onConsoleInput", "onConsoleInput")
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	
	-- hotreload
	if tableSize(MP.GetPlayers()) > 0 then
		print("-->   Performing Hotreload   <--")
		for player_id, player_name in pairs(MP.GetPlayers()) do
			onPlayerJoin(player_id)
		end
	end
	
	print("=====. CircleTP Loaded .====")
end

---------------------------------------------------------------------------------------------
-- Commands
--------------------------------------------
-- Global
COMMANDS.tome = {function(data)
	local vehicles = MP.GetPlayerVehicles(data.from_playerid) or {}
	local id, _ = next(vehicles)
	if not id then
		SendChatMessage(data.from_playerid, 'You do not have a vehicle anyone can be teleported to')
		return
	end
	
	TriggerClientEvent:broadcastExcept(data.from_playerid, "stp_tpto", data.from_playerid .. '-' .. id)
	--TriggerClientEvent:send(-1, "stp_tpto", data.from_playerid .. '-' .. id)
end, "global", "", "Teleport everyone to you"}

COMMANDS.to = {function(data)
	local to_id = data.message[2]
	if not to_id then return end
	
	local vehicle = MP.GetPlayerVehicles(tonumber(to_id)) or {}
	local id, _ = next(vehicle)
	if not id then
		SendChatMessage(data.from_playerid, 'You do not have a vehicle anyone can be teleported to')
		return
	end
	
	TriggerClientEvent:broadcastExcept(tonumber(to_id), "stp_tpto", data.from_playerid .. '-' .. id)
	--TriggerClientEvent:send(-1, "stp_tpto", data.from_playerid .. '-' .. id)
end, "global", "player_id", "Teleport everyone to that player"}
