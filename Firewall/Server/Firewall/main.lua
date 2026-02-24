-- Made by Neverless @ BeamMP. Issues? Feel free to ask.

--[[
	Failed IP checks and failed backend checks will let the player in question successfully join.
	Simply because the ip-api or forum may be unavailable at times.
]]

-- Add hardcoded players you want this script to not handle
-- format: {"player1","player2"}
local EXCEPTIONS = {}

-- Add dynamic players. Reloaded on each new onPlayerAuth
-- format: {"players":["player1","player2"]}
local EXCEPTIONS_FILE = "Resources/Server/Firewall/data/exceptions.json"

-- Settings
-- if you want to allow guests on your server or not
local B_NO_GUESTS = true

-- Will check if the ip comes from a known vpn or proxy and kicks them if the case.
-- A warning: There have been many adverts for VPN's over the past.. so you may be blocking away many players.
local B_CHECK_IP = false

-- Will check the age of the account and kick them if its to young
local B_CHECK_ACCOUNTAGE = true
local MIN_AGE_IN_DAYS = 30 -- minimum account age in days

local MSG_INVALID_IP = "VPN's and Proxy's are not allowed on this Server." -- kick messages
local MSG_PROFILE_HIDDEN = "To play on this server your BeamMP profile must NOT be hidden. This is required to check your account age."
local MSG_INVALID_ACCOUNTAGE = "Your Account is to fresh to join this Server."
local MSG_INVALID_ISGUEST = 'You have to have a BeamMP account from "forum.beammp.com/login" to join this server'


-- Dont touch anything below this line ---------------------------------------

local VERSION = 0.18
local URL_PLAYER_JSON = "https://forum.beammp.com/u/%.json"
local URL_IP_DATA = "http://ip-api.com/json/%?fields=status,message,proxy,hosting"
local HTTP_EXEC = "" -- filled in init, as its dependant on the os the server is running on

-- Basic functions -----------------------------------------------------------
local function split(string, delim)
	local t = {}
	for str in string.gmatch(string, "([^" .. delim .. "]+)") do
		table.insert(t, str)
	end
	return t
end

-- got this method from the nickel plugin.
local function httpRequest(url)
	local response = os.execute(string.gsub(HTTP_EXEC, "%%", url))
	if response == nil then return nil end
	local file = io.open("httpReq_temp.dat", "r")
	local data = file:read("*all")
	file:close()
	-- we are not removing the file on purpose
	return data
end

local function currentDate()
	local t = os.date("*t")
	local d = {}
	d.day = t.day
	d.month = t.month
	d.year = t.year
	return d
end

local function formatBackendDate(birth)
	local t = split(split(birth, "T")[1], "-")
	local d = {}
	d.day = tonumber(t[3])
	d.month = tonumber(t[2])
	d.year = tonumber(t[1])
	return d
end

-- Check Functions -----------------------------------------------------------
local function IsPlayerOldEnough(playerName)
	local request = httpRequest(string.gsub(URL_PLAYER_JSON, "%%", playerName))
	if request == nil then return true end -- shouldnt fail because of the check in init
	local request = Util.JsonDecode(request)
	if type(request) ~= "table" then  -- fails..
		print("FIREWALL Exception. Cannot decode Forum response")
		MP.TriggerGlobalEvent("onScriptMessage", "Exception. Cannot decode forum response", "Firewall")
		return true
	end
	
	if not request.user then
		print("FIREWALL Exception. Forum reponse does not contain the user value")
		MP.TriggerGlobalEvent("onScriptMessage", "Exception. Forum response does not contain .user", "Firewall")
		return true
	end
	
	if request.user.profile_hidden == true then
		return false, 1
	end
	
	if not request.user.created_at then -- fails..
		print("FIREWALL Exception. Forum reponse does not contain the user.created_at value")
		MP.TriggerGlobalEvent("onScriptMessage", "Exception. Forum response does not contain .user.created_at", "Firewall")
		return true
	end
	
	local dif_days = math.floor(os.difftime(os.time(), os.time(formatBackendDate(request.user.created_at))) / (24 * 60 * 60))
	
	if dif_days >= MIN_AGE_IN_DAYS then return true end
	return false, 2
end

local function IsValidIP(IP)
	local request = httpRequest(string.gsub(URL_IP_DATA, "%%", IP))
	if request == nil then return true end -- shouldnt fail because of the check in init
	local request = Util.JsonDecode(request)
	if type(request) ~= "table" then
		print("FIREWALL Exception. IP-API response cannot be decoded")
		MP.TriggerGlobalEvent("onScriptMessage", "Exception. Ip api response is invalid", "Firewall")
		return true
	end
	if request.status == "fail" then -- fails, but we let the player in
		print("FIREWALL Exception. IP-API fails to parse our request")
		MP.TriggerGlobalEvent("onScriptMessage", "Exception. Ip api backend unable to process our request", "Firewall")
		print('REASON "' .. IP .. '" is "' .. request.message .. '"')
		return true
	end
	
	if request.hosting or request.Proxy then return false end -- bad ip
	return true
end

-- Events --------------------------------------------------------------------
function onPlayerAuth(playerName, playerRole, isGuest, player)
	local handle = io.open(EXCEPTIONS_FILE, "r")
	if handle ~= nil then
		local file_exceptions = Util.JsonDecode(handle:read("*all"))
		handle:close()
		if file_exceptions ~= nil then
			for i in pairs(file_exceptions.players) do
				if file_exceptions.players[i] == playerName then return nil end
			end
		end
	end
	if EXCEPTIONS[playerName] then return nil end
	if isGuest and B_NO_GUESTS then
		print('FIREWALL "' .. playerName .. '" no guests allowed')
		MP.TriggerGlobalEvent("onScriptMessage", "Guest player was kicked", "Firewall")
		return MSG_INVALID_ISGUEST
	end
	
	if type(player) == "table" and B_CHECK_IP then
		if not IsValidIP(player.ip) then
			print('FIREWALL "' .. playerName .. '" joins with invalid ip "' .. player.ip .. '"')
			MP.TriggerGlobalEvent("onScriptMessage", "Player using a VPN was kicked", "Firewall")
			return MSG_INVALID_IP
		end
	end
	if B_CHECK_ACCOUNTAGE and not isGuest then
		local isOldEnough, invalidReason = IsPlayerOldEnough(playerName:lower())
		if not isOldEnough then
			if invalidReason == 1 then
				print('FIREWALL "' .. playerName .. '" ' .. MSG_PROFILE_HIDDEN)
				MP.TriggerGlobalEvent("onScriptMessage", "Kickd player. Cannot verify account age. Profile is hidden.", "Firewall")
				return MSG_PROFILE_HIDDEN
			elseif invalidReason == 2 then
				print('FIREWALL "' .. playerName .. '" ' .. MSG_INVALID_ACCOUNTAGE)
				MP.TriggerGlobalEvent("onScriptMessage", "Kicked Player. Account is to young.", "Firewall")
				return MSG_INVALID_ACCOUNTAGE
			end
		end
	end
end

-- Init ----------------------------------------------------------------------
function onInit()
	if MP.GetOSName() == "Windows" then
		HTTP_EXEC = "curl -s % --output httpReq_temp.dat"
	else -- linux
		HTTP_EXEC = "wget -q -O httpReq_temp.dat %"
	end
	
	-- check
	local request = httpRequest(string.gsub(URL_PLAYER_JSON, "%%", "Neverless"))
	if type(request) == "nil" then
		print('FIREWALL. Exception. cannot execute line "' .. HTTP_EXEC .. '"')
		print('FIREWALL ABORTED LOADING')
		return nil
	end
	
	local admins = EXCEPTIONS
	EXCEPTIONS = {}
	for _, playerName in pairs(admins) do
		EXCEPTIONS[playerName] = true
	end

	MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
	
	print("Firewall: No Guests enabled? " .. tostring(B_NO_GUESTS))
	print("Firewall: Check IP? " .. tostring(B_CHECK_IP))
	print("Firewall: Check Account age? " .. tostring(B_CHECK_ACCOUNTAGE))
	print("Firewall: Min Account age? " .. tostring(MIN_AGE_IN_DAYS) .. " days")
	print("------- Firewall Loaded ---------")
	
	--MP.SendChatMessage(-1, "Updated Firewall to v" .. VERSION)
	--onPlayerAuth("Neverless", "USER", false, {})
end
