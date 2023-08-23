print("------------ MapSwap ------------")
-- Made by Neverless @ BeamMP

local SERVERCONFIG = require("ServerConfig")
local RESTARTFILE = "restart"

local MAPS = {}
MAPS["gridmap"] = "/levels/gridmap_v2/info.json"
MAPS["johnson_valley"] = "/levels/johnson_valley/info.json"
MAPS["automation"] = "/levels/automation_test_track/info.json"
MAPS["eastcoast"] = "/levels/east_coast_usa/info.json"
MAPS["hirochi"] = "/levels/hirochi_raceway/info.json"
MAPS["italy"] = "/levels/italy/info.json"
MAPS["jungle"] = "/levels/jungle_rock_island/info.json"
MAPS["industrial"] = "/levels/industrial/info.json"
MAPS["small_island"] = "/levels/small_island/info.json"
MAPS["utah"] = "/levels/utah/info.json"
MAPS["westcoast"] = "/levels/west_coast_usa/info.json"
MAPS["training"] = "/levels/driver_training/info.json"
MAPS["derby"] = "/levels/derby/info.json"
MAPS["nordschleife"] = "/levels/ks_nord/info.json"
MAPS["spa"] = "/levels/ks_spa/info.json"


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


function onChatMessage(playerId, playerName, message)
	if string.sub(message, 0, 4) ~= "/map" then return 0 end
	local message = messageSplit(message)
	
	if tableSize(message) == 1 then message[1] = "help" end
	
	message[1] = string.lower(message[1])
	if MAPS[message[1]] == nil then message[1] = "help" end
	
	if message[1] == "help" then
		for name, _ in pairs(MAPS) do
			MP.SendChatMessage(playerId, "=> " .. name)
		end
		return 1
	end
	
	SERVERCONFIG.Set("General", "Map", MAPS[message[1]])
	local handle = io.open(RESTARTFILE, "w")
	handle:close()
	
	MP.SendChatMessage(-1, "New map has been set to: " .. message[1] .. " by " .. playerName .. ". restart imminent")
	return 1
end

MP.RegisterEvent("onChatMessage", "onChatMessage")
print("--------- MapSwap Loaded --------")