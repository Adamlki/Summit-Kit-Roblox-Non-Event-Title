-- ========================================
-- MODULE: MessageModule
-- Letakkan sebagai child dari DonationBroadcastHandler
-- ========================================

local BroadcastConfig = require(script.Parent.BroadcastConfig)

local MessageModule = {}

function MessageModule.filterMessage(message)
	-- Trim whitespace
	message = message:gsub("^%s+", ""):gsub("%s+$", "")

	-- Limit length
	if #message > BroadcastConfig.BROADCAST.MAX_MESSAGE_LENGTH then
		message = message:sub(1, BroadcastConfig.BROADCAST.MAX_MESSAGE_LENGTH)
	end

	-- Filter bad words (opsional - tambahkan sesuai kebutuhan)
	-- message = message:gsub("badword", "***")

	return message
end

return MessageModule