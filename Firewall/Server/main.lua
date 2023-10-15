-- Made by Neverless @ BeamMP. Issues? Feel free to ask.

--[[
	Failed IP checks and failed backend checks will let the player in question successfully join.
	Simply because the ip-api or forum may be unavailable at times.
]]

-- Settings
-- if you want to allow guests on your server or not
local B_NO_GUESTS <const> = true

-- Will check if the ip comes from a known vpn or proxy and kicks them if the case.
-- A warning: There have been many adverts for VPN's over the past.. so you may be blocking away many players.
local B_CHECK_IP <const> = false

-- Will check the age of the account and kick them if its to young
local B_CHECK_ACCOUNTAGE <const> = true
local MIN_AGE_IN_MONTH <const> = 3 -- minimum account age in months

local MSG_INVALID_IP <const> = "VPN's and Proxy's are not allowed on this Server." -- kick messages
local MSG_INVALID_ACCOUNTAGE <const> = "Your Account is to fresh to join this Server."
local MSG_INVALID_ISGUEST <const> = "Guests are not allowed on this server"


-- Dont touch anything below this line ---------------------------------------

local VERSION <const> = 0.1
local URL_PLAYER_JSON <const> = "https://forum.beammp.com/u/%.json"
local URL_IP_DATA <const> = "http://ip-api.com/json/%?fields=status,message,proxy,hosting"
local HTTP_EXEC = "" -- filled in init

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
		return true
	end
	
	if not request.user or not request.user.created_at then -- fails..
		print("FIREWALL Exception. Forum reponse does not contain the created_at value")
		return true
	end
	local birth = formatBackendDate(request.user.created_at)
	local date = currentDate()
	local month_dif = ((date.year - birth.year) * 12) + (date.month - birth.month)
	
	if month_dif >= MIN_AGE_IN_MONTH then return true end
	return false
end

local function IsValidIP(IP)
	local request = httpRequest(string.gsub(URL_IP_DATA, "%%", IP))
	if request == nil then return true end -- shouldnt fail because of the check in init
	local request = Util.JsonDecode(request)
	if type(request) ~= "table" then
		print("FIREWALL Exception. IP-API response cannot be decoded")
		return true
	end
	if request.status == "fail" then -- fails, but we let the player in
		print("FIREWALL Exception. IP-API fails to parse our request")
		print('REASON "' .. IP .. '" is "' .. request.message .. '"')
		return true
	end
	
	if request.hosting or request.Proxy then return false end -- bad ip
	return true
end

-- Events --------------------------------------------------------------------
function onPlayerAuth(playerName, playerRole, isGuest, player)
	if isGuest and B_NO_GUESTS then
		print('FIREWALL "' .. playerName .. '" no guests allowed')
		return MSG_INVALID_ISGUEST
	end
	
	if type(player) == "table" then
		if B_CHECK_IP then
			if not IsValidIP(player.ip) then
				print('FIREWALL "' .. playerName .. '" joins with invalid ip "' .. player.ip .. '"')
				return MSG_INVALID_IP
			end
		end
	end
	if B_CHECK_ACCOUNTAGE and not isGuest then
		if not IsPlayerOldEnough(string.lower(playerName)) then
			print('FIREWALL "' .. playerName .. '" account is not old enough')
			return MSG_INVALID_ACCOUNTAGE
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

	MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
	
	print("Firewall: No Guests enabled? " .. tostring(B_NO_GUESTS))
	print("Firewall: Check IP? " .. tostring(B_CHECK_IP))
	print("Firewall: Check Account age? " .. tostring(B_CHECK_ACCOUNTAGE))
	print("Firewall: Min Account age? " .. tostring(MIN_AGE_IN_MONTH) .. " months")
	print("------- Firewall Loaded ---------")
end
