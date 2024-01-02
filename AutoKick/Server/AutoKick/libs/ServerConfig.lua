local toml = require("libs/toml") -- requires a edited Toml encoder that does not convert / to /\
local ServerConfig = {
	version = "0.1",
	
	-- you can pull data directly from here but it will throw a error
	-- if the key does not exist
	Config = {},
}

local sf_ServerConfig = "ServerConfig.toml"


function ServerConfig.GetAll()
	if ServerConfig.Config == nil then return nil end
	return tableServerConfig
end

-- will return nil if the value doesnt exist
function ServerConfig.Get(section, key)
	local data = ServerConfig.Config[section]
	if data == nil then return nil end
	return data[key]
end

-- you can only write to already existing keys
function ServerConfig.Set(section, key, value)
	if ServerConfig.Config == nil then return nil, 1 end
	if ServerConfig.Config[section] == nil then return nil, 2 end
	local data = ServerConfig.Config[section]
	if data[key] == nil then return nil, 3 end
	
	data[key] = value
	ServerConfig.Config[section] = data
	
	local handle = io.open(sf_ServerConfig, "w")
	if handle == nil then return nil, 3 end
	handle:write(toml.encode(ServerConfig.Config))
	handle:close()
	
	return true
end

function ServerConfig.Reload()
	local handle = io.open(sf_ServerConfig, "r")
	if handle == nil then return nil, 1 end
	
	ServerConfig.Config = toml.parse(handle:read("*all"))
	handle:close()
end

ServerConfig.Reload()

return ServerConfig