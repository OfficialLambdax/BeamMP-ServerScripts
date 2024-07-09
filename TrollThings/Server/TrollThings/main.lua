-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local VERSION = "0.1" -- 09.07.2024 (DD.MM.YYYY)

local M = {}
M.Admins = {"player_1", "player_2"}
M.Commands = {}

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
	print(MP.GetPlayerName(player_id) .. " is considered synced now")
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

-- /troll command
-- or
-- /troll command player_id
function onChatMessage(player_id, player_name, message, is_console)
	if message:sub(1, 6) ~= "/troll" then return nil end
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
	
	M.Commands[message[1]:lower()]({to_playerid = tonumber(message[2]) or -1, from_playerid = player_id})
	return 1
end

function onPlayerJoin(player_id)
	TriggerClientEvent:set_synced(player_id)
end

function onPlayerDisconnect(player_id)
	TriggerClientEvent:remove(player_id)
end

---------------------------------------------------------------------------------------------
-- Init
function onInit()
	local copy = {}
	for _, player_name in pairs(M.Admins) do
		copy[player_name] = true
	end
	M.Admins = copy

	MP.RegisterEvent("onChatMessage", "onChatMessage")
	MP.RegisterEvent("onConsoleInput", "onConsoleInput")
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	
	-- hotreload
	for player_id, _ in pairs(MP.GetPlayers()) do
		onPlayerJoin(player_id)
	end
	
	print("-----. TrollThings loaded .-----")
	
	--onChatMessage(-1, "Neverless", "/troll honk")
end


---------------------------------------------------------------------------------------------
-- Commands
M.Commands.honk = function(data)
	TriggerClientEvent:send(data.to_playerid, "onHonk")
	sleep(1)
	TriggerClientEvent:send(data.to_playerid, "onStopHonk")
end
M.Commands.siren = function(data)
	TriggerClientEvent:send(data.to_playerid, "onSiren")
end
M.Commands.brake = function(data)
	TriggerClientEvent:send(data.to_playerid, "onBrake")
	sleep(1)
	TriggerClientEvent:send(data.to_playerid, "onStopBrake")
end
M.Commands.gas = function(data)
	TriggerClientEvent:send(data.to_playerid, "onGas")
	sleep(1)
	TriggerClientEvent:send(data.to_playerid, "onStopGas")
end
M.Commands.johncena = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "JOHNCENA")
	sleep(2.3)
	TriggerClientEvent:send(data.to_playerid, "onJump", 20)
	sleep(0.5)
	TriggerClientEvent:send(data.to_playerid, "onJump", -40)
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onExplode")
end
M.Commands.boost = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "GASGASGAS")
	sleep(0.5)
	TriggerClientEvent:send(data.to_playerid, "onSpeedBoost", 5)
end
M.Commands.boostbackwards = function(data)
	TriggerClientEvent:send(data.to_playerid, "onSpeedBoost", -10)
end
M.Commands.handbrake = function(data)
	TriggerClientEvent:send(data.to_playerid, "onHandbrake")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopHandbrake")
end
M.Commands.blind = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "blind")
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0")
	sleep(3)
	TriggerClientEvent:send(data.to_playerid, "onStopScreenRGB", "0 0 0")
end
M.Commands.lookback = function(data)
	TriggerClientEvent:send(data.to_playerid, "onLookBack")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopLookBack")
end
M.Commands.moon = function(data)
	TriggerClientEvent:send(data.to_playerid, "onMoonGravity")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onEarthGravity")
end
M.Commands.clutch = function(data)
	TriggerClientEvent:send(data.to_playerid, "onClutch")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopClutch")
end
M.Commands.drift = function(data)
	SendChatMessage(data.from_playerid, "Disabled Command")
	--TriggerClientEvent:send(data.to_playerid, "onPlaySound", "tokyo")
	--sleep(0.1)
	--TriggerClientEvent:send(data.to_playerid, "onDrift")
	--sleep(1)
	--TriggerClientEvent:send(data.to_playerid, "onStopDrift")
end
M.Commands.lookleft = function(data)
	TriggerClientEvent:send(data.to_playerid, "onLookLeft")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopLookLeft")
end
M.Commands.lookright = function(data)
	TriggerClientEvent:send(data.to_playerid, "onLookRight")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopLookRight")
end
M.Commands.turnright = function(data)
	TriggerClientEvent:send(data.to_playerid, "onSteerRight")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopSteerRight")
end
M.Commands.turnleft = function(data)
	TriggerClientEvent:send(data.to_playerid, "onSteerLeft")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onStopSteerLeft")
end
M.Commands.ignition = function(data)
	TriggerClientEvent:send(data.to_playerid, "onIgnitionOff")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onIgnitionOn")
end
M.Commands.iceicebaby = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "iceIceBaby")
	sleep(1)
	TriggerClientEvent:send(data.to_playerid, "onIce")
	sleep(5)
	TriggerClientEvent:send(data.to_playerid, "onStopIce")
end
M.Commands.barrelroll = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "barrelroll")
	sleep(1)
	TriggerClientEvent:send(data.to_playerid, "onJump", 10)
	sleep(0.5)
	TriggerClientEvent:send(data.to_playerid, "onBarrelRoll", -7.5)
	sleep(0.6)
	TriggerClientEvent:send(data.to_playerid, "onBarrelRoll", 5)
end
M.Commands.warning = function(data)
	TriggerClientEvent:send(data.to_playerid, "onWarningSignal")
end
M.Commands.hop = function(data)
	TriggerClientEvent:send(data.to_playerid, "onJump", 3)
end
M.Commands.flashbang = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "Flashbang")
	sleep(2)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "86 86 86")
	sleep(0.5)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "64 64 64")
	sleep(0.5)
	TriggerClientEvent:send(data.to_playerid, "onStopScreenRGB", "0 0 0")
end
M.Commands.changecamera = function(data)
	TriggerClientEvent:send(data.to_playerid, "onChangeCamera")
end
M.Commands.lights = function(data)
	TriggerClientEvent:send(data.to_playerid, "onLights")
end
M.Commands.spin = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "spinMeRightRound")
	TriggerClientEvent:send(data.to_playerid, "onSpin", 10)
end
M.Commands.explode = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "fbiOpenUp")
	sleep(2.5)
	TriggerClientEvent:send(data.to_playerid, "onExplode")
end
M.Commands.backflip = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "backflip")
	sleep(6)
	TriggerClientEvent:send(data.to_playerid, "onJump", 10)
	sleep(0.5)
	TriggerClientEvent:send(data.to_playerid, "onBackflip", -4.5)
end
M.Commands.moveit = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "moveit")
	sleep(0.7)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", -2)
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.01)
	TriggerClientEvent:send(data.to_playerid, "onSpin", 2)
	sleep(0.3)
end
M.Commands.dj = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "Otto")
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0.5")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0.5 0 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 0.5 0")
	sleep(0.3)
	TriggerClientEvent:send(data.to_playerid, "onStopScreenRGB", "0 0 0")
end

M.Commands.snoopdogg = function(data)
	TriggerClientEvent:send(data.to_playerid, "onPlaySound", "snoopdogg")
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onSwitchUILayout", "svc")
	TriggerClientEvent:send(data.to_playerid, "onFullscreenImage", "Smog.gif")
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onDVDImage", "SnoopDogg.gif")
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onScreenRGB", "0 10 0")
	sleep(12)
	TriggerClientEvent:send(data.to_playerid, "onStopScreenRGB", "0 0 0")
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onStopDVDImage", "SnoopDogg.gif")
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onStopFullscreenImage", "Smog.gif")
	sleep(0.1)
	TriggerClientEvent:send(data.to_playerid, "onSwitchUILayout", "multiplayer")
end
