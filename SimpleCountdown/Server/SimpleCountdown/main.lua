
-- CONSTANTS -----------------------------------------------------------------
local MAXTIME = 30
local DEFAULTTIME = 10

-- GLOBALS -------------------------------------------------------------------
local LEFTTIME = 0

-- Basic functions -----------------------------------------------------------
local function messageSplit(message)
	local messageSplit = {}
	local nCount = 0
	for i in string.gmatch(message, "%S+") do
		messageSplit[nCount] = i
		nCount = nCount + 1
	end
	
	return messageSplit
end

-- Events --------------------------------------------------------------------
function onChatMessage(playerId, playerName, message)
	if string.sub(message, 0, 10) ~= "/countdown" then return end
	local message = messageSplit(message)
	if #message == 0 then
		message[1] = DEFAULTTIME
	elseif tonumber(message[1]) > MAXTIME then
		MP.SendChatMessage(playerId, "=> Max time is " .. tostring(MAXTIME))
		return 1
	end
	
	LEFTTIME = tonumber(message[1])
	MP.CreateEventTimer("countdown_loop", 1000)
	MP.SendChatMessage(-1, "=> " .. message[1] .. " Second countdown started by " .. playerName)
	return 1
end

function countdown()
	LEFTTIME = LEFTTIME - 1
	if LEFTTIME <= 0 then
		MP.SendChatMessage(-1, "=> GO !!")
		MP.CancelEventTimer("countdown_loop")
		return nil
	end
	MP.SendChatMessage(-1, "=> " .. LEFTTIME)
end

function onInit()
	MP.CancelEventTimer("countdown_loop")
	MP.RegisterEvent("countdown_loop", "countdown")

	MP.RegisterEvent("onChatMessage", "onChatMessage")
	print("---- Simple Countdown loaded ----")
	
	--onChatMessage(-1, "lol", "/countdown")
end
