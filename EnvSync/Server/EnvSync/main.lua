-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local VERSION = "0.3" -- 27.05.2025 (DD.MM.YYYY)

--[[ Todo
	- Make the game tick time faster/slower if close to the destination instead of setting it and if game is not paused
	- Hard lock the gravity setting in the client
	- Integrate Admins, that have full power over env and where any change they do to env, immediatly overwrites the servers env
	- Integrate temp sync
		Notes _
		- Temp is regulated in core_environment.onUpdate() from a temp_curve set to a theLevelInfo object.
		scenetree.theLevelinfo:setTemperatureCurveC(temp_curve)
		core_environment.onInit() -- recreate tempcurve cache
		dump(scenetree.theLevelinfo:getTemperatureCurveC())
		temp_curve Format
			[1..n] = table (where n must atleast be 2)
				[1] = float (0 - 1, represents time, see below)
				[2] = float (as temperature in celcisus)
				
			--0-------0.5-------1--
			12:00----24:00----12:00
			
			eg.
			[1] = [ 0  , 20 ]
			[2] = [ 0.5, 10 ]
			[3] = [ 1  , 20 ]
			
			At 12:00 temp will be 20°C
			At 18:00 temp will be 15°C
			At 24:00 temp will be 10°C
			At 06:00 temp will be 15°C
			At 12:00 temp will be 20°C
]]

local M = {}
M.Commands = {}

---------------------------------------------------------------------------------------------
-- Variables

-- Admins. set as eg {"player_1", "player_2"}
M.Admins = {}

-- the server wont sync any environment setting unless this is true. This also means that the players have full control over their env
M.enabled = true

-- set to false if either another script controls gravity, or if you want the players to have full control over gravity
M.syncGravity = true

-- set to false, if time should stop progressing when no player is present
M.progressTimeIfNoPlayer = false

-- Will reset the environment once all players have left the server
-- So if your preset is set to day and the players leave at night, then it will reset back to day, so that no player joins during night
M.resetToPresetWhenServerEmpty = true

--[[
	The game defines time like this, you dont want to change these
		--0-----------0.5-----------1--
		  |            |            |
		12:00--------24:00--------12:00
		
		Day from 0.72507 (05:24) until 0.27443 (18:35)
		Night from 0.27443 (18:35) until 0.72507 (05:24)
	
	core_environment.getState()
		[play] = bool
		[dayScale] = float (0 - 10)
		[nightScale] = float (0 - 10)
		[time] = float (0 - 1)
		[gravity] = float (actual value eg. -9.81)
		[fogDensity] = float (0 - 20000)
		[windSpeed] = float (-1 - 10)
		[cloudCover] = float (0 - 5)
		
		-- unsupported
		[startTime] = float (0 - 1)
		[azimuthOverride] = - (unknown)
		[temperatureC] = float (actual value eg. 27 as celsius)
		
	Game time changes per second (measured)
		1.00 = 0.00055
]]
-- Define a preset in this file which you can save to and load from via commands
M.presetFilePath = "envsync.preset.json"

-- if true, the file is loaded on boot and hotreload, if false the preset from below is used
M.autoLoadPresetFromFile = true

-- Open the ingame environment tab, match the numbers to here. You can also call `print(core_environment.getState())` in the game console to get the raw data from the game
M.preset = {
	play = false, -- true/false
	dayScale = 1, -- 0 - 10
	nightScale = 1, -- 0 - 10
	time = 0, -- 0 - 1
	gravity = -9.8100004196167,
	fogDensity = 0.1, -- 0 - 20000
	windSpeed = 0, -- -1 - 10
	cloudCover = 0 -- 0 - 5
}

-- Dont touch unless you know what you are doing
M.TimeMovePerSecond = 0.00055
M.NightStart = 0.27433
M.NightEnd = 0.72507
M.globalSyncTime = 5000 -- a sync rate in ms

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
------------------------------------Internal barrier-----------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

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

local function inRange(value, min, max)
	return value >= min and value <= max
end

local function prettyTime(seconds) -- MM:SS.MS (eg. 01:13.046 or 00:00.020)
	if not seconds then
		return "N/A"
	end
	local ms = seconds * 1000
	
	return string.format("%.2d:%06.3f", (math.floor(math.fmod(ms, 3600000) / 60000)), (math.fmod(math.fmod(ms, 3600000), 60000) / 1000))
end

local function readJsonFile(file_path)
	local handle = io.open(file_path, "r")
	if handle == nil then return nil end
	local data = handle:read("*all")
	handle:close()
	
	data = Util.JsonDecode(data)
	if data == nil or type(data) == "string" then return nil end
	return data
end

local function writeJsonFile(file_path, data)
	local handle = io.open(file_path, "w")
	if handle == nil then return nil end
	handle:write(Util.JsonPrettify(Util.JsonEncode(data)))
	handle:close()
	return true
end

local function stringToBool(bool)
	if bool == nil then return nil end
	if bool:lower() == "true" then
		return true
	elseif bool:lower() == "false" then
		return false
	end
	return nil
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
			--print(MP.GetPlayerName(player_id) .. " is not ready yet to receive event data")
		else
			if type(event_data) == "table" then event_data = Util.JsonEncode(event_data) end
			MP.TriggerClientEvent(player_id, event_name, tostring(event_data) or "")
		end
	end
end

function TriggerClientEvent:broadcastExcept(player_id, event_name, event_data)
	player_id = tonumber(player_id)
	for player_id_2, _ in pairs(MP.GetPlayers()) do
		if player_id ~= player_id_2 then
			if not self:is_synced(player_id_2) then
				--print(MP.GetPlayerName(player_id_2) .. " is not ready yet to receive event data")
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
-- Precision Timer
local function PrecisionTimer()
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

---------------------------------------------------------------------------------------------
-- Players
--[[ Format
	[id] = table
		[name] = string
		[play] = bool
		[dayScale] = float
		[nightScale] = float
		[time] = float
		[gravity] = float
		[startTime] = float
		[temperatureC] = float
		[fogDensity] = float
		[azimuthOverride] = - (unknown)
		[windSpeed] = float
		[cloudCover] = float
]]
M.Players = {int = {}}
function M.Players:new(player_id)
	local player = {
			int = {
			name = MP.GetPlayerName(player_id),
			play = false,
			dayScale = 0,
			nightScale = 0,
			time = 0,
			gravity = -9.8100004196167,
			startTime = 0,
			temperatureC = 0,
			fogDensity = 0,
			azimuthOverride = 0,
			windSpeed = 0,
			cloudCover = 0
		}
	}
	
	function player:get(name)
		return self.int[name]
	end
	
	function player:set(name, value)
		self.int[name] = value
	end
	
	function player:updateFromTable(table)
		-- data must also be controlled by the server, be of the same type and in the allowed game own range
		-- in any other case its malicious and we wont consider the data.
		
		--print(table)
		
		if type(table.play) == "boolean" then
			self.int.play = table.play
		end
		
		if table.dayScale ~= nil and type(table.dayScale) == "number" then
			self.int.dayScale = table.dayScale
		end
		
		if table.nightScale ~= nil and type(table.nightScale) == "number" then
			self.int.nightScale = table.nightScale
		end
		
		if table.time ~= nil and type(table.time) == "number" and inRange(table.time, 0, 1) then
			self.int.time = table.time
		end
		
		if table.gravity ~= nil and type(table.gravity) == "number" then
			self.int.gravity = table.gravity
		end
		
		if table.temperatureC ~= nil and type(table.temperatureC) == "number" then
			self.int.temperatureC = table.temperatureC
		end
			
		if table.fogDensity ~= nil and type(table.fogDensity) == "number" and inRange(table.fogDensity, 0, 20000) then
			self.int.fogDensity = table.fogDensity
		end
		
		if table.cloudCover ~= nil and type(table.cloudCover) == "number" and inRange(table.cloudCover, 0, 5) then
			self.int.cloudCover = table.cloudCover
		end
		
		if table.windSpeed ~= nil and type(table.windSpeed) == "number" and inRange(table.windSpeed, -1, 10) then
			self.int.windSpeed = table.windSpeed
		end
		
		
		--if table.startTime ~= nil and type(table.startTime) == "number" and inRange(table.startTime, 0, 1) then
		--	self.startTime = table.startTime
		--else print('Player "' .. self.name .. '" send no or invalid data for "startTime"') end
		
		--if table.azimuthOverride ~= nil and type(table.azimuthOverride) == "number" and inRange(table.azimuthOverride, 0, 1) then
	end
	
	function player:diff(table) -- for client vs server. only the diff is updated on the client where server has authority
		local diff = {}
		for k, v in pairs(table) do
			if self.int[k] ~= nil then
				if k == "time" then -- we allow a margin for time
					local diff_time = self.int[k] - v
					if inRange(diff_time, -0.01, 0.01) or inRange(diff_time, -1, -0.99) then
					else
						diff[k] = v
					end
					
				elseif k == "gravity" and not M.syncGravity then
					-- do nothing if gravity sync is not allowed
					
				else
					if type(self.int[k]) == "number" then
						local diff2 = tonumber(string.format("%.3f", self.int[k])) - tonumber(string.format("%.3f", v))
						if diff2 < -0.1 or diff2 > 0.1 then
							diff[k] = v
						end
					else
						if self.int[k] ~= v then diff[k] = v end
					end
				end
			end
		end
		
		-- we cannot properly sync to high time shifts properly, so we wont set time on the clients
		if diff.time ~= nil and (M.ServerTime.dayScale > 20 or M.ServerTime.nightScale > 20) then
			diff.time = nil
		end
		
		if tableSize(diff) == 0 then return nil end
		return diff
	end
	
	function player:updateToTable(table) -- updates the reference
		for k, v in pairs(table) do
			if self.int[k] ~= nil then table[k] = self.int[k] end
		end
	end
	
	self.int[player_id] = player
end

function M.Players:remove(player_id)
	self.int[player_id] = nil
end

function M.Players:diff(table)
	local diff = {}
	for player_id, player in pairs(self.int) do
		diff[player_id] = player:diff(table)
	end
	return diff
end

function M.Players:updateFromTable(player_id, table)
	if self.int[player_id] ~= nil then
		self.int[player_id]:updateFromTable(table)
	end
end

function M.Players:updateToTable(player_id, table) -- updates the reference
	if self.int[player_id] ~= nil then
		self.int[player_id]:updateToTable(table)
	end
end

function M.Players:getAll()
	return self.int
end

function M.Players:getCount()
	return tableSize(self.int)
end

---------------------------------------------------------------------------------------------
-- ServerTime
M.ServerTickTimer = PrecisionTimer()
M.ServerTime = { -- commented are unsupported as of now
	play = M.preset.play or false,
	dayScale = M.preset.dayScale or 1,
	nightScale = M.preset.nightScale or 1,
	time = M.preset.time or 0,
	gravity = M.preset.gravity or -9.8100004196167,
	fogDensity = M.preset.fogDensity or 0.1,
	windSpeed = M.preset.windSpeed or 0,
	cloudCover = M.preset.cloudCover or 0,
	--azimuthOverride = 0, -- idk what this is for
	--startTime = 0, -- cannot be overwritten in the client
	--temperatureC = 16, -- not all maps support it
}

local function setPreset(table)
	for k, v in pairs(table) do
		if type(M.ServerTime[k]) == type(v) then
			M.preset[k] = v
		end
	end
end

local function adaptPreset()
	for k, v in pairs(M.preset) do
		if type(M.ServerTime[k]) == type(v) then
			M.ServerTime[k] = v
		end
	end
end

local function dayLength() -- returns seconds
	local night_length = (M.NightEnd - M.NightStart) / (M.TimeMovePerSecond * M.ServerTime.nightScale)
	local day_length = (1 - (M.NightEnd - M.NightStart)) / (M.TimeMovePerSecond * M.ServerTime.dayScale)
	local total_length = night_length + day_length
	
	--[[ My brain aint braining rn
	local left_length = 0
	local local_time = M.ServerTime.time
	while local_time <= 0.5 do
		if inRange(M.ServerTime.time, M.NightStart, M.NightEnd) then
			left_length = left_length + (M.TimeMovePerSecond * M.ServerTime.nightScale)
		else
			left_length = left_length + (M.TimeMovePerSecond * M.ServerTime.dayScale)
		end
		local_time = local_time + M.TimeMovePerSecond
		if local_time > 1 then local_time = local_time - 1 end
	end
	left_length = local_time * total_length]]
	
	return {
		day_length = day_length,
		night_length = night_length,
		total_length = total_length
		--left_length = left_length
	}
end

local function fullSync()
	if M.syncGravity then
		TriggerClientEvent:send(-1, "envsync_updateenv", M.ServerTime)
	else
		local server_time = {}
		for k, v in pairs(M.ServerTime) do
			if k ~= "gravity" then
				server_time[k] = v
			end
		end
		TriggerClientEvent:send(-1, "envsync_updateenv", server_time)
	end
end

---------------------------------------------------------------------------------------------
-- Routines
function timeTick()
	if M.enabled == false then return nil end
	if not M.progressTimeIfNoPlayer and M.Players:getCount() == 0 then return nil end
	
	-- tick time
	local dt = M.ServerTickTimer:stopAndReset()
	if M.ServerTime.play then
		local time_increase = 0
		if inRange(M.ServerTime.time, M.NightStart, M.NightEnd) then -- if night
			time_increase = (dt / 1000) * (M.TimeMovePerSecond * M.ServerTime.nightScale)
		else -- if day
			time_increase = (dt / 1000) * (M.TimeMovePerSecond * M.ServerTime.dayScale)
		end
		M.ServerTime.time = M.ServerTime.time + time_increase
		while M.ServerTime.time > 1 do
			M.ServerTime.time = M.ServerTime.time - 1
		end
	end
	
	--print(M.ServerTime.time)
	
	-- check players
	local diff = M.Players:diff(M.ServerTime)
	for player_id, diff in pairs(diff) do
		--print("Updating: " .. MP.GetPlayerName(player_id))
		--print(diff)
		TriggerClientEvent:send(player_id, "envsync_updateenv", diff)
	end
end


---------------------------------------------------------------------------------------------
-- Custom Events
function updatePlayer(player_id, raw_msg)
	local decode = Util.JsonDecode(raw_msg)
	if decode == nil or type(decode) == "string" then return nil end
	M.Players:updateFromTable(player_id, decode)
end

---------------------------------------------------------------------------------------------
-- Regular Events
function onConsoleInput(cmd)
	onChatMessage(-2, "", cmd, true)
end

-- /esync command
-- or
-- /esync command arg1 argN
function onChatMessage(player_id, player_name, message, is_console)
	if message:sub(1, 6) ~= "/esync" then return nil end
	if not M.Admins[player_name] and is_console ~= true then return 1 end
	local message = messageSplit(message)
	if tableSize(message) < 2 then message[1] = "help" end
	message[1] = message[1]:lower()
	
	if message[1] == "help" then
		SendChatMessage(player_id, "=> Available Commands")
		for cmd, _ in pairs(M.Commands) do
			SendChatMessage(player_id, "-> " .. cmd)
		end
		
		return 1
	end
	
	if M.Commands[message[1]] == nil then
		SendChatMessage(player_id, "Unknown Command")
		return 1
	end
	
	M.Commands[message[1]]({from_playerid = player_id, message = message})
	return 1
end

function onPlayerJoin(player_id)
	if M.resetToPresetWhenServerEmpty and M.Players:getCount() == 0 then adaptPreset() end
	
	TriggerClientEvent:set_synced(player_id)
	M.Players:new(player_id)
	TriggerClientEvent:send(player_id, "envsync_updatesynctime", M.globalSyncTime)
end

function onPlayerDisconnect(player_id)
	TriggerClientEvent:remove(player_id)
	M.Players:remove(player_id)
end

---------------------------------------------------------------------------------------------
-- Init
function onInit()
	print("------. Loading Envsync .-------")
	local copy = {}
	for _, player_name in pairs(M.Admins) do
		copy[player_name] = true
	end
	M.Admins = copy

	-- Regular Events
	MP.RegisterEvent("onChatMessage", "onChatMessage")
	MP.RegisterEvent("onConsoleInput", "onConsoleInput")
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	
	-- Custom Events
	MP.RegisterEvent("envsync_updateenv", "updatePlayer")
	
	-- internal
	MP.CancelEventTimer("envsync_timetick")
	MP.RegisterEvent("envsync_timetick", "timeTick")
	MP.CreateEventTimer("envsync_timetick", M.globalSyncTime)
	
	-- hotreload
	local players = MP.GetPlayers()
	if tableSize(players) > 0 then
		for player_id, _ in pairs(players) do
			onPlayerJoin(player_id)
		end
		print("=> Hot reloaded " .. tableSize(players) .. " players")
	end
	
	if M.enabled and M.autoLoadPresetFromFile then
		local file_data = readJsonFile(M.presetFilePath)
		if file_data ~= nil then
			setPreset(file_data)
			adaptPreset()
			print("=> Overwritten Preset from file")
		end
	end
	if M.enabled then fullSync() else TriggerClientEvent:send(-1, "envsync_updateenv", "") end
	
	
	print("======= General Settings =======")
	print("-> " .. tableSize(copy) .. " Admins are defined")
	print("=> Sync time is " .. M.globalSyncTime .. " ms")
	if M.syncGravity then
		print("-> HAS AUTHORITY OVER GRAVITY")
	else
		print("-> Has no Authority over gravity")
	end
	print("====== Empty Server Rules ======")
	if M.progressTimeIfNoPlayer then
		print("-> Time keeps progressing")
	else
		print("-> Time progression halts")
	end
	if M.resetToPresetWhenServerEmpty then
		print("-> Env is reset to preset")
	else
		print("-> Env is kept")
	end
	print("=========== Commands ===========")
	print("-> There are " .. tableSize(M.Commands) .. " Commands")
	print('-> Type "/esync" to see all of them')
	print("========= Env Settings =========")
	print("play           : " .. tostring(M.ServerTime.play))
	print("time           : " .. M.ServerTime.time)
	print("dayScale       : " .. M.ServerTime.dayScale)
	print("nightScale     : " .. M.ServerTime.nightScale)
	print("fogDensity     : " .. M.ServerTime.fogDensity)
	print("cloudCover     : " .. M.ServerTime.cloudCover)
	print("windSpeed      : " .. M.ServerTime.windSpeed)
	print("gravity        : " .. M.ServerTime.gravity)
	print("                _ Minutes _")
	local day_length = dayLength()
	print("Day takes      : " .. prettyTime(day_length.day_length))
	print("Night takes    : " .. prettyTime(day_length.night_length))
	print("Total takes    : " .. prettyTime(day_length.total_length))
	print("============ Status ============")
	if M.enabled then
		print("-> Env Script is enabled")
		print("Server has full Authority")
		print("over the environment.")
	else
		print("-> Env Script is disabled")
		print("Players have full Authority")
		print("over the environment")
	end
	print("-------. EnvSync Loaded .-------")
	
	--[[M.Players:new(0)
	M.Players:updateFromTable(0, Util.JsonDecode('{"gravity":-9.8100004196167,"startTime":0.87999999523163,"temperatureC":27.996475577144,"fogDensity":1.0000000474975,"nightScale":5,"azimuthOverride":0,"windSpeed":0.20000000298023,"play":true,"cloudCover":0.40000000596046,"dayScale":5,"time":0.88881057500839}'))
	print(M.Players:diff(M.ServerTime))]]
end


---------------------------------------------------------------------------------------------
-- Commands
M.Commands.updateenv = function(data)
	if data.from_playerid == -2 and data.message[2] == nil then
		print("Unable to sync the clients to the console env. As the console has no Env. try /esync updateenv player_id")
		return nil
	end
	local sync_from = tonumber(data.message[2] or data.from_playerid)
	
	M.Players:updateToTable(sync_from, M.ServerTime)
	M.enabled = true
	SendChatMessage(data.from_playerid, "Environment has been updated and envsync Activated")
end

M.Commands.disable = function(data)
	M.enabled = false
	TriggerClientEvent:send(-1, "envsync_updateenv", "")
	SendChatMessage(data.from_playerid, "Disabled")
end

M.Commands.enable = function(data)
	M.enabled = true
	M.ServerTickTimer:stopAndReset()
	timeTick()
	SendChatMessage(data.from_playerid, "Enabled")
end

M.Commands.sunrise = function(data)
	M.ServerTime.time = 0.77
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Time updated to Sunrise")
end

M.Commands.noon = function(data)
	M.ServerTime.time = 1
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Time updated to Noon")
end

M.Commands.afternoon = function(data)
	M.ServerTime.time = 0.125
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Time updated to Afternoon")
end

M.Commands.sunset = function(data)
	M.ServerTime.time = 0.20
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Time updated to Sunset")
end

M.Commands.night = function(data)
	M.ServerTime.time = 0.375
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Time updated to Night")
end

M.Commands.cloudy = function(data)
	M.ServerTime.cloudCover = 5
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to Cloudy")
end

M.Commands.sunny = function(data)
	M.ServerTime.cloudCover = 0
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to Sunny")
end

--[[ Fog is verry different per map, have to see how to support that
M.Commands.lightfog = function(data)
	M.ServerTime.fogDensity = 2.5
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to Light fog")
end

M.Commands.heavyfog = function(data)
	M.ServerTime.fogDensity = 17.5
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to Heavy fog")
end
]]

M.Commands.slowsun = function(data)
	M.ServerTime.play = true
	M.ServerTime.dayScale = 1
	M.ServerTime.nightScale = 1
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to slow sun")
end

M.Commands.fastsun = function(data)
	M.ServerTime.play = true
	M.ServerTime.dayScale = 100
	M.ServerTime.nightScale = 1000
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to fast sun")
end

M.Commands.hypersun = function(data)
	M.ServerTime.play = true
	M.ServerTime.dayScale = 2000
	M.ServerTime.nightScale = 6000
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to fast sun")
end

M.Commands.extremehypersun = function(data)
	M.ServerTime.play = true
	M.ServerTime.dayScale = 10000
	M.ServerTime.nightScale = 10000
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Set to fast sun")
end

M.Commands.playon = function(data)
	M.ServerTime.play = true
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Enabled time play")
end

M.Commands.playoff = function(data)
	M.ServerTime.play = false
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Disabled time play")
end

M.Commands.dump = function(data)
	SendChatMessage(data.from_playerid, "Dumping to Console")
	print(M.ServerTime)
end

M.Commands.dumpall = function(data)
	SendChatMessage(data.from_playerid, "Dumping Everything to Console")
	print("== Server Time")
	print(M.ServerTime)
	print("== Players")
	print(M.Players)
end

M.Commands.save = function(data)
	if not writeJsonFile(M.presetFilePath, M.ServerTime) then SendChatMessage(data.from_playerid, "Could not save to preset") return nil end
	SendChatMessage(data.from_playerid, "Current Time has been saved")
end

M.Commands.load = function(data)
	local file_data = readJsonFile(M.presetFilePath)
	if file_data == nil then SendChatMessage(data.from_playerid, "Could not read preset from file") return nil end
	
	setPreset(file_data)
	adaptPreset()
	
	M.enabled = true
	fullSync()
	SendChatMessage(data.from_playerid, "Preset has been reinstated")
end

M.Commands.gravitysync = function(data)
	local state = stringToBool(data.message[2])
	if state == nil then SendChatMessage(data.from_playerid, "Need to give true or false as arguments") return nil end
	
	M.syncGravity = state
	if state then
		SendChatMessage(data.from_playerid, "Gravity sync has been enabled")
	else
		SendChatMessage(data.from_playerid, "Gravity sync has been disabled")
	end
end
