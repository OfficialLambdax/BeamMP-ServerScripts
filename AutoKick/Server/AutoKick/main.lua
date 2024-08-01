-- Made by Neverless @ BeamMP. Issues? Feel free to ask.

--[[
	Todo
		-
]]

-- Admins arent tracked, warned or kicked. And they can temporarely disable the script by sending "/autokick disable" into the chat, AutoKick will be disabled for 60 minutes.
-- format {"PlayerName1", "PlayerName2"}
local ADMINS = {}

-- settings
local WARN_AFK_TIME = 8 -- (default: 8) minutes. Warns the player after this time
local KICK_AFK_TIME = 12 -- (default: 12) minutes. Kicks the player after this time. wont affect players who are still downloading mods
local WARN_EDIT_AMOUNT = 8 -- (default: 8) amount. After this many edits warn the player
local KICK_EDIT_AMOUNT = 10 -- (default: 10) amount. After thic many edits kick the player
local WARN_SPAWN_AMOUNT = 5 -- (default: 5)
local KICK_SPAWN_AMOUNT = 7 -- (default: 7)
local WARN_SPAWN_UNICYCLE_AMOUNT = 3 -- (default: 3)
local KICK_SPAWN_UNICYCLE_AMOUNT = 5 -- (default: 5)

-- this script saves the last time the player performed a edit or spawn.
-- their edits and spawns will be reset back to 0 whenever they havent done any of those actions in the past X minutes.
-- So if a player would spawn KICK_SPAWN_UNICYCLE_AMOUNT within WEAR_SPAWNS_UNICYCLE_EVERY then they are kicked.
local WEAR_EDITS_EVERY = 4 -- (default: 4) minutes
local WEAR_SPAWNS_EVERY = 4 -- (default: 4) minutes
local WEAR_SPAWNS_UNICYCLE_EVERY = 3 -- (default: 3) minutes

local TEMP_BAN = false -- Set to true if you want to temp ban players after they had been kicked for any reason that this script handles.
local TEMP_BAN_AFK_TIME = 0 -- temp ban for this many minutes when kicked for afk. 0 Means no temp ban
local TEMP_BAN_SPAWN_TIME = 0
local TEMP_BAN_EDIT_TIME = 0
local TEMP_BAN_SPAWN_UNICYCLE_TIME = 0

-- will only warn and kick players for the afk reason if the server is filled >= X%
local AFK_KICK_ONLY_IF_SERVERFULL = true -- (default: true)
local AFK_KICK_ONLY_IF_SERVERFULL_PERCENT = 80 -- (default: 80)

-- the script wont warn or kick anyone until that many players are on the server or more.
-- Idea is, that there may just be a single player on the server.. no point kicking them.
-- Also affects the afk kick. no afk warn/kick until this many players and
-- AFK_KICK_ONLY_IF_SERVERFULL_PERCENT, if AFK_KICK_ONLY_IF_SERVERFULL.
local MIN_PLAYERS_UNTIL_ACTIVE = 3 -- (default: 3)

-- message given to the kicked player as their disconnect reason
local MSG_AFK_KICK = "AutoKick: You have been AFK for to long"
local MSG_EDIT_KICK = "AutoKick: If you need to build/tune a car, visit the Garage"
local MSG_SPAWN_KICK = "AutoKick: Dont know why you feel the need to constantly spawn new cars"
local MSG_SPAWN_UNICYCLE_KICK = "AutoKick: Why would you constantly spawn player models"

-- message given to the other players
local MSG_AFK_KICK_BROADCAST = 'AutoKick: "%" appears to have gone afk'
local MSG_EDIT_KICK_BROADCAST = 'AutoKick: "%". Causes to many Ques'
local MSG_SPAWN_KICK_BROADCAST = 'AutoKick: "%". Causes to many Ques'
local MSG_SPAWN_UNICYCLE_BROADCAST = 'AutoKick: "%". Constantly spawned player models'

-- NO NEED TO EDIT ANY OF THE BELOW VARIABLES
-- ----------------------------------------------------------------------------------------

-- Warn message files
--[[ Format
	[name] = String
	[buttonText] = String
	[description] = String
]]
local WARN_AFK_FILE = "/warns/warn_afk.json"
local WARN_EDIT_FILE = "/warns/warn_edit.json"
local WARN_SPAWN_FILE = "/warns/warn_spawn.json"
local WARN_SPAWN_UNICYCLE_FILE = "/warns/warn_spawn_unicycle.json"

-- will just display a warning if the client mod is not found
local AUTOKICK_CLIENT_MOD = "/Client/AutoKick.zip"

-- Warning Message helper
local WARNING_MSG_HELPER_TO_DISK = false -- set true if you want to encode this warning to disk
local WARNING_MSG_HELPER_TEST = false -- set true if you want to test this warning. send to everyone on hotreload.
local WARNING_MSG_HELPER = {
	name = "You are constantly changing your Vehicle",
	buttonText = "understood",
	
	-- accepts new lines and all that stuff
	description = [[[img]/art/image/spawn.jpg[/img]
	You appear to change your car very often. This causes many event ques and depending on the hardware of the other players quite some Lag.
	
	Stop doing that or you may soon be kicked.]],
}


-- NO EDITING BELOW THIS LINE --------------------------------------------

local VERSION = 0.28

-- required to encode the warn messages
local BASE64 = require("libs/base64")
if WARNING_MSG_HELPER_TEST then
	MP.TriggerClientEvent(-1, "autokick_warning", BASE64.encode(Util.JsonEncode(WARNING_MSG_HELPER)))
end

-- required because there is no MP.Get().
-- MP.Settings is a enum and MP.Set is there to set a setting.
-- There is no way to get a setting. wtf lion
local SERVERCONFIG = require("libs/ServerConfig")
local MAX_PLAYERS = SERVERCONFIG.Get("General", "MaxPlayers")
AUTOKICK_CLIENT_MOD = SERVERCONFIG.Get("General", "ResourceFolder") .. AUTOKICK_CLIENT_MOD

-- warn/kick type enum
local KICK_TYPE = {AFK = 0, EDITS = 1, SPAWNS = 2, SPAWNS_UNICYCLE = 3}
local OUR_SCRIPT_PATH = "" -- filled in init

--[[
	[playerId] = table
		[edits] = Int
		[spawns] = Int
		[spawns_unicycle] = Int
		[last_edit] = os.time() or -1
		[last_spawn] = os.time() or -1
		[last_spawn_unicycle] = os.time() or -1
		[afk_since] = time since afk
		[synced] = bool
		[synced_in] = timer
		[vehicles] = table
			[n] = table
				[pos] = laspostable
				[config] = config string
		[warns] = table
			ALL KICK_TYPES = bool
]]
local PLAYERS = {}

--[[
	[playerName] = table
		[at] = os.time()
		[len] = int
]]
local TEMP_BANS = {}

local ENABLED = true
local DISABLED_SINCE = -1

-- Basic functions -----------------------------------------------------------
local function split(string, delim)
	local t = {}
	for str in string.gmatch(string, "([^" .. delim .. "]+)") do
		table.insert(t, str)
	end
	return t
end

local function vehicleDataTrim(vehicleData)
	local start = string.find(vehicleData, "{")
	return string.sub(vehicleData, start, -1)
end

--[[ #var cannot be trusted on zero indexed tablearrays.. eg.
	local table_1 = {}
	print(#table_1) -- will show 0
	local table_2 = {}
	table_2[0] = "some value"
	print(#table_1) -- will also show 0.. fock
]] -- so we have to use this func.
local function tableSize(table)
	if type(table) ~= "table" then return 0 end
	local len = 0
	for _, _ in pairs(table) do
		len = len + 1
	end
	return len
end

local function scriptPath()
	local str = debug.getinfo(2, "S").source:sub(1):gsub("\\", "/")
	local _, pos = str:find(".*/")
	return str:sub(1, pos - 1)
end

local function getWarnFile(name)
	local handle = io.open(OUR_SCRIPT_PATH .. name, "r")
	if handle == nil then print('AutoKick Error: Missing "' .. name .. '"'); return nil end
	local data = handle:read("*all")
	handle:close()
	
	-- check
	local decode = Util.JsonDecode(data)
	if type(decode) ~= "table" then print('AutoKick Error: Cannot decode "' .. name .. '"'); return nil end
	
	if decode.name == nil then print('AutoKick Error: "' .. name .. '" doesnt contain "name"'); return nil end
	if decode.buttonText == nil then print('AutoKick Error: "' .. name .. '" doesnt contain "buttonText"'); return nil end
	if decode.description == nil then print('AutoKick Error: "' .. name .. '" doesnt contain "description"'); return nil end
	
	return BASE64.encode(data) -- as base64 to prevent packet splits by beammp
end

local function getServerFillStatus()
	return math.floor((MP.GetPlayerCount() / MAX_PLAYERS) * 100)
end

-- Structs -------------------------------------------------------------------
local function createPlayerTable()
	local player = {}
	player.edits = 0
	player.spawns = 0
	player.spawns_unicycle = 0
	player.last_edit = -1
	player.last_spawn = -1
	player.last_spawn_unicycle = -1
	player.afk_since = -1
	player.synced = false
	player.synced_in = -1
	player.vehicles = {}
	player.warns = {}
	player.warns.afk = false
	player.warns.edits = false
	player.warns.spawns = false
	player.warns.spawns_unicycle = false
	return player
end

local function createVehicleTable()
	local vehicle = {}
	vehicle.pos = {0, 0, 0}
	vehicle.config = {}
	return vehicle
end

local function createBanTable(banTime)
	local t = {}
	t.at = os.time()
	t.len = banTime
	return t
end

-- Actions -------------------------------------------------------------------
local function warnPlayer(playerId, reason)
	if not ENABLED then return nil end
	local msg = ""
	local playerName = MP.GetPlayerName(playerId)
	if reason == KICK_TYPE.AFK then
		if PLAYERS[playerId].warns.afk then
			print('AutoKick: AFK Warning for "' .. playerName .. '". Previously warned.')
			return nil
		else
			print('AutoKick: AFK Warning send to "' .. playerName .. '"')
			PLAYERS[playerId].warns.afk = true
			msg = getWarnFile(WARN_AFK_FILE)
		end
	elseif reason == KICK_TYPE.EDITS then
		if PLAYERS[playerId].warns.edits then
			print('AutoKick: Edit Warning for "' .. playerName .. '". Previously warned.')
			return nil
		else
			print('AutoKick: Edit Warning send to "' .. playerName .. '"')
			PLAYERS[playerId].warns.edits = true
			msg = getWarnFile(WARN_EDIT_FILE)
		end
	elseif reason == KICK_TYPE.SPAWNS then
		if PLAYERS[playerId].warns.spawns then
			print('AutoKick: Spawn Warning for "' .. playerName .. '". Previously warned.')
			return nil
		else
			print('AutoKick: Spawn Warning send to "' .. playerName .. '"')
			PLAYERS[playerId].warns.spawns = true
			msg = getWarnFile(WARN_SPAWN_FILE)
		end
	elseif reason == KICK_TYPE.SPAWNS_UNICYCLE then
		if PLAYERS[playerId].warns.spawns_unicycle then
			print('AutoKick: SpawnU Warning for "' .. playerName .. '". Previously warned.')
			return nil
		else
			print('AutoKick: SpawnU Warning send to "' .. playerName .. '"')
			PLAYERS[playerId].warns.spawns_unicycle = true
			msg = getWarnFile(WARN_SPAWN_UNICYCLE_FILE)
		end
	else
		print('AutoKick: UNKNOWN WARN REASON "' .. reason .. '"')
		return nil
	end
	
	if msg == nil then return nil end -- error was already printed in getWarnFile()
	MP.TriggerClientEvent(playerId, "autokick_warning", msg)
end

local function kickPlayer(playerId, reason)
	if not ENABLED then return nil end
	local msg = ""
	local msgB = ""
	local banTime = 0
	if reason == KICK_TYPE.AFK then
		msg = MSG_AFK_KICK
		msgB = string.gsub(MSG_AFK_KICK_BROADCAST, "%%", MP.GetPlayerName(playerId))
		banTime = TEMP_BAN_AFK_TIME
	elseif reason == KICK_TYPE.EDITS then
		msg = MSG_EDIT_KICK
		msgB = string.gsub(MSG_EDIT_KICK_BROADCAST, "%%", MP.GetPlayerName(playerId))
		banTime = TEMP_BAN_EDIT_TIME
	elseif reason == KICK_TYPE.SPAWNS then
		msg = MSG_SPAWN_KICK
		msgB = string.gsub(MSG_SPAWN_KICK_BROADCAST, "%%", MP.GetPlayerName(playerId))
		banTime = TEMP_BAN_SPAWN_TIME
	elseif reason == KICK_TYPE.SPAWNS_UNICYCLE then
		msg = MSG_SPAWN_UNICYCLE_KICK
		msgB = string.gsub(MSG_SPAWN_UNICYCLE_BROADCAST, "%%", MP.GetPlayerName(playerId))
		banTime = TEMP_BAN_SPAWN_UNICYCLE_TIME
	else
		print('AutoKick: UNKNOWN KICK REASON "' .. reason .. '". Wont kick.')
		return nil
	end
	
	if TEMP_BAN and banTime > 0 then TEMP_BANS[MP.GetPlayerName(playerId)] = createBanTable(banTime) end
	
	PLAYERS[playerId] = nil
	MP.DropPlayer(playerId, msg)
	MP.SendChatMessage(-1, msgB)
end

-- Ticks ---------------------------------------------------------------------
-- adds and removes players from the PLAYERS table and does a AFK check
-- ticks every 30 seconds.. can tick more often without issue
function tick()
	-- add missing players, remove disconnected cause the onPlayerDisconnected event is unsafe
	local players = MP.GetPlayers()
	for playerId, _ in pairs(players) do
		if PLAYERS[playerId] == nil then PLAYERS[playerId] = createPlayerTable() end
	end
	for playerId, _ in pairs(PLAYERS) do
		if players[playerId] == nil then PLAYERS[playerId] = nil end
	end
	
	-- check afk
	local currenttime = os.time()
	for playerId, playerName in pairs(players) do
		if ADMINS[playerName] == nil and PLAYERS[playerId].synced then
			local vehicles = MP.GetPlayerVehicles(playerId) or {}
			
			-- add missing vehicles, remove deleted
			for vehicleId, vehicleData in pairs(vehicles) do
				if PLAYERS[playerId].vehicles[vehicleId] == nil then
					PLAYERS[playerId].vehicles[vehicleId] = createVehicleTable()
					PLAYERS[playerId].vehicles[vehicleId].config = vehicleDataTrim(vehicleData)
				end
			end
			for vehicleId, _ in pairs(PLAYERS[playerId].vehicles) do
				if vehicles[vehicleId] == nil then
					PLAYERS[playerId].vehicles[vehicleId] = nil
				end
			end
			
			if tableSize(vehicles) == 0 then -- if the player has no vehicles
				local time = PLAYERS[playerId].afk_since
				if time == -1 then PLAYERS[playerId].afk_since = currenttime end
				
			else -- if they have vehicles
				for vehicleId, _ in pairs(vehicles) do -- check posses
					local serverpos = MP.GetPositionRaw(playerId, vehicleId) -- buggs when id has 2 digits
					if type(serverpos) == "table" then -- can be nil because of that
						local currentpos = serverpos.pos
						local lastpos = PLAYERS[playerId].vehicles[vehicleId].pos
						local dist = math.floor(math.sqrt((currentpos[1] - lastpos[1])^2 + (currentpos[2] - lastpos[2])^2 + (currentpos[3] - lastpos[3])^2))
						local vel = math.floor(math.sqrt(serverpos.vel[1]^2 + serverpos.vel[2]^2 + serverpos.vel[3]^2) * 3.6) -- kph
						
						if dist < 100 and vel < 5 then -- didnt move this meters in the last minute
							if PLAYERS[playerId].afk_since == -1 then PLAYERS[playerId].afk_since = os.time() end
						else -- moved
							PLAYERS[playerId].afk_since = -1
							PLAYERS[playerId].warns.afk = false
							
							-- update once moved.. so that the tick rate doesnt influence the afk detection.
							-- so rather then checking dist between last tick and current.. we check dist
							-- between last time they where seen moving and current
							PLAYERS[playerId].vehicles[vehicleId].pos = currentpos
						end
					end
				end
			end
		end
	end
	
	-- warn/kick by afk
	if MP.GetPlayerCount() >= MIN_PLAYERS_UNTIL_ACTIVE and (AFK_KICK_ONLY_IF_SERVERFULL == false or getServerFillStatus() >= AFK_KICK_ONLY_IF_SERVERFULL_PERCENT) then
		for playerId, _ in pairs(PLAYERS) do
			if PLAYERS[playerId].afk_since ~= -1 then
				local diff_minutes = math.floor(os.difftime(currenttime, PLAYERS[playerId].afk_since) / 60)
				--print(os.difftime(currenttime, PLAYERS[playerId].afk_since))
				if diff_minutes >= KICK_AFK_TIME then
					kickPlayer(playerId, KICK_TYPE.AFK)
				elseif diff_minutes >= WARN_AFK_TIME then
					warnPlayer(playerId, KICK_TYPE.AFK)
				end
			end
		end
	end
	
	-- wear edits/spawns
	for playerId, table in pairs(PLAYERS) do
		if table.last_edit ~= -1 and math.floor(os.difftime(currenttime, table.last_edit) / 60) >= WEAR_EDITS_EVERY then
			PLAYERS[playerId].edits = 0
			PLAYERS[playerId].last_edit = -1
			PLAYERS[playerId].warns.edits = false
		end
		if table.last_spawn ~= -1 and math.floor(os.difftime(currenttime, table.last_spawn) / 60) >= WEAR_SPAWNS_EVERY then
			PLAYERS[playerId].spawns = 0
			PLAYERS[playerId].last_spawn = -1
			PLAYERS[playerId].warns.spawns = false
		end
		if table.last_spawn_unicycle ~= -1 and math.floor(os.difftime(currenttime, table.last_spawn_unicycle) / 60) >= WEAR_SPAWNS_UNICYCLE_EVERY then
			PLAYERS[playerId].spawns_unicycle = 0
			PLAYERS[playerId].last_spawn_unicycle = -1
			PLAYERS[playerId].warns.spawns_unicycle = false
		end
	end
	
	-- check disabled
	if not ENABLED then
		if math.floor(os.difftime(currenttime, DISABLED_SINCE) / 60) >= 60 then
			ENABLED = true
			DISABLED_SINCE = -1
			
			-- drop table
			PLAYERS = {}
		end
	end
	
	--print(PLAYERS)
end

-- dynamic.. only ticked once a second when a player joined or on hotreload and only until
-- all players are considered synced.
function synTick() -- if syn required
	local tickmore = false
	local currenttime = os.time()
	for playerId, _ in pairs(PLAYERS) do
		local time = PLAYERS[playerId].synced_in
		if time ~= -1 then
			if os.difftime(currenttime, time) > 10 then
				PLAYERS[playerId].synced_in = -1
				PLAYERS[playerId].synced = true
			else
				tickmore = true
			end
		end
	end
	if not tickmore then MP.CancelEventTimer("AutoKick_syntick") end
end

function tempBanTick()
	local currenttime = os.time()
	for playerName, table in pairs(TEMP_BANS) do
		if math.floor(os.difftime(currenttime, table.at) / 60) >= table.len then
			TEMP_BANS[playerName] = nil
		end
	end
end

-- Events --------------------------------------------------------------------
function onPlayerAuth(playerName, playerRole, isGuest, player)
	if TEMP_BANS[playerName] ~= nil then
		return "AutoKick: You have been Temporarely banned from this Server for " .. TEMP_BANS[playerName].len - math.floor(os.difftime(os.time(), TEMP_BANS[playerName].at) / 60) .. " more minutes"
	end
end

function onPlayerJoining(playerId)
	PLAYERS[playerId].synced_in = os.time()
	MP.CreateEventTimer("AutoKick_syntick", 1000)
end

function onVehicleEdited(playerId, vehicleId, vehicleData)
	if ADMINS[MP.GetPlayerName(playerId)] == true then return nil end
	tick() -- to create the eventually missing tables
	if PLAYERS[playerId].synced == false then -- in case they wherent yet
		PLAYERS[playerId].synced = true
		onVehicleSpawn(playerId, vehicleId, vehicleData)
	end
	
	local vehicleData = vehicleDataTrim(vehicleData)
	local diff = Util.JsonDiff(PLAYERS[playerId].vehicles[vehicleId].config, vehicleData)
	-- if error. even if there is no diff the return is 2 chars long "[]"
	-- but if corrupted json, the return is just a empty string.
	if diff:len() == 0 then
		print("AutoKick Error: Cannot decode VehicleData in onVehicleEdited for player " .. MP.GetPlayerName(playerId) .. ". Deleting vehicle")
		MP.RemoveVehicle(playerId, vehicleId)
		MP.SendChatMessage(playerId, "AutoKick: Your vehicle data is corrupted. Removed vehicle. You may want to approach the admin of this Server is this persists.")
		return nil
	end
	local diff = Util.JsonDecode(diff)
	local jbmChanged = false
	for index, _ in pairs(diff) do
		if diff[index].path == "/pos" then
			diff[index] = nil
		elseif diff[index].path == "/rot" then
			diff[index] = nil
		elseif diff[index].path == "/vid" then
			diff[index] = nil
		elseif diff[index].path == "/jbm" then
			jbmChanged = true
			break
		end
	end
	
	-- if the edit was a jbm change then handle it as a new spawn otherwise as a car config edit
	if jbmChanged then return onVehicleSpawn(playerId, vehicleId, vehicleData) end
	
	PLAYERS[playerId].vehicles[vehicleId].config = vehicleData
	if tableSize(diff) == 0 then return nil end -- no change in the config.. player just pressed the sync button for the luls
	
	if MP.GetPlayerCount() < MIN_PLAYERS_UNTIL_ACTIVE then return nil end
	
	-- add edit
	PLAYERS[playerId].edits = PLAYERS[playerId].edits + 1
	PLAYERS[playerId].last_edit = os.time()
	if PLAYERS[playerId].edits >= KICK_EDIT_AMOUNT then
		kickPlayer(playerId, KICK_TYPE.EDITS)
	elseif PLAYERS[playerId].edits >= WARN_EDIT_AMOUNT then
		warnPlayer(playerId, KICK_TYPE.EDITS)
	end
end

function onVehicleSpawn(playerId, vehicleId, vehicleData)
	if ADMINS[MP.GetPlayerName(playerId)] == true then return nil end
	tick() -- to create the eventually missing tables
	PLAYERS[playerId].synced = true -- in case they wherent yet
	
	PLAYERS[playerId].vehicles[vehicleId] = createVehicleTable()
	PLAYERS[playerId].vehicles[vehicleId].config = vehicleDataTrim(vehicleData)
	
	local vehicleTable = Util.JsonDecode(PLAYERS[playerId].vehicles[vehicleId].config)
	if type(vehicleTable) ~= "table" then
		print("AutoKick Error: Cannot decode VehicleData in onVehicleSpawn for player " .. MP.GetPlayerName(playerId) .. ". Denying spawn")
		
		PLAYERS[playerId].vehicles[vehicleId] = nil
		MP.SendChatMessage(playerId, "AutoKick: Your vehicle data is corrupted. Denied vehicle spawn. You may want to approach the admin of this Server if this persists.")
		return 1 -- denying spawn, smt is messed up with the vehicle json
	end
	
	if MP.GetPlayerCount() < MIN_PLAYERS_UNTIL_ACTIVE then return nil end
	
	-- add spawn
	if vehicleTable.jbm and vehicleTable.jbm == "unicycle" then
		PLAYERS[playerId].spawns_unicycle = PLAYERS[playerId].spawns_unicycle + 1
		PLAYERS[playerId].last_spawn_unicycle = os.time()
		if PLAYERS[playerId].spawns_unicycle >= KICK_SPAWN_UNICYCLE_AMOUNT then
			kickPlayer(playerId, KICK_TYPE.SPAWNS_UNICYCLE)
		elseif PLAYERS[playerId].spawns_unicycle >= WARN_SPAWN_UNICYCLE_AMOUNT then
			warnPlayer(playerId, KICK_TYPE.SPAWNS_UNICYCLE)
		end
	else
		PLAYERS[playerId].spawns = PLAYERS[playerId].spawns + 1
		PLAYERS[playerId].last_spawn = os.time()
		if PLAYERS[playerId].spawns >= KICK_SPAWN_AMOUNT then
			kickPlayer(playerId, KICK_TYPE.SPAWNS)
		elseif PLAYERS[playerId].spawns >= WARN_SPAWN_AMOUNT then
			warnPlayer(playerId, KICK_TYPE.SPAWNS)
		end
	end
end

function onVehicleDeleted(playerId, vehicleId)
	if ADMINS[MP.GetPlayerName(playerId)] == true then return nil end
	tick() -- to create the eventually missing tables
	PLAYERS[playerId].vehicles[vehicleId] = nil
end

function onChatMessage(playerId, playerName, message)
	if message == "/notafk" then
		local diff_minutes = math.floor(os.difftime(os.time(), PLAYERS[playerId].afk_since) / 60)
		if diff_minutes >= WARN_AFK_TIME then
			PLAYERS[playerId].afk_since = -1
			PLAYERS[playerId].warns.afk = false
			MP.SendChatMessage(playerId, "AFK status reset")
		end
		return 1
	elseif message == "/autokick disable" then
		if ADMINS[MP.GetPlayerName(playerId)] == nil then return 1 end
		ENABLED = false
		DISABLED_SINCE = os.time()
		return 1
	end
end

-- Init ----------------------------------------------------------------------
local function onHotreload() -- script is hotreload save, because of this func
	tick()
	for playerId, _ in pairs(PLAYERS) do
		PLAYERS[playerId].synced_in = os.time()
		--PLAYERS[playerId].synced = true -- debug
	end
	MP.CreateEventTimer("AutoKick_syntick", 1000)
	--tick() -- debug
end

function onInit()
	print("======== Loading AutoKick =======")
	print("---------.Version " .. VERSION .. ".----------")
	OUR_SCRIPT_PATH = scriptPath()
	
	if WARNING_MSG_HELPER_TEST then
		local handle = io.open(OUR_SCRIPT_PATH .. "/warning_helper.json", "w")
		handle:write(Util.JsonPrettify(Util.JsonEncode(WARNING_MSG_HELPER)))
		handle:close()
	end
	
	local error = false
	if getWarnFile(WARN_AFK_FILE) == nil then error = true end
	if getWarnFile(WARN_EDIT_FILE) == nil then error = true	end
	if getWarnFile(WARN_SPAWN_FILE) == nil then error = true end
	if getWarnFile(WARN_SPAWN_UNICYCLE_FILE) == nil then error = true end
	if error then
		print("AutoKick Error: ABORTING LOAD. One or multiple Warning files are missing. Script wont function.")
		return nil
	end
	
	if not FS.Exists(AUTOKICK_CLIENT_MOD) then
		print("AutoKick Error: Cannot find the AutoKick.zip client mod.")
		print("AutoKick: Warnings may not be properly displayed to the player.")
	end
	
	-- Array to Object
	-- {0:"name"} -> {"name":true}
	local admins = ADMINS
	ADMINS = {}
	for _, playerName in pairs(admins) do
		ADMINS[playerName] = true
	end

	MP.RegisterEvent("onVehicleEdited", "onVehicleEdited")
	MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
	MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
	MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
	MP.RegisterEvent("onChatMessage","onChatMessage")
	
	MP.CancelEventTimer("AutoKick_tick")
	MP.CreateEventTimer("AutoKick_tick", 30000)
	--MP.CreateEventTimer("AutoKick_tick", 1000) -- debug
	MP.RegisterEvent("AutoKick_tick", "tick")
	
	MP.CancelEventTimer("AutoKick_syntick")
	MP.RegisterEvent("AutoKick_syntick", "synTick")
	
	MP.CancelEventTimer("AutoKick_tempbantick")
	MP.RegisterEvent("AutoKick_tempbantick", "tempBanTick")
	MP.CreateEventTimer("AutoKick_tempbantick", 60000)
	
	onHotreload()
	print("----------. Condition .----------")
	if AFK_KICK_ONLY_IF_SERVERFULL then
		print("- Kicking AFK players only when")
		print("  (" .. math.floor((SERVERCONFIG.Get("General", "MaxPlayers") / 100) * AFK_KICK_ONLY_IF_SERVERFULL_PERCENT) .. "/" .. SERVERCONFIG.Get("General", "MaxPlayers") .. ") Players = " .. AFK_KICK_ONLY_IF_SERVERFULL_PERCENT .. "%")
	else
		print("- Kicking AFK players always")
	end
	if MIN_PLAYERS_UNTIL_ACTIVE > 0 then
		print("- " .. MIN_PLAYERS_UNTIL_ACTIVE .. " Min players before acting")
	else
		print("- Acting even when only 1 Player is online")
	end
	print("-----------. Warnings .----------")
	print("- Warn AFK Time   >-minutes->: " .. WARN_AFK_TIME)
	print("- Warn EDIT Amount           : " .. WARN_EDIT_AMOUNT)
	print("- Warn SPAWN Amount          : " .. WARN_SPAWN_AMOUNT)
	print("- Warn SPAWN_UNICYCLE Amount : " .. WARN_SPAWN_UNICYCLE_AMOUNT)
	print("------------. Kicks .------------")
	print("- Kick AFK Time   >-minutes->: " .. KICK_AFK_TIME)
	print("- Kick EDIT Amount           : " .. KICK_EDIT_AMOUNT)
	print("- Kick SPAWN Amount          : " .. KICK_SPAWN_AMOUNT)
	print("- KICK SPAWN_UNICYCLE Amount : " .. KICK_SPAWN_UNICYCLE_AMOUNT)
	print("-----------. Wearing .-----------")
	print("- EDITS after     >-minutes->: " .. WEAR_EDITS_EVERY)
	print("- SPAWNS after               : " .. WEAR_SPAWNS_EVERY)
	print("- SPAWNS_UNICYCLE after      : " .. WEAR_SPAWNS_UNICYCLE_EVERY)
	print("--------. Temp banning .---------")
	if TEMP_BAN then
		print("- Enabled")
		if TEMP_BAN_AFK_TIME > 0 then print("- AFK Ban time    >-minutes->: " .. TEMP_BAN_AFK_TIME) end
		if TEMP_BAN_EDIT_TIME > 0 then print("- EDIT Ban time              : " .. TEMP_BAN_EDIT_TIME) end
		if TEMP_BAN_SPAWN_TIME > 0 then print("- SPAWN Ban time             : " .. TEMP_BAN_SPAWN_TIME) end
		if TEMP_BAN_SPAWN_UNICYCLE_TIME > 0 then print("- SPAWN_UNICYCLE Ban time    : " .. TEMP_BAN_SPAWN_UNICYCLE_TIME) end
	else
		print("- Disabled")
	end
	print("======== AutoKick loaded ========")
	
	--MP.SendChatMessage(-1, "Updated AutoKick to v" .. VERSION)
	--warnPlayer(0, KICK_TYPE.AFK) -- debug
end
