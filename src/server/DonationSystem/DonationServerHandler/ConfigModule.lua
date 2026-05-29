-- ========================================
-- MODULE: ConfigModule
-- Letakkan sebagai child dari DonationServerHandler
-- ========================================

local ConfigModule = {}

-- ============================================
-- 📋 KONFIGURASI
-- ============================================
ConfigModule.DEBUG = {
	ENABLED = false,
	SHOW_PLAYER_REQUESTS = false,
	SHOW_PRODUCT_LOADING = false,
	SHOW_CACHE_INFO = false,
	SHOW_VALIDATION = true,
	SHOW_ERRORS = true,
}

ConfigModule.CACHE = {
	DURATION = 300, -- 5 menit
}

ConfigModule.PRODUCTS = {
	{id = 3598419185, name = "Donation1", price = 8},
}

return ConfigModule