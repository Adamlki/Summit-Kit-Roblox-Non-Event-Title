-- ========================================
-- MODULE: SecurityModule
-- Letakkan sebagai child dari DonationBroadcastHandler
-- ========================================

local BroadcastConfig = require(script.Parent.BroadcastConfig)
local BroadcastDebug = require(script.Parent.BroadcastDebug)

local SecurityModule = {}

-- ============================================
-- 📊 STATE
-- ============================================
local verifiedPurchases = {}
-- Format: [userId] = {[timestamp] = {productId, amount, claimed}}

-- ============================================
-- 🔒 FUNCTIONS
-- ============================================

function SecurityModule.recordPurchase(player, productId, amount)
	local userId = player.UserId

	if not verifiedPurchases[userId] then
		verifiedPurchases[userId] = {}
	end

	local timestamp = tick()
	verifiedPurchases[userId][timestamp] = {
		productId = productId,
		amount = amount,
		claimed = false
	}

	BroadcastDebug.log("SECURITY", "Recorded purchase:", player.Name, "-", amount, "R$")
end

function SecurityModule.verifyPurchase(player, amount)
	if not BroadcastConfig.SECURITY.TRACK_PURCHASES then
		BroadcastDebug.warn("SECURITY", "Purchase tracking DISABLED - allowing unverified broadcast")
		return true
	end

	local userId = player.UserId
	local purchases = verifiedPurchases[userId]

	if not purchases then
		BroadcastDebug.warn("SECURITY", "No purchases found for", player.Name)
		return false
	end

	local currentTime = tick()

	for timestamp, purchaseData in pairs(purchases) do
		if currentTime - timestamp > BroadcastConfig.SECURITY.PURCHASE_TIMEOUT then
			purchases[timestamp] = nil
			BroadcastDebug.log("SECURITY", "Removed expired purchase for", player.Name)
		elseif not purchaseData.claimed and purchaseData.amount == amount then
			purchaseData.claimed = true
			BroadcastDebug.log("SECURITY", "Verified purchase:", player.Name, "-", amount, "R$")
			return true
		end
	end

	BroadcastDebug.warn("SECURITY", "FAKE DONATION!", player.Name, "tried", amount, "R$")
	return false
end

function SecurityModule.handlePurchaseReceipt(player, productId)
	local amount = BroadcastConfig.PRODUCT_PRICES[productId]

	if amount then
		SecurityModule.recordPurchase(player, productId, amount)
		BroadcastDebug.log("SECURITY", "Purchase verified via ProcessReceipt:", player.Name, "-", amount, "R$")
	else
		BroadcastDebug.warn("SECURITY", "Unknown product ID:", productId)
	end
end

function SecurityModule.cleanupPlayer(player)
	verifiedPurchases[player.UserId] = nil
end

function SecurityModule.cleanupExpiredPurchases()
	local currentTime = tick()
	local cleanedCount = 0

	for userId, purchases in pairs(verifiedPurchases) do
		for timestamp, _ in pairs(purchases) do
			if currentTime - timestamp > BroadcastConfig.SECURITY.PURCHASE_TIMEOUT then
				purchases[timestamp] = nil
				cleanedCount = cleanedCount + 1
			end
		end

		if not next(purchases) then
			verifiedPurchases[userId] = nil
		end
	end

	if cleanedCount > 0 then
		BroadcastDebug.log("SECURITY", "Cleaned", cleanedCount, "expired purchases")
	end
end

return SecurityModule