-- Made by Neverless @ BeamMP. Issues? Feel free to ask.
local Log = require("libs/Log")

-- ---------------------------------------------------------
-- Settings
local ENABLE = true
local RESTART_AFTER = 24 -- hours
local FORCE_RESTART = false -- if true will restart even if players are on the server at that time
local PLAYER_EXCEPTIONS = {} -- add bot players to this list to be exempt from the player check

-- ---------------------------------------------------------
-- Internal
local TIMER = MP.CreateTimer()
local SCRIPT_REF = "AutoRestart"
local RESTART_TRIGGERED = false

-- ----------------------------------------------------------------------
-- Common
local function getTotalPlayers()
    local total = 0
    local players = MP.GetPlayers()
    if players == nil then return 0 end

    for _, player_name in pairs(players) do
        if not PLAYER_EXCEPTIONS[player_name] then
           total = total + 1
        end
    end

    return total
end

-- ----------------------------------------------------------------------
-- Routine
function routine()
    if not RESTART_TRIGGERED then
        local seconds = TIMER:GetCurrent() -- seconds
        local hours = seconds / 60 / 60
        if hours > RESTART_AFTER and (FORCE_RESTART or getTotalPlayers() == 0) then
            RESTART_TRIGGERED = true
            TIMER:Start()

            Log.info("Restarting Server in 10 seconds", SCRIPT_REF)
            MP.TriggerGlobalEvent("onScriptMessage", "Auto restarting", SCRIPT_REF)
            MP.SendChatMessage(-1, "^l^cSERVER WILL RESTART IN 10 SECONDS")
        end

    else
        if TIMER:GetCurrent() > 10 then
           exit()
        end
    end
end

-- ----------------------------------------------------------------------
-- Events
function onPlayerAuth()
    if RESTART_TRIGGERED then
        return "Server is pending a restart. Try again in a few seconds"
    end
end

-- ----------------------------------------------------------------------
-- Init
function onInit()
    Log.setCollectMode(true)
    Log.load("Initializing", SCRIPT_REF)

    -- kill events in case of hotreload
    MP.CancelEventTimer("autoRestartRoutine")

    if not ENABLE then
       Log.warn("Script is disabled. Aborting load", SCRIPT_REF)
       Log.printCollect()
       return
    end

    if RESTART_AFTER == 0 then
       Log.error("RESTART_AFTER is set to 0 hours. Aborting load", SCRIPT_REF)
       Log.printCollect()
       return
    end
    Log.load("Restarting after " .. RESTART_AFTER .. " hours", SCRIPT_REF)

    local players = {}
    for _, player_name in ipairs(PLAYER_EXCEPTIONS) do
        players[player_name] = true
    end
    PLAYER_EXCEPTIONS = players

    Log.load(#players .. " players are exempt from the player check", SCRIPT_REF)
    if FORCE_RESTART then
        Log.load("Will force restart even if players are online at that point", SCRIPT_REF)
    else
        Log.load("Will wait with restart if players are online", SCRIPT_REF)
    end

    MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
    MP.RegisterEvent("autoRestartRoutine", "routine")
    MP.CreateEventTimer("autoRestartRoutine", 1000)

    Log.ok("Loaded", SCRIPT_REF)

    Log.printCollect()
    Log.setCollectMode(false)
end
