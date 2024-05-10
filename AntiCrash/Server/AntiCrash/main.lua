-- Made by Neverless @ BeamMP. Issues? Feel free to ask.

local TIME_UNTIL_SYNC = 10
local TIME_UNTIL_KICK = 10

--[[
	["player_name"] = table
		[is_synced] = bool
		[syn_timer] = nil/os.time()
		[id] = int
		[last_return] = nil/os.time()
]]
local PLAYERS = {}


function checkRoutine()
	for player_name, player in pairs(PLAYERS) do
		if MP.GetPlayerName(player.id) == "" then
			PLAYERS[player_name] = nil
			
		elseif not player.is_synced then
			if os.difftime(os.time(), player.syn_timer) >= TIME_UNTIL_SYNC then
				player.is_synced = true
				player.syn_timer = nil
				player.last_return = os.time()
				print("AntiCrash: " .. player_name .. " is considered synced now")
			end
			
		else
			-- request and check last return
			if os.difftime(os.time(), player.last_return) >= TIME_UNTIL_KICK then
				print("ANTI CRASH PREVENTION. KICKING: " .. player_name)
				MP.DropPlayer(player.id, "Kicked by system")
				PLAYERS[player_name] = nil
			else
				MP.TriggerClientEvent(player.id, "anticrash_check", "")
			end
		end
	end
end

function clientResponse(player_id, void)
	local player_name = MP.GetPlayerName(player_id)
	if player_name == "" then return nil end
	if PLAYERS[player_name] == "" then return nil end
	
	--print("AntiCrash: Got response from: " .. player_name)
	PLAYERS[player_name].last_return = os.time()
end

function onPlayerJoin(player_id)
	local player_name = MP.GetPlayerName(player_id)
	if player_name == "beamcruisebot" then return nil end
	local player = {}
	player.is_synced = false
	player.syn_timer = os.time()
	player.id = player_id
	player.last_return = nil
	PLAYERS[player_name] = player
	print("AntiCrash: New Player " .. player_name)
end

function onInit()
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("anticrash_check", "clientResponse")
	
	MP.CancelEventTimer("AntiCrashRoutine")
	MP.CreateEventTimer("AntiCrashRoutine", 1000)
	MP.RegisterEvent("AntiCrashRoutine", "checkRoutine")
	
	for player_id, _ in pairs(MP.GetPlayers()) do
		onPlayerJoin(player_id)
	end
	
	print("Anti crash loaded")
end


