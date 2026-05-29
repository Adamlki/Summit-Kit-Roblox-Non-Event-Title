-- ========================================
-- MODULE: DebugModule
-- Letakkan sebagai child dari DonationServerHandler
-- ========================================

local ConfigModule = require(script.Parent.ConfigModule)

local DebugModule = {}

function DebugModule.log(category, ...)
	if not ConfigModule.DEBUG.ENABLED then return end

	local categorySettings = {
		PLAYER = ConfigModule.DEBUG.SHOW_PLAYER_REQUESTS,
		LOADING = ConfigModule.DEBUG.SHOW_PRODUCT_LOADING,
		CACHE = ConfigModule.DEBUG.SHOW_CACHE_INFO,
		VALIDATION = ConfigModule.DEBUG.SHOW_VALIDATION,
		ERROR = ConfigModule.DEBUG.SHOW_ERRORS,
	}

	if categorySettings[category] then
		print("[" .. category .. "]", ...)
	end
end

function DebugModule.warn(category, ...)
	if not ConfigModule.DEBUG.ENABLED then return end
	if ConfigModule.DEBUG.SHOW_ERRORS then
		warn("[" .. category .. "]", ...)
	end
end

return DebugModule