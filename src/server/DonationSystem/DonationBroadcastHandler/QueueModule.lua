-- ========================================
-- MODULE: QueueModule
-- Letakkan sebagai child dari DonationBroadcastHandler
-- ========================================

local BroadcastConfig = require(script.Parent.BroadcastConfig)
local BroadcastDebug = require(script.Parent.BroadcastDebug)
local SecurityModule = require(script.Parent.SecurityModule)
local MessageModule = require(script.Parent.MessageModule)

local QueueModule = {}

-- ============================================
-- 📊 STATE
-- ============================================
local broadcastQueue = {}
local isProcessingQueue = false
local playerCooldowns = {}

-- ============================================
-- 🔧 FUNCTIONS
-- ============================================

local function getPlayerQueueCount(userId)
	local count = 0
	for _, broadcast in ipairs(broadcastQueue) do
		if broadcast.userId == userId then
			count = count + 1
		end
	end
	return count
end

local function processQueue(receiveRemote)
	if isProcessingQueue then return end
	isProcessingQueue = true

	while #broadcastQueue > 0 do
		local broadcast = table.remove(broadcastQueue, 1)

		BroadcastDebug.log("QUEUE", "Processing:", broadcast.displayName, "Queue:", #broadcastQueue)

		if receiveRemote then
			receiveRemote:FireAllClients(
				broadcast.displayName,
				broadcast.amount,
				broadcast.message
			)
			BroadcastDebug.log("BROADCAST", "Sent to clients:", broadcast.displayName, "-", broadcast.amount, "R$")
		end

		task.wait(BroadcastConfig.BROADCAST.DISPLAY_DURATION + BroadcastConfig.BROADCAST.QUEUE_DELAY)
	end

	isProcessingQueue = false
	BroadcastDebug.log("QUEUE", "Queue processing finished")
end

function QueueModule.addToQueue(player, message, amount, receiveRemote)
	-- Security check
	if not SecurityModule.verifyPurchase(player, amount) then
		BroadcastDebug.warn("SECURITY", "REJECTED:", player.Name)

		if BroadcastConfig.SECURITY.KICK_ON_FAKE then
			player:Kick("Fake donation detected")
			BroadcastDebug.warn("SECURITY", "KICKED:", player.Name)
		end

		return false, "Donasi tidak terverifikasi"
	end

	-- Validasi amount
	if amount < BroadcastConfig.BROADCAST.MIN_DONATION then
		BroadcastDebug.warn("ERROR", player.Name, "insufficient donation:", amount)
		return false, "Donasi minimal " .. BroadcastConfig.BROADCAST.MIN_DONATION .. " Robux"
	end

	-- Anti-spam cooldown
	if BroadcastConfig.ANTISPAM.ENABLED then
		local currentTime = tick()
		local lastTime = playerCooldowns[player.UserId] or 0

		if currentTime - lastTime < BroadcastConfig.ANTISPAM.COOLDOWN then
			local remaining = math.ceil(BroadcastConfig.ANTISPAM.COOLDOWN - (currentTime - lastTime))
			BroadcastDebug.warn("ERROR", player.Name, "on cooldown:", remaining, "seconds")
			return false, "Cooldown: " .. remaining .. " detik lagi"
		end

		playerCooldowns[player.UserId] = currentTime
	end

	-- Check per-player queue limit
	local playerQueueCount = getPlayerQueueCount(player.UserId)
	if playerQueueCount >= BroadcastConfig.ANTISPAM.MAX_QUEUE_PER_PLAYER then
		BroadcastDebug.warn("ERROR", player.Name, "exceeded queue limit:", playerQueueCount)
		return false, "Anda sudah memiliki " .. playerQueueCount .. " pesan dalam antrian"
	end

	-- Check global queue limit
	if #broadcastQueue >= BroadcastConfig.ANTISPAM.MAX_QUEUE then
		BroadcastDebug.warn("ERROR", "Queue full:", #broadcastQueue)
		return false, "Antrian penuh, coba lagi nanti"
	end

	-- Filter message
	local filteredMessage = MessageModule.filterMessage(message)

	-- Add to queue
	table.insert(broadcastQueue, {
		userId = player.UserId,
		displayName = player.DisplayName,
		amount = amount,
		message = filteredMessage,
		timestamp = tick()
	})

	BroadcastDebug.log("QUEUE", "Added:", player.DisplayName, "- Queue:", #broadcastQueue)

	-- Start processing
	task.spawn(function()
		processQueue(receiveRemote)
	end)

	return true, "Pesan ditambahkan ke antrian"
end

function QueueModule.cleanupPlayer(player)
	playerCooldowns[player.UserId] = nil

	for i = #broadcastQueue, 1, -1 do
		if broadcastQueue[i].userId == player.UserId then
			table.remove(broadcastQueue, i)
		end
	end
end

return QueueModule