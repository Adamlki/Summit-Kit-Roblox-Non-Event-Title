-- ServerScriptService > DonationServer
local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- ============================================
-- DONATION PACKAGES
-- ============================================
local DONATION_PACKAGES = {
	{id = 3598419185, price = 8},
}
 
-- ============================================
-- CREATE REMOTES
-- ============================================
local GetDonationPackagesRF = Instance.new("RemoteFunction")
GetDonationPackagesRF.Name   = "Donation_GetPackages"
GetDonationPackagesRF.Parent = ReplicatedStorage
 
local PurchaseDonationRE = Instance.new("RemoteEvent")
PurchaseDonationRE.Name   = "Donation_Purchase"
PurchaseDonationRE.Parent = ReplicatedStorage
 
local DonationNotifyRE = Instance.new("RemoteEvent")
DonationNotifyRE.Name   = "Donation_Notify"
DonationNotifyRE.Parent = ReplicatedStorage
 
-- ============================================
-- GET PACKAGES (client request)
-- ============================================
GetDonationPackagesRF.OnServerInvoke = function(_player)
    return DONATION_PACKAGES
end
 
-- ============================================
-- VALIDATE PACKAGE
-- ============================================
local function isValidPackage(productId)
    for _, package in ipairs(DONATION_PACKAGES) do
        if package.id == productId then
            return true, package.price
        end
    end
    return false, 0
end
 
-- ============================================
-- BROADCAST NOTIFIKASI KE SEMUA PLAYER
-- ============================================
local function broadcastDonation(donorPlayer, amount)
    for _, target in ipairs(Players:GetPlayers()) do
        DonationNotifyRE:FireClient(target, donorPlayer.DisplayName, amount)
    end
end
 
local DataStoreService = game:GetService("DataStoreService")
local DonationDataStore = DataStoreService:GetOrderedDataStore("GlobalDonationLB_v1")

-- ============================================
-- PROCESS RECEIPT (MarketplaceService)
-- ============================================
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local donorPlayer = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	-- Validasi apakah player ada di server
	if not donorPlayer then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Validasi apakah product valid
	local isValid, price = isValidPackage(receiptInfo.ProductId)
	if not isValid then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Proses penyimpanan ke OrderedDataStore
	local key = "Player_" .. donorPlayer.UserId
	local success, err = pcall(function()
		-- IncrementAsync akan otomatis menambah value jika key sudah ada,
		-- atau membuat key baru dengan value 'price' jika belum ada.
		DonationDataStore:IncrementAsync(key, price)
	end)

	if success then
		-- Jika berhasil disimpan, broadcast notifikasi dan izinkan purchase
		broadcastDonation(donorPlayer, price)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("[DonationServer] Gagal menyimpan donasi untuk " .. donorPlayer.Name .. ": " .. tostring(err))
		-- Jika gagal (misal server Roblox gangguan), jangan selesaikan purchase
		-- Roblox akan mencoba lagi dalam beberapa saat.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end
 
-- ============================================
-- HANDLE PURCHASE REQUEST FROM CLIENT
-- ============================================
PurchaseDonationRE.OnServerEvent:Connect(function(requestPlayer, productId)
    local isValid, _ = isValidPackage(productId)
    if not isValid then return end
    
    pcall(function()
        MarketplaceService:PromptProductPurchase(requestPlayer, productId)
    end)
end)

