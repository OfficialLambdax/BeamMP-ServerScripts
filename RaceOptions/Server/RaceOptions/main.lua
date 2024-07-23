-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local VERSION = "0.1" -- 23.07.2024 (DD.MM.YYYY)

local M = {}
M.Admins = {"player_1", "player_2"}
M.Commands = {}
M.IsEnabled = false

---------------------------------------------------------------------------------------------
-- Basics
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

local function sleep(seconds)
	MP.Sleep(math.floor(seconds * 1000))
end

---------------------------------------------------------------------------------------------
-- MP Overwrites
--[[ onPlayerJoin based
	Format
		[players] = table
			["player_id"] = table
				[is_synced] = bool
				[buffer] = table -- unused
]]
local TriggerClientEvent = {}
TriggerClientEvent.players = {}

function TriggerClientEvent:is_synced(player_id)
	return self.players[player_id] or false
end

function TriggerClientEvent:set_synced(player_id)
	self.players[player_id] = true
end

function TriggerClientEvent:remove(player_id)
	self.players[player_id] = nil
end

function TriggerClientEvent:send(player_id, event_name, event_data)
	local send_to = {}
	player_id = tonumber(player_id)
	if player_id ~= -1 then
		table.insert(send_to, player_id)
	else
		for player_id, _ in pairs(MP.GetPlayers()) do
			table.insert(send_to, player_id)
		end
	end
	for _, player_id in pairs(send_to) do
		if not self:is_synced(player_id) then
			print(MP.GetPlayerName(player_id) .. " is not ready yet to receive event data")
		else
			if type(event_data) == "table" then event_data = Util.JsonEncode(event_data) end
			MP.TriggerClientEvent(player_id, event_name, tostring(event_data) or "")
		end
	end
end

function TriggerClientEvent:broadcastExcept(player_id, event_name, event_data)
	for player_id_2, _ in pairs(MP.GetPlayers()) do
		if player_id ~= player_id_2 then
			if not self:is_synced(player_id_2) then
				print(MP.GetPlayerName(player_id_2) .. " is not ready yet to receive event data")
			else
				if type(event_data) == "table" then event_data = Util.JsonEncode(event_data) end
				MP.TriggerClientEvent(player_id_2, event_name, tostring(event_data) or "")			
			end
		end
	end
end

local function SendChatMessage(player_id, message)
	if player_id == -2 then
		print(message)
	else
		MP.SendChatMessage(player_id, message)
	end
end

---------------------------------------------------------------------------------------------
-- Events
function onConsoleInput(cmd)
	onChatMessage(-2, "", cmd, true)
end

-- /rcopt command
-- or
-- /rcopt command player_id
function onChatMessage(player_id, player_name, message, is_console)
	if message:sub(1, 6) ~= "/rcopt" then return nil end
	if not M.Admins[player_name] and is_console ~= true then return 1 end
	local message = messageSplit(message)
	if tableSize(message) < 2 then message[1] = "help" end
	
	if message[1]:lower() == "help" then
		SendChatMessage(player_id, "=> Available Commands")
		for cmd, _ in pairs(M.Commands) do
			SendChatMessage(player_id, "-> " .. cmd)
		end
		
		return 1
	end
	
	if M.Commands[message[1]:lower()] == nil then
		SendChatMessage(player_id, "Unknown Command")
		return 1
	end
	
	M.Commands[message[1]:lower()]({to_playerid = tonumber(message[2]) or -1, from_playerid = player_id, message = message})
	return 1
end

function onPlayerJoin(player_id)
	TriggerClientEvent:set_synced(player_id)
	
	if M.IsEnabled then
		TriggerClientEvent:send(player_id, "raceoptions_enablecompetitivemode")
	else
		TriggerClientEvent:send(player_id, "raceoptions_disablecompetitivemode")
	end
end

function onPlayerDisconnect(player_id)
	TriggerClientEvent:remove(player_id)
end

function onExplosion(player_id, vehicle_id)
	vehicle_id = tonumber(vehicle_id)
	if vehicle_id == nil then return nil end
	if MP.GetPlayerVehicles(player_id)[vehicle_id] == nil then return nil end
	
	TriggerClientEvent:broadcastExcept(player_id, "carbomb_explode", tostring(player_id) .. "-" .. tostring(vehicle_id))
end

---------------------------------------------------------------------------------------------
-- Init
function onInit()
	local copy = {}
	for _, player_name in pairs(M.Admins) do
		copy[player_name] = true
	end
	M.Admins = copy
	
	MP.RegisterEvent("carbomb_exploded", "onExplosion")

	MP.RegisterEvent("onChatMessage", "onChatMessage")
	MP.RegisterEvent("onConsoleInput", "onConsoleInput")
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	
	-- hotreload
	for player_id, _ in pairs(MP.GetPlayers()) do
		onPlayerJoin(player_id)
	end
	print("-----. RaceOptions loaded .-----")
end


---------------------------------------------------------------------------------------------
-- Commands
M.Commands.enable = function(data)
	M.IsEnabled = true
	TriggerClientEvent:send(data.to_playerid, "raceoptions_enablecompetitivemode")
end
M.Commands.disable = function(data)
	M.IsEnabled = false
	TriggerClientEvent:send(data.to_playerid, "raceoptions_disablecompetitivemode")
end
