-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local VERSION = "0.1" -- 28.04.2025 (DD.MM.YYYY)
local SCRIPT_REF = "VehicleConfigCheck"

package.loaded[".libs/TriggerClientEvent"] = nil
package.loaded["./libs/config_check"] = nil

local Colors = require("./libs/colors")
local TriggerClientEvent = require(".libs/TriggerClientEvent")
local ConfigCheck = require("./libs/config_check")


---------------------------------------------------------------------------------------------
-- Settings
local SETTINGS = {}

-- Admins are never affected from join limits or kicks
SETTINGS.admins = {"player_1", "player_2"}

SETTINGS.remove_invalid_vehicles = true


---------------------------------------------------------------------------------------------
-- MP Overwrites
local function SendChatHook(message)
	MP.TriggerGlobalEvent("onScriptMessage", message, SCRIPT_REF)
end

local function SendChatMessage(player_id, message, chat_hook)
	Colors.SendChatMessage(player_id, message)
	if chat_hook then SendChatHook(message) end
end

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

local function vehicleDataTrim(vehicle_data)
	local start = string.find(vehicle_data, "{")
	return string.sub(vehicle_data, start, -1)
end

local function isConfigModded(vehicle_data)
	vehicle_data = Util.JsonDecode(vehicleDataTrim(vehicle_data))
	if vehicle_data.jbm == "unicycle" then return false, vehicle_data.jbm end
	if not ConfigCheck.isValidJbm(vehicle_data.jbm) then
		return true, vehicle_data.jbm
	end
	local diff = ConfigCheck.checkConfig(vehicle_data.jbm, vehicle_data.vcf.parts)
	return #diff > 0, vehicle_data.jbm, diff
end

local function reportModded(send_to, player_id, jbm, diff)
	if not diff then
		SendChatMessage(send_to, '^l^c-->^r^l "' .. MP.GetPlayerName(player_id) .. '" - Illegal jbm^r "' .. jbm .. '"', true)
		
	else
		local collect = ''
		for _, invalid_part in ipairs(diff) do
			collect = collect .. invalid_part .. ', '
		end
		
		SendChatMessage(send_to, '^l^c->^r^l "' .. MP.GetPlayerName(player_id) .. '" - Jbm "' .. jbm .. '" contains illegal parts', true)
		SendChatMessage(send_to, '^l^c-->^r ' .. collect, true)
	end
end

---------------------------------------------------------------------------------------------
-- MP Events
function onConsoleInput(cmd)
	onChatMessage(-2, "", cmd, true)
end

local COMMANDS = {}
function onChatMessage(player_id, player_name, message, is_console)
	if message:sub(1, 4) ~= "/vcc" then return nil end
	if not SETTINGS.admins[player_name] and is_console ~= true then return 1 end
	local message = messageSplit(message)
	if tableSize(message) < 2 then message[1] = "help" end
	message[1] = message[1]:lower()
	
	
	if message[1] == "help" then
		SendChatMessage(player_id, "^l^e===-. Global Commands .-===")
		for cmd_name, cmd in pairs(COMMANDS) do
			if cmd[2] == "global" then
				SendChatMessage(player_id, '-> ^l/vcc ' .. cmd_name .. ' ' .. cmd[3] .. '^r - ' .. cmd[4])
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

function onVehicleSpawn(player_id, vehicle_id, vehicle_data)
	if SETTINGS.admins[MP.GetPlayerName(player_id)] then return end
	local is_modded, jbm, diff = isConfigModded(vehicle_data)
	if not is_modded then
		--SendChatMessage(player_id, '^l^a->^r^l Your vehicle has been verified to not be modded ^6[WIP]^r^l')
		SendChatMessage(-2, '^l^a->^r^l Vehicle of "' .. MP.GetPlayerName(player_id) .. '" has been verified to not be modded ^6[WIP]^r^l')
		
	else
		SendChatMessage(player_id, '^l^cDetected Modded Vehicle^r ^6[WIP]^r If you believe this to be an error then please let me know.')
		reportModded(player_id, player_id, jbm, diff)
		
		if SETTINGS.remove_invalid_vehicles then
			return 1
		else
			SendChatMessage(player_id, '^l^aNot removing vehicle.^r ^lThis may change in the near future')
		end
	end
end

function onVehicleEdited(player_id, vehicle_id, vehicle_data)
	if SETTINGS.admins[MP.GetPlayerName(player_id)] then return end
	local is_modded, jbm, diff = isConfigModded(vehicle_data)
	if not is_modded then
		--SendChatMessage(player_id, '^l^a->^r^l Your vehicle has been verified to not be modded ^6[WIP]^r^l')
		SendChatMessage(-2, '^l^a->^r^l Vehicle of "' .. MP.GetPlayerName(player_id) .. '" has been verified to not be modded ^6[WIP]^r^l')
		
	else
		SendChatMessage(player_id, '^l^cDetected Modded Vehicle^r ^6[WIP]^r If you believe this to be an error then please let me know.')
		reportModded(player_id, player_id, jbm, diff)
		
		if SETTINGS.remove_invalid_vehicles then
			MP.RemoveVehicle(player_id, vehicle_id)
		else
			SendChatMessage(player_id, '^l^aNot removing vehicle.^r ^lThis may change in the near future')
		end
	end
end

---------------------------------------------------------------------------------------------
-- init
function onInit()
	print("====. Loading VCC .====")
	
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
	MP.RegisterEvent("onVehicleEdited", "onVehicleEdited")
	MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
	
	-- hotreload
	if tableSize(MP.GetPlayers()) > 0 then
		for player_id, player_name in pairs(MP.GetPlayers()) do
			local r = onPlayerJoin(player_id)
			if r then
				MP.DropPlayer(player_id, r)
				
			else
				for vehicle_id, vehicle_data in pairs(MP.GetPlayerVehicles(player_id) or {}) do
					if onVehicleSpawn(player_id, vehicle_id, vehicle_data) and SETTINGS.remove_invalid_vehicles then
						MP.RemoveVehicle(player_id, vehicle_id)
					end
				end
			end
		end
		SendChatMessage(-1, '^l^6->^r^l^n "' .. SCRIPT_REF .. '" Script has been modified and reloaded.')
	end
	
	print("=====. VCC Loaded .====")
	onConsoleInput('/vcc check')
end

---------------------------------------------------------------------------------------------
-- Commands
--------------------------------------------
-- Global
COMMANDS.check = {function(data)
	for player_id, player_name in pairs(MP.GetPlayers() or {}) do
		for vehicle_id, vehicle_data in pairs(MP.GetPlayerVehicles(player_id) or {}) do
			local is_modded, jbm, diff = isConfigModded(vehicle_data)
			if not is_modded then
				SendChatMessage(data.from_playerid, '^l^a->^r^l Vehicle of "' .. MP.GetPlayerName(player_id) .. '" is ok')
				
			else
				SendChatMessage(data.from_playerid, '^l^cDetected Modded Vehicle^r^l')
				SendChatMessage(data.from_playerid, '^l^c->^r^l Vehicle of "' .. MP.GetPlayerName(player_id) .. '" is modded')
				reportModded(data.from_playerid, player_id, jbm, diff)
			end
		end
	end
end, "global", "", "Check everyones vehicles of modded parts"}
