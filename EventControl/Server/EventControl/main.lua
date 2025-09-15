-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local VERSION = "0.5" -- 13.01.2025 (DD.MM.YYYY)
local SCRIPT_REF = "EventControl"

local Colors = require("./libs/colors")

--[[ 
	This script, if enabled, handles two different modes along the requirements for the official events.
	In any mode, admins can always join.
	
	You can always see all commands, their arguments and describtion, by executing in either the chat or server console
		/event
	
	For any of the modes to function the script must be activated (it is activated by default)
		/event enable
		/event disable - disables
	
	Quali
		/event setquali
		/event setlimit player_limit
			eg. /event setlimit 15
		
		Now 15 Players can join. After they have successfully downloaded the mods and fully joined a timer starts running. After SETTINGS.overplayed_after minutes this player is considered to have played enough to not be able to join again. They are not kicked. But if they try to rejoin this or another server the SETTINGS.db_path is synchronized with the script will not allow them to rejoin
		
		Commands
			/event setlimit 15		- will allow 15 players (wont affect admins and admins arent counted)
			/event kickall			- kicks everyone that is not a admin, this way allowing x many more players do join that havent yet qualied
			/event reset			- will reset the database
			.. there is more
	
	Race
		/event setrace
		/event whitelist player1 player2 playerN
		
		Now these players can join.
		
		Commands
			/event wipewhitelist						- will wipe the whitelist but not kick anyone
			/event kickall								- will kick everyone that is not a admin
			/event nextrace player1 player2 playerN		- will kick everyone, wipe the whitelist and set a new
			/event missing								- Will show which of the whitelisted players are missing
	
	
	Changelog
		0.1
			- Added quali and race modes that behave the same. A player can only join once per type. Player is added to db after 5 minutes after onPlayerJoin event
			
		0.2
			- Changed race mode to work by a whitelist
			- Added addtional helpfull information for event controls
			- Colored Chat messages
			
		0.3
			- Added failsafes
			- Reverted some mode definitons from 0.1. DB can no longer accept "race" mode data and is locked to "quali" mode data
			- Added unused PlayersFilterClass
			- Verbose onInit() information
			- Changed SETTINGS.message_*
			- Added SETTINGS.repeat_important_information_every and set it to 60000
			- setquali and setrace now take optional extra arguments to either set the player limit or whitelist directly
			
		0.4
			- Fixed failsafe not removing players that have been rejected by other states in onPlayerAuth
			
		0.5
			- Integrated colors lib
]]

---------------------------------------------------------------------------------------------
-- Settings
local SETTINGS = {}

-- Enable/Disable the script by default (after the server has started). Will not limit server joins if disabled. Can be toggled via command
SETTINGS.enabled = false

-- Admins are never affected from join limits or kicks
SETTINGS.admins = {"Player_1", "Player_N"}

-- The default mode, can only either be nil/"quali"/"race", can be set via command.
SETTINGS.type = nil

-- Repeats errors to the chat in the interval of X ms. These errors are only shown to the admins of this script. Can eg. be `Players cannot join until you define a type "/event setquali" "/event setrace"`
SETTINGS.repeat_important_information_every = 60000 -- as ms

-- Shown when the set player limit is 0 or no type has been set
SETTINGS.message_not_ready_yet = "Event Server is not ready yet. Please wait patiently!"

-- Shown when the joining player is a guest
SETTINGS.message_is_guest = "Sorry but you have to join with a registered account, not as a guest!"

SETTINGS.message_kick_all = "Thank you for joining, time for the next round of drivers!"

---------------------
-- Quali Settings

-- Defines the playerlimit of the server. Does not overwrite the setting from ServerConfig.toml, but rather introduces its own playerlimit without counting admins. Can be set via command
SETTINGS.player_limit = 0

-- if multiple servers are used for quali at the same time, then these pathes must match between the servers. Every server needs to access the same exact files or it wont sync between them.
SETTINGS.db_path = "eventorg_players_played.json"
SETTINGS.db_lockfile = "eventorg_locked"

-- as ms - After this many minutes the player is considered to have played enough to not be able to rejoin in the quali type
SETTINGS.overplayed_after = 1000 * 60 * 5

-- Shown when the player limit has been reached
-- % will be replaced with SETTINGS.player_limit
SETTINGS.message_server_full = "%/% players have already joined! Try next round!"

-- Shown when the player already qualified
SETTINGS.message_competed_already = "Thank you, but you have already participated in the qualification!"

---------------------
-- Race Settings

-- Players in this table can join during race, set via command. {"player_name_n": true}
SETTINGS.player_whitelist = {}

-- Shown when a player joins in the race type that wasnt whitelisted
SETTINGS.message_not_selected_for_race = "You have not been selected for this race. Please wait for your turn!"

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
-- Precision Timer. Adjusted to the game own behaviour
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
-- DB
--[[ DB Format
	["type"] = table
		["player_name"] = true
]]
local DB = {}
function DB:lock()
	self:waitForUnlock()
	local handle = io.open(SETTINGS.db_lockfile, "w")
	if handle == nil then
		print(SCRIPT_REF .. " > FATAL. Cannot lock database")
		return nil
	end
	handle:close()
end

function DB:unlock()
	FS.Remove(SETTINGS.db_lockfile)
end

function DB:waitForUnlock()
	local seconds = 0
	while FS.Exists(SETTINGS.db_lockfile) do
		print(SCRIPT_REF .. " > Waiting for database unlock")
		MP.Sleep(1000)
		seconds = seconds + 1
		if seconds > 10 then
			print(SCRIPT_REF .. " > Breaking out of hangup")
			break
		end
	end
end

function DB:create()
	local handle = io.open(SETTINGS.db_path, "w")
	if handle == nil then
		print(SCRIPT_REF .. " > FATAL. Cannot open database in write mode")
		return nil
	end
	handle:write('{"quali": {}}')
	handle:close()
	return true
end

function DB:load()
	if not FS.Exists(SETTINGS.db_path) then
		if not self:create() then
			return nil
		end
	end
	
	local handle = io.open(SETTINGS.db_path, "r")
	if handle == nil then
		print(SCRIPT_REF .. " > FATAL. Cannot open database in read mode")
		return nil
	end
	local db = handle:read("*all")
	handle:close()
		
	db = Util.JsonDecode(db)
	if type(db) ~= "table" then
		print(SCRIPT_REF .. " > FATAL. Database is corrupted")
		return nil
	end
	
	return db
end

function DB:save(db)
	local handle = io.open(SETTINGS.db_path, "w")
	if handle == nil then
		print(SCRIPT_REF .. " > FATAL. Cannot open database in write mode")
		return nil
	end
	
	handle:write(Util.JsonEncode(db))
	handle:close()
end

function DB:hasCompeted(type, player_name)
	self:lock()
	local db = self:load()
	self:unlock()
	if db == nil then return nil end
	
	return db[type][player_name] == true
end

function DB:setCompeted(player_name, state)
	self:lock()
	local db = self:load()
	if db == nil then
		self:unlock()
		return nil
	end
	
	if state then
		db["quali"][player_name] = true
	else
		db["quali"][player_name] = nil
	end
	self:save(db)
	self:unlock()
	
	return tableSize(db["quali"])
end

function DB:getCompetedCount()
	self:lock()
	local db = self:load()
	self:unlock()
	if db == nil then return nil end
	
	return tableSize(db["quali"])
end

---------------------------------------------------------------------------------------------
-- PlayersClass

--[[ Format
	[int] = table
		[player_name] = Player -- must be based on player_name as its created before the player has a ID
]]
local Players = {int = {}}
function Players:accept(player)
	self.int[player:getPlayerName()] = player
end

function Players:kickAll()
	for _, player in pairs(self.int) do
		if not player:isAdmin() then
			MP.DropPlayer(player:getPlayerId(), SETTINGS.message_kick_all)
		end
	end
end

function Players:get(player_name)
	return self.int[player_name]
end

function Players:getById(player_id)
	return self.int[MP.GetPlayerName(player_id)]
end

function Players:remove(player_name)
	self.int[player_name] = nil
end

function Players:removeById(player_id)
	self.int[MP.GetPlayerName(player_id)] = nil
end

function Players:getPlayers()
	return self.int
end

function Players:getPlayersNoAdmins()
	local temp = {}
	for player_name, player in pairs(self.int) do
		if not player:isAdmin() then
			temp[player_name] = player
		end
	end
	return temp
end

function Players:getPlayerCount()
	return tableCount(self.int)
end

function Players:getPlayerCountNoAdmins()
	local len = 0
	for _, player in pairs(self.int) do
		if not player:isAdmin() then len = len + 1 end
	end
	return len
end

function Players:getNewOverplayed()
	local overplayed = {}
	for player_name, player in pairs(self.int) do
		if player:isSynced() and (player:isOverplayed() == false and player:isAdmin() == false) then
			if player:getTime() >= SETTINGS.overplayed_after then
				overplayed[player_name] = player
			end
		end
	end
	return overplayed
end

function Players:propagateToAdmins(message, print_if_no_admin)
	local count = 0
	for _, player in pairs(self.int) do
		if player:isSynced() and player:isAdmin() then
			SendChatMessage(player:getPlayerId(), message)
			count = count + 1
		end
	end
	if print_if_no_admin and count == 0 then Colors.print(message) end
end

function Players:getUnSyncedPlayerCount()
	local count = 0
	local players = ""
	for player_name, player in pairs(self.int) do
		if not player:isSynced() then
			count = count + 1
			players = players .. player_name .. " "
		end
	end
	return count, players
end

function Players:kickUnsyncedPlayers()
	for _, player in pairs(self.int) do
		if not player:isSynced() then MP.DropPlayer(player:getPlayerId()) end
	end
end

function Players:getPlayersWithNoVehicle()
	local players = ""
	for player_name, player in pairs(self.int) do
		if player:isSynced() and not player:isAdmin() then
			if tableSize(MP.GetPlayerVehicles(player:getPlayerId())) == 0 then
				players = players .. player_name .. " "
			end
		end
	end
	return players
end

local function removePlayer(player_name)
	Players:remove(player_name)
	if SETTINGS.type == "quali" then
		Players:propagateToAdmins(SCRIPT_REF .. ": Player Left " .. Players:getPlayerCountNoAdmins() .. '/' .. SETTINGS.player_limit)
	elseif SETTINGS.type == "race" then
		Players:propagateToAdmins(SCRIPT_REF .. ": Player Left " .. Players:getPlayerCountNoAdmins() .. '/' .. tableSize(SETTINGS.player_whitelist))
	end
end

--[[
	playing around with more code readability by creating filter classes
	
	eg.
	Players:toFilter():isNotAdmin():isSynced():isNotOverplayed():playTimeGreater(SETTINGS.overplayed_after):get()
	
	Players:toFilter():isNotAdmin():get()
]]
function Players:toFilter()
	local filter_class = {int = {}}
	for player_name, player in pairs(self.int) do
		filter_class.int[player_name] = player
	end
	
	function filter_class:get() return self.int end
	function filter_class:getCount() return tableSize(self.int) end
	--[[function filter_class:equals(key, x)
		for player_name, player in pairs(self.int) do
			if player.int[key] ~= x then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:smaller(key, x)
		for player_name, player in pairs(self.int) do
			if player.int[key] < x then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:greater(key, x)
		for player_name, player in pairs(self.int) do
			if player.int[key] > x then
				self.int[player_name] = nil
			end
		end
		return self
	end]]
	function filter_class:isSynced()
		for player_name, player in pairs(self.int) do
			if not player:isSynced() then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:isNotSynced()
		for player_name, player in pairs(self.int) do
			if player:isSynced() then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:isAdmin()
		for player_name, player in pairs(self.int) do
			if not player:isAdmin() then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:isNotAdmin()
		for player_name, player in pairs(self.int) do
			if player:isAdmin() then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:playTimeGreater(x)
		for player_name, player in pairs(self.int) do
			if player:getTime() > x then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:isOverplayed(x)
		for player_name, player in pairs(self.int) do
			if not player:isOverplayed() then
				self.int[player_name] = nil
			end
		end
		return self
	end
	function filter_class:isNotOverplayed(x)
		for player_name, player in pairs(self.int) do
			if player:isOverplayed() then
				self.int[player_name] = nil
			end
		end
		return self
	end
	
	return filter_class
end

---------------------------------------------------------------------------------------------
-- PlayerClass
--[[ Format
	[int] = table
		[is_synced] = bool
		[is_admin] = bool
		[is_overplayed] = bool
		[played_timer] = PrecisionTimer
		[player_id] = number
		[player_name] = string
]]
local Player = {}
function Player:new(player_name)
	local player = {int = {
		is_synced = false,
		is_admin = SETTINGS.admins[player_name] == true,
		is_overplayed = false,
		player_timer = nil,
		player_id = nil,
		player_name = player_name
	}}

	function player:setSynced(state, player_id)
		self.int.is_synced = state
		if state then
			self:setPlayerId(player_id)
		end
	end
	function player:isSynced() return self.int.is_synced end
	function player:setAdmin(state) self,int.is_admin = state end
	function player:isAdmin() return self.int.is_admin end
	function player:setPlayerId(player_id) self.int.player_id = player_id end
	function player:getPlayerId() return self.int.player_id end
	function player:initPlayedTimer() self.int.played_timer = PrecisionTimer() end
	function player:getTime()
		if self.int.played_timer == nil then self:initPlayedTimer() end
		return self.int.played_timer:stop()
	end
	function player:setOverplayed(state) self.int.is_overplayed = state end
	function player:isOverplayed() return self.int.is_overplayed end
	function player:getPlayerName() return self.int.player_name end

	return player
end

---------------------------------------------------------------------------------------------
-- Main Routine
local MESSAGE_TIMER = PrecisionTimer()
function mainRoutine(check_state)
	if not SETTINGS.enabled then return nil end
	
	-- failsafe in case the onPlayerDisconnect event is not called
	local players = tableInvert(MP.GetPlayers())
	for player_name, player in pairs(Players:getPlayers()) do
		if players[player_name] == nil then
			removePlayer(player:getPlayerName())
		end
	end
	
	-- check quali timers per player
	if SETTINGS.type == "quali" then
		local competed = 0
		local competed_new = Players:getNewOverplayed()
		for player_name, player in pairs(competed_new) do
			player:setOverplayed(true)
			
			-- set to db
			competed = DB:setCompeted(player_name, true)
			print(SCRIPT_REF .. ' > "' .. player_name .. '" will not be able to rejoin from now on')
		end
		if competed > 0 then
			Players:propagateToAdmins("^l" .. SCRIPT_REF .. ": ^6+" .. tableSize(competed_new) .. "^r^l more have competed. Total ^6" .. competed)
		end
	end
	
	if check_state or MESSAGE_TIMER:stop() > SETTINGS.repeat_important_information_every then
		MESSAGE_TIMER:stopAndReset()
		local error = false
		if SETTINGS.type == nil then
			Players:propagateToAdmins("^l^c" .. SCRIPT_REF .. ': Players cannot join until you define a type "/event setquali" "/event setrace"', true)
			error = true
		end
		
		if SETTINGS.type == "quali" then
			if SETTINGS.player_limit <= 0 then
				Players:propagateToAdmins("^l^c" .. SCRIPT_REF .. ': Quali mode requires a player limit "/event setlimit X"', true)
				error = true
			end
			
		elseif SETTINGS.type == "race" then
			if tableSize(SETTINGS.player_whitelist) == 0 then
				Players:propagateToAdmins("^l^c" .. SCRIPT_REF .. ': Race mode requires set players in the whitelist "/event whitelist player1 playerN"', true)
				error = true
			end
		end
		
		local missing, players = Players:getUnSyncedPlayerCount()
		if missing > 0 then
			Players:propagateToAdmins("^l" .. SCRIPT_REF .. ": " .. missing .. " players are still in the joining process: ^6" .. players)
			error = true
		end
		local missing = Players:getPlayersWithNoVehicle()
		if missing:len() > 0 then
			Players:propagateToAdmins("^l" .. SCRIPT_REF .. ": Players with no vehicle: ^6" .. missing)
			error = true
		end
		
		if check_state and not error then
			Players:propagateToAdmins("^l^a" .. SCRIPT_REF .. ": Nothing is missing, good to go!")
		end
	end
end

---------------------------------------------------------------------------------------------
-- MP Events
function onPlayerAuth(player_name, player_role, is_guest, player_identifiers)
	if is_guest then
		return SETTINGS.message_is_guest
	end
	
	local player = Player:new(player_name)
	if player:isAdmin() then
		Players:accept(player)
		return nil
	end
	
	if SETTINGS.enabled then
		if SETTINGS.type == nil then
			return SETTINGS.message_not_ready_yet
		end
		
		if SETTINGS.type == "quali" then
			if SETTINGS.player_limit == 0 then
				return SETTINGS.message_not_ready_yet
				 
			elseif Players:getPlayerCountNoAdmins() >= SETTINGS.player_limit then
				return string.gsub(SETTINGS.message_server_full, "%%", SETTINGS.player_limit)
			end
			
			-- check if played already
			if DB:hasCompeted(SETTINGS.type, player_name) then
				return SETTINGS.message_competed_already
			end
			
			Players:propagateToAdmins(SCRIPT_REF .. ": Player Joining " .. Players:getPlayerCountNoAdmins() + 1 .. '/' .. SETTINGS.player_limit)
			
		elseif SETTINGS.type == "race" then
			if tableSize(SETTINGS.player_whitelist) == 0 then
				return SETTINGS.message_not_ready_yet
				
			elseif not SETTINGS.player_whitelist[player_name:lower()] then
				return SETTINGS.message_not_selected_for_race
			end
			
			Players:propagateToAdmins(SCRIPT_REF .. ": Player Joining " .. Players:getPlayerCountNoAdmins() + 1 .. '/' .. tableSize(SETTINGS.player_whitelist))
		end
	end
	
	Players:accept(player)
end

function onPlayerJoin(player_id)
	Players:getById(player_id):setSynced(true, player_id)
end

function onPlayerDisconnect(player_id)
	removePlayer(MP.GetPlayerName(player_id))
end

function onConsoleInput(cmd)
	onChatMessage(-2, "", cmd, true)
end

local COMMANDS = {}
function onChatMessage(player_id, player_name, message, is_console)
	if message:sub(1, 6) ~= "/event" then return nil end
	if not SETTINGS.admins[player_name] and is_console ~= true then return 1 end
	local message = messageSplit(message)
	if tableSize(message) < 2 then message[1] = "help" end
	message[1] = message[1]:lower()
	
	
	if message[1] == "help" then
		SendChatMessage(player_id, "^l^e===-. Global Commands .-===")
		for cmd_name, cmd in pairs(COMMANDS) do
			if cmd[2] == "global" then
				SendChatMessage(player_id, '-> ^l/event ' .. cmd_name .. ' ' .. cmd[3] .. '^r - ' .. cmd[4])
			end
		end
		SendChatMessage(player_id, "^l^e===-. Quali Commands .-===")
		for cmd_name, cmd in pairs(COMMANDS) do
			if cmd[2] == "quali" then
				SendChatMessage(player_id, '-> ^l/event ' .. cmd_name .. ' ' .. cmd[3] .. '^r - ' .. cmd[4])
			end
		end
		SendChatMessage(player_id, "^l^e===-. Race Commands .-===")
		for cmd_name, cmd in pairs(COMMANDS) do
			if cmd[2] == "race" then
				SendChatMessage(player_id, '-> ^l/event ' .. cmd_name .. ' ' .. cmd[3] .. '^r - ' .. cmd[4])
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

---------------------------------------------------------------------------------------------
-- init
function onInit()
	print("====. Loading EventControl .====")
	
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
	
	-- failsafe
	if FS.Exists(SETTINGS.db_lockfile) then FS.Remove(SETTINGS.db_lockfile) end
	
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
	MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	MP.RegisterEvent("onChatMessage", "onChatMessage")
	MP.RegisterEvent("onConsoleInput", "onConsoleInput")
	
	-- routines
	print("-->   Registering Routines   <--")
	MP.CancelEventTimer("event_mainroutine")
	MP.RegisterEvent("event_mainroutine", "mainRoutine")
	MP.CreateEventTimer("event_mainroutine", 10000)
	
	-- hotreload
	if tableSize(MP.GetPlayers()) > 0 then
		print("-->   Performing Hotreload   <--")
		for player_id, player_name in pairs(MP.GetPlayers()) do
			local temp = onPlayerAuth(player_name, MP.GetPlayerIdentifiers(player_id))
			if type(temp) == "string" or temp == 1 then
				MP.DropPlayer(player_id)
			else
				onPlayerJoin(player_id)
			end
		end
		Players:propagateToAdmins("^l=============================")
		Players:propagateToAdmins("^l" .. SCRIPT_REF .. " has been hotreloaded")
		Players:propagateToAdmins("^l=============================")
	end
	
	print("=====. EventControl Loaded .====")
	mainRoutine(true)
end

---------------------------------------------------------------------------------------------
-- Commands
--------------------------------------------
-- Global
COMMANDS.enable = {function(data)
	SETTINGS.enabled = true
	SendChatMessage(data.from_playerid, "^l^aScript has been enabled")
	mainRoutine(true)
end, "global", "", "Enables the script"}

COMMANDS.disable = {function(data)
	SETTINGS.type = nil
	SETTINGS.player_limit = 0
	SETTINGS.enabled = false
	SETTINGS.player_whitelist = {}
	SendChatMessage(data.from_playerid, "^l^aScript has been disabled")
end, "global", "", "Disables the script"}

COMMANDS.kickall = {function(data)
	Players:kickAll()
	SendChatMessage(data.from_playerid, "^l^aAll non Admins have been kicked")
end, "global", "", "Kicks all non Admin players"}

COMMANDS.info = {function(data)
	SendChatMessage(data.from_playerid, "Version: " .. VERSION)
	
	if SETTINGS.enabled then
		SendChatMessage(data.from_playerid, "Script is enabled")
	else
		SendChatMessage(data.from_playerid, "Script is disabled")
	end
	
	if SETTINGS.type == nil then
		SendChatMessage(data.from_playerid, "No type selected")
		
	elseif SETTINGS.type == "quali" then
		SendChatMessage(data.from_playerid, "Qualification is selected")
		SendChatMessage(data.from_playerid, "Player Limit: " .. SETTINGS.player_limit)
		
	elseif SETTINGS.type == "race" then
		SendChatMessage(data.from_playerid, "Racing is selected")
		SendChatMessage(data.from_playerid, "Whitelisted players: " .. tableSize(SETTINGS.player_whitelist))
	end
	mainRoutine(true)
end, "global", "", "Returns version and current settings"}

COMMANDS.kickunsynced = {function(data)
	Players:kickUnsyncedPlayers()
	SendChatMessage(data.from_playerid, "^l^aKicked all unsynced players")
end, "global", "", "Kicks all unsynced players"}

--------------------------------------------
-- Quali Commands
COMMANDS.setquali = {function(data)
	SETTINGS.type = "quali"
	SendChatMessage(data.from_playerid, "^l^aType has been set to quali")
	
	if data.message[2] ~= nil then
		data.no_check = true
		COMMANDS.setlimit[1](data)
	end
	
	local competed = DB:getCompetedCount()
	if competed == nil then
		SendChatMessage(data.from_playerid, "^l^cERROR: Cannot open Database in read mode")
	elseif competed > 0 then
		SendChatMessage(data.from_playerid, "^l^e" .. competed .. " player(s) already competed")
	else
		SendChatMessage(data.from_playerid, "^l^eNo Player has competed yet")
	end
	mainRoutine(true)
end, "quali", "player_limit", "Sets the type to quali"}

COMMANDS.setlimit = {function(data)
	local player_limit = tonumber(data.message[2])
	if player_limit == nil then
		SendChatMessage(data.from_playerid, "^l^eMust give a integer as a player limit")
		return nil
	end
	
	SETTINGS.player_limit = player_limit
	SendChatMessage(data.from_playerid, "^l^aLimit has been set to " .. player_limit)
	if not data.no_check then mainRoutine(true) end
end, "quali", "player_limit", "Sets a playerlimit"}

COMMANDS.reset = {function(data)
	if data.message[2] == nil or data.message[2]:lower() ~= "yes" then
		return SendChatMessage(data.from_playerid, '^l^eSafety. Please type "/event reset yes" to delete the database')
	end
	DB:lock()
	FS.Remove(SETTINGS.db_path)
	DB:unlock()
	SendChatMessage(data.from_playerid, "^l^aDatabase has been reset")
end, "quali", "", "Resets the Database"}

COMMANDS.remove = {function(data)
	if data.message[2] == nil then return SendChatMessage(data.from_playerid, "^l^eMust give a player name") end
	DB:setCompeted(data.message[2], false)
	SendChatMessage(data.from_playerid, "^l^aPlayer has been removed from the database")
end, "quali", "player_name", "Remove the player from the database, allowing them to rejoin"}

--------------------------------------------
-- Race commands
COMMANDS.setrace = {function(data)
	SETTINGS.player_whitelist = {}
	SETTINGS.type = "race"
	SendChatMessage(data.from_playerid, "^l^aType has been set to race")
	
	if data.message[2] ~= nil then COMMANDS.whitelist[1](data) end
	
	mainRoutine(true)
end, "race", "Player1 PlayerN", "Sets the type to race"}

COMMANDS.whitelist = {function(data)
	if data.message[2] == nil then return SendChatMessage(data.from_playerid, "^l^eNo players given to whitelist") end
	
	for i = 2, #data.message, 1 do
		SETTINGS.player_whitelist[data.message[i]:lower()] = true
	end
	
	SendChatMessage(data.from_playerid, "^l^a" .. tableSize(SETTINGS.player_whitelist) .. " players are now whitelisted")
end, "race", "Player1 PlayerN", "Adds the given players to the whitelist"}

COMMANDS.wipewhitelist = {function(data)
	SETTINGS.player_whitelist = {}
	SendChatMessage(data.from_playerid, "^l^aPlayer whitelist has been reset")
end, "race", "", "Wipes the whitelist. Race only"}

COMMANDS.nextrace = {function(data)
	COMMANDS.kickall[1](data)
	COMMANDS.wipewhitelist[1](data)
	COMMANDS.whitelist[1](data)
end, "race", "Player1 PlayerN", "A quick next race command. Kicks everyone, wipes the whitelist and sets a new"}

COMMANDS.missing = {function(data)
	local missing = ""
	for player_name, _ in pairs(SETTINGS.player_whitelist) do
		if Players:get(player_name) == nil then
			missing = missing .. player_name .. ", "
		end
	end
	if missing:len() == 0 then
		SendChatMessage(data.from_playerid, "^l^aNo player is missing")
	else
		SendChatMessage(data.from_playerid, "^lThese players are missing: ^e" .. missing)
	end
end, "race", "", "Shows which of the whitelisted players are missing"}
