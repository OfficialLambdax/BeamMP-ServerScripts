local M = {}

local function check(void)
	TriggerServerEvent("anticrash_check", "")
end

local function onWorldReadyState()
    if worldReadyState == 2 then
		if AddEventHandler then
			AddEventHandler("anticrash_check", check)
		end
    end
end

M.onWorldReadyState = onWorldReadyState
return M