-- ========================================
-- SERVERSCRIPT - REFACTORED
-- Letakkan di ServerScriptService
-- Nama: DonationBroadcastHandler
-- ========================================

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local marketplaceService = game:GetService("MarketplaceService")

-- Load modules
local BroadcastConfig = require(script.BroadcastConfig)
local BroadcastDebug = require(script.BroadcastDebug)
local SecurityModule = require(script.SecurityModule)
local QueueModule = require(script.QueueModule)
local MessageModule = require(script.MessageModule)

-- ============================================
-- ?? SETUP REMOTES
-- ============================================
local broadcastRemote = Instance.new("RemoteFunction")
broadcastRemote.Name = "BroadcastDonationMessage"
broadcastRemote.Parent = replicatedStorage

local receiveRemote = Instance.new("RemoteEvent")
receiveRemote.Name = "ReceiveDonationBroadcast"
receiveRemote.Parent = replicatedStorage

-- ============================================
-- ?? HELPER FUNCTIONS
-- ============================================
local function getRandomAutoMessage()
	local messages = BroadcastConfig.AUTO_MESSAGES
	return messages[math.random(1, #messages)]
end

-- ============================================
-- ?? MAIN HANDLER
-- ============================================
broadcastRemote.OnServerInvoke = function(player, message, amount)
	BroadcastDebug.log("BROADCAST", player.Name, "requesting broadcast. Amount:", amount)

	-- Validasi player
	if not player or not player.Parent then
		return false, "Player tidak valid"
	end

	-- Validasi message
	if type(message) ~= "string" or #message < 1 then
		return false, "Pesan tidak valid"
	end

	if #message > BroadcastConfig.BROADCAST.MAX_MESSAGE_LENGTH then
		return false, "Pesan terlalu panjang"
	end

	-- Validasi amount
	if type(amount) ~= "number" then
		BroadcastDebug.warn("SECURITY", player.Name, "sent invalid amount type:", type(amount))
		return false, "Donasi tidak valid"
	end

	if amount < BroadcastConfig.BROADCAST.MIN_DONATION then
		return false, "Donasi tidak mencukupi"
	end

	-- Add to queue (dengan security check)
	return QueueModule.addToQueue(player, message, amount, receiveRemote)
end

-- ============================================
-- ?? PURCHASE TRACKING & AUTO BROADCAST
-- ============================================
local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = players:GetPlayerByUserId(userId)

	if player then
		-- Track purchase untuk security
		SecurityModule.handlePurchaseReceipt(player, productId)

		-- AUTO BROADCAST untuk donasi kecil
		local amount = BroadcastConfig.PRODUCT_PRICES[productId]

		if amount then
			BroadcastDebug.log("BROADCAST", "Purchase detected:", player.Name, "-", amount, "R$")

			-- Cek apakah perlu auto broadcast
			if BroadcastConfig.BROADCAST.AUTO_MESSAGE_ENABLED and 
				amount < BroadcastConfig.BROADCAST.AUTO_MESSAGE_THRESHOLD then

				BroadcastDebug.log("BROADCAST", "Triggering auto broadcast for small donation")

				-- Generate random auto message
				local autoMessage = getRandomAutoMessage()

				-- Add to queue (skip security karena sudah verified di ProcessReceipt)
				task.spawn(function()
					local success, result = QueueModule.addToQueue(player, autoMessage, amount, receiveRemote, true)

					if success then
						BroadcastDebug.log("BROADCAST", "✓ Auto broadcast queued:", player.Name)
					else
						BroadcastDebug.warn("ERROR", "✗ Auto broadcast failed:", result)
					end
				end)
			else
				BroadcastDebug.log("BROADCAST", "Amount >= threshold or auto message disabled, no auto broadcast")
			end
		else
			BroadcastDebug.warn("ERROR", "Unknown product ID:", productId)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

marketplaceService.ProcessReceipt = processReceipt

-- ============================================
-- ?? CLEANUP
-- ============================================
players.PlayerRemoving:Connect(function(player)
	QueueModule.cleanupPlayer(player)
	SecurityModule.cleanupPlayer(player)
	BroadcastDebug.log("BROADCAST", "Cleaned up data for:", player.Name)
end)

-- Periodic cleanup
task.spawn(function()
	while true do
		task.wait(60)
		SecurityModule.cleanupExpiredPurchases()
	end
end)

-- ============================================
-- ?? INITIALIZATION
-- ============================================
BroadcastDebug.log("LOADING", "Donation Broadcast Handler (Refactored + Auto Broadcast via ProcessReceipt) initialized!")