
local Colors = require("libs/colors")
local SendChatMessage = Colors.SendChatMessage

-- CONSTANTS -----------------------------------------------------------------
local MAXTIME = 60
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
		SendChatMessage(playerId, "^l^c->^r^l Max time is " .. tostring(MAXTIME))
		return 1
	end
	
	LEFTTIME = tonumber(message[1])
	MP.CreateEventTimer("countdown_loop", 1000)
	SendChatMessage(-1, "^l->^6^r^l " .. message[1] .. " Second countdown started by ^b@" .. playerName)
	return 1
end

function countdown()
	LEFTTIME = LEFTTIME - 1
	if LEFTTIME <= 0 then
		SendChatMessage(-1, "^l^a-> GO GO GO !!")
		MP.CancelEventTimer("countdown_loop")
		return nil
	end
	if LEFTTIME <= 2 then
		SendChatMessage(-1, "^l^e-> " .. LEFTTIME)
	elseif LEFTTIME <= 4 then
		SendChatMessage(-1, "^l^6-> " .. LEFTTIME)
	elseif LEFTTIME > 4 then
		SendChatMessage(-1, "^l^c-> " .. LEFTTIME)
	end
end

function onInit()
	MP.CancelEventTimer("countdown_loop")
	MP.RegisterEvent("countdown_loop", "countdown")

	MP.RegisterEvent("onChatMessage", "onChatMessage")
	print("---- Simple Countdown loaded ----")
	
	--onChatMessage(-1, "lol", "/countdown")
end
