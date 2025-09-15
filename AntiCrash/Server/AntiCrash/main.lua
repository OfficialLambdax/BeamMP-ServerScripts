
local Timer = require("libs/PauseTimer")
local TriggerClientEvent = require("libs/TriggerClientEvent")

local TIME_UNTIL_SYNC = 20 * 1000
local TIME_UNTIL_KICK = 30 * 1000


--[[
	["player_id"] = table
		[is_synced] = bool
		[syn_timer] = Timer
		[last_message] = Timer
]]
local PLAYERS = {}
local LAST_CHECK = Timer.new()

-- ----------------------------------------------------------------------
-- Routine
function checkRoutine()
	if LAST_CHECK:stopAndReset() > 5000 then return end -- server lag
	TriggerClientEvent:send(-1, "anticrash_check")
	
	for player_id, player in pairs(PLAYERS) do
		local player_name = MP.GetPlayerName(player_id)
		if not player.is_synced then
			if player.syn_timer:stop() > TIME_UNTIL_SYNC then
				player.is_synced = true
				player.last_message:stopAndReset()
				print("AntiCrash: " .. player_name .. " is considered synced now")
			end
			
		else
			if player.last_message:stop() > TIME_UNTIL_KICK then
				print("ANTI CRASH PREVENTION. KICKING: " .. player_name)
				MP.TriggerGlobalEvent("onScriptMessage", "Kicking " .. player_name, "AntiCrash")
				MP.DropPlayer(player_id, "Kicked by system")
			end
		end
	end
end

-- ----------------------------------------------------------------------
-- Custom Events
function clientResponse(player_id)
	local player = PLAYERS[player_id]
	if not player then return onPlayerJoin(player_id) end
	
	player.last_message:stopAndReset()
end

-- ----------------------------------------------------------------------
-- MP Events
function onPlayerJoin(player_id)
	local player_name = MP.GetPlayerName(player_id)
	if player_name == "beamcruisebot" then return end
	TriggerClientEvent:set_synced(player_id)
	PLAYERS[player_id] = {
		is_synced = false,
		syn_timer = Timer.new(),
		last_message = Timer.new()
	}
end

function onPlayerDisconnect(player_id)
	TriggerClientEvent:remove(player_id)
	PLAYERS[player_id] = nil
end

-- ----------------------------------------------------------------------
-- Init
function onInit()
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	MP.RegisterEvent("anticrash_check", "clientResponse")
	
	MP.CancelEventTimer("AntiCrashRoutine")
	MP.CreateEventTimer("AntiCrashRoutine", 1000)
	MP.RegisterEvent("AntiCrashRoutine", "checkRoutine")
	
	for player_id, _ in pairs(MP.GetPlayers() or {}) do
		onPlayerJoin(player_id)
	end
	
	print("=====. AntiCrash Loaded .====")
end
