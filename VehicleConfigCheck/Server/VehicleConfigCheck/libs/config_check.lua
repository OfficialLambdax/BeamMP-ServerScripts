local M = {}

M.script_path = "Resources/Server/VehicleConfigCheck"
M.clientModPath = "Resources/Client"
M.bin_path = M.script_path .. "/bin"
--M.all_parts_path = M.script_path .. "/bin/all_parts.json"
M.all_parts_path = "all_parts.json"
M.vanilla_parts_path = M.script_path .. "/assets/vanilla_parts.json"
M.all_parts = {}

local function run()
	local os_name = MP.GetOSName()
	if os_name == "Windows" then
		os.execute('cd ' .. M.bin_path .. ' & call extract_parts.exe ../../../Client ../../../../all_parts.json --parts-only')
	elseif os_name == "Linux" then
		os.execute('cd ' .. M.bin_path .. '; chmod +x ./extract_parts; ./extract_parts ../../../Client ../../../../all_parts.json --parts-only')
		
		-- custom
		--os.execute('cd ' .. M.bin_path .. '; chmod +x ./extract_parts; ./extract_parts /beammp/Resources/Client /beammp/all_parts.json --parts-only')
	end
end

M.learnParts = function()
	FS.Remove(M.all_parts_path)
	FS.Copy(M.vanilla_parts_path, M.all_parts_path)
	run()
	
	local handle = io.open(M.all_parts_path, "r")
	if handle == nil then return end
	local data = handle:read("*all")
	handle:close()
	
	M.all_parts = Util.JsonDecode(data)
	return true
end

M.isValidJbm = function(jbm)
	return M.all_parts.jbeams[jbm:lower()] ~= nil
end

M.checkConfig = function(jbm, parts)
	if jbm:len() == 0 then return nil end
	jbm = jbm:lower()
	
	local failed_parts = {}
	
	for socket, plug in pairs(parts) do
		if not M.findSocket(jbm, socket) then
			if socket:sub(1, 1) == '/' and socket:sub(-1) == '/' then
				print('BeamMP bug with a socket found: "' .. socket .. '"')
			else
				table.insert(failed_parts, socket)
			end
		end
		
		if plug:len() > 0 then
			if not M.findPlug(jbm, plug) then
				table.insert(failed_parts, plug)
			end
		end
	end
	
	return failed_parts
end

M.findSocket = function(jbm, socket)
	socket = socket:lower()
	if M.all_parts.jbeams[jbm].sockets[socket] then return true end
	if M.all_parts.jbeams.common.sockets[socket] then return true end
	return false
end

M.findPlug = function(jbm, plug)
	plug = plug:lower()
	if M.all_parts.jbeams[jbm].plugs[plug] then return true end
	if M.all_parts.jbeams.common.plugs[plug] then return true end
	return false
end

local function test()
	--[[
	local handle = io.open(M.bin_path .. "/test.pc", "r")
	if handle == nil then return nil end
	local data = handle:read("*all")
	handle:close()
	
	local data = require("./bin/libs/sjson").decode(data)
	print(M.checkConfig(data.model, data.parts))
	]]
	
	--[[
	for player_id, player_name in pairs(MP.GetPlayers() or {}) do
		for vehicle_id, vehicle_data in pairs(MP.GetPlayerVehicles(player_id)) do
			vehicle_data = Util.JsonDecode(vehicleDataTrim(vehicle_data))
			print(vehicle_data.vcf.parts)
			print(M.checkConfig(vehicle_data.vcf.model, vehicle_data.vcf.parts))
		end
	end
	]]
end


M.learnParts()
--M.checkConfig("atv", {atv_body_4x4 = ""})
test()
return M
