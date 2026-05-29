-- ========================================
-- MODULE: BroadcastConfig
-- Letakkan sebagai child dari DonationBroadcastHandler
-- ========================================

local BroadcastConfig = {}

-- Debug Settings
BroadcastConfig.DEBUG = {
	ENABLED = false,
	SHOW_BROADCAST = true,
	SHOW_QUEUE = true,
	SHOW_ERRORS = true,
	SHOW_SECURITY = true,
}

-- Broadcast Settings
BroadcastConfig.BROADCAST = {
	MIN_DONATION = 5,
	DISPLAY_DURATION = 5,
	MAX_MESSAGE_LENGTH = 200,
	QUEUE_DELAY = 0.5,
	-- NEW: Auto message untuk donasi kecil
	AUTO_MESSAGE_ENABLED = true,
	AUTO_MESSAGE_THRESHOLD = 49, -- Donasi < 50 Robux akan dapat pesan otomatis
}

-- Auto Messages (random pilih salah satu)
BroadcastConfig.AUTO_MESSAGES = {
	"Terima kasih atas dukungannya! 💖",
	"Setiap donasi sangat berarti! 🙏",
	"Terima kasih telah berdonasi! ✨",
	"Dukungan kamu sangat membantu! 💫",
	"Terima kasih banyak! 🌟",
	"Apresiasi untuk donasi kamu! 🎉",
}

-- Anti-Spam
BroadcastConfig.ANTISPAM = {
	ENABLED = true,
	COOLDOWN = 10,
	MAX_QUEUE = 50,
	MAX_QUEUE_PER_PLAYER = 3,
}

-- Security
BroadcastConfig.SECURITY = {
	TRACK_PURCHASES = false,
	PURCHASE_TIMEOUT = 300,
	KICK_ON_FAKE = false,
}

-- Product Prices (sync dengan DonationServerHandler)
BroadcastConfig.PRODUCT_PRICES = {
	{id = 3598419185, name = "Donation1", price = 8},
}

return BroadcastConfig