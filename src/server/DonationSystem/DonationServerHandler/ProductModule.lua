-- ========================================
-- MODULE: ProductModule
-- Letakkan sebagai child dari DonationServerHandler
-- ========================================

local ConfigModule = require(script.Parent.ConfigModule)
local DebugModule = require(script.Parent.DebugModule)

local ProductModule = {}

-- ============================================
-- 📊 CACHE STATE
-- ============================================
local cachedProducts = nil
local lastCacheTime = 0

-- ============================================
-- 🎯 FUNCTIONS
-- ============================================

function ProductModule.getDeveloperProducts()
	local currentTime = tick()

	-- Gunakan cache jika masih valid
	if cachedProducts and (currentTime - lastCacheTime) < ConfigModule.CACHE.DURATION then
		DebugModule.log("CACHE", "Using cached products (" .. #cachedProducts .. " items)")
		return cachedProducts
	end

	DebugModule.log("LOADING", "Loading developer products...")
	local validProducts = {}

	-- Validasi dan load products
	for _, product in ipairs(ConfigModule.PRODUCTS) do
		if product.id and product.name and product.price then
			table.insert(validProducts, {
				Id = product.id,
				Name = product.name,
				Price = product.price,
				Description = ""
			})
			DebugModule.log("VALIDATION", product.name .. " - R$ " .. product.price .. " [VALID]")
		else
			DebugModule.warn("VALIDATION", "Invalid product configuration:", product)
		end
	end

	-- Sort by price
	table.sort(validProducts, function(a, b)
		return a.Price < b.Price
	end)

	-- Update cache
	cachedProducts = validProducts
	lastCacheTime = currentTime

	DebugModule.log("LOADING", "Total products loaded: " .. #validProducts)

	if #validProducts == 0 then
		DebugModule.warn("ERROR", "NO PRODUCTS! Check CONFIG.PRODUCTS")
	end

	return validProducts
end

return ProductModule