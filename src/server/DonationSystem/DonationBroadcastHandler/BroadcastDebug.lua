-- ========================================
-- MODULE: BroadcastDebug
-- Letakkan sebagai child dari DonationBroadcastHandler
-- ========================================

local BroadcastConfig = require(script.Parent.BroadcastConfig)

local BroadcastDebug = {}

function BroadcastDebug.log(category, ...)
	if not BroadcastConfig.DEBUG.ENABLED then return end

	local categorySettings = {
		BROADCAST = BroadcastConfig.DEBUG.SHOW_BROADCAST,
		QUEUE = BroadcastConfig.DEBUG.SHOW_QUEUE,
		ERROR = BroadcastConfig.DEBUG.SHOW_ERRORS,
		SECURITY = BroadcastConfig.DEBUG.SHOW_SECURITY,
		LOADING = true,
	}

	if categorySettings[category] then
		print("[" .. category .. "]", ...)
	end
end

function BroadcastDebug.warn(category, ...)
	if not BroadcastConfig.DEBUG.ENABLED then return end
	if BroadcastConfig.DEBUG.SHOW_ERRORS then
		warn("[" .. category .. "]", ...)
	end
end

return BroadcastDebug