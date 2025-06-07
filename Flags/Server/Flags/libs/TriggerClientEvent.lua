---------------------------------------------------------------------------------------------
-- Better TriggerClientEvent
--[[
	Format
		[players] = table
			["player_id"] = table
				[is_synced] = bool
]]
local TriggerClientEvent = {}
TriggerClientEvent.players = {}

function TriggerClientEvent:is_synced(player_id)
	return self.players[player_id] or false
end

function TriggerClientEvent:set_synced(player_id)
	self.players[player_id] = true
end

function TriggerClientEvent:remove(player_id)
	self.players[player_id] = nil
end

function TriggerClientEvent:send(player_id, event_name, event_data)
	player_id = tonumber(player_id)
	if type(event_data) == "table" then event_data = Util.JsonEncode(event_data) end
	event_data = tostring(event_data) or ""
	
	local send_to = {}
	if player_id ~= -1 then
		table.insert(send_to, player_id)
	else
		for player_id, _ in pairs(MP.GetPlayers()) do
			table.insert(send_to, player_id)
		end
	end
	for _, player_id in ipairs(send_to) do
		if self:is_synced(player_id) then
			MP.TriggerClientEvent(player_id, event_name, event_data)
		end
	end
end

function TriggerClientEvent:sendTo(player_ids, event_name, event_data)
	if type(event_data) == "table" then event_data = Util.JsonEncode(event_data) end
	event_data = tostring(event_data) or ""
	
	for _, player_id in ipairs(player_ids) do
		if self:is_synced(player_id) then
			MP.TriggerClientEvent(player_id, event_name, event_data)
		end
	end
end

function TriggerClientEvent:broadcastExcept(player_id, event_name, event_data)
	player_id = tonumber(player_id)
	if type(event_data) == "table" then event_data = Util.JsonEncode(event_data) end
	event_data = tostring(event_data) or ""
	
	for player_id_2, _ in pairs(MP.GetPlayers()) do
		if player_id ~= player_id_2 then
			if self:is_synced(player_id_2) then
				MP.TriggerClientEvent(player_id_2, event_name, event_data)
			end
		end
	end
end

return TriggerClientEvent