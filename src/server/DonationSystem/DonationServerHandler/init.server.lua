-- ========================================
-- SERVERSCRIPT - REFACTORED
-- Letakkan di ServerScriptService
-- Nama: DonationServerHandler
-- ========================================

local replicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local ConfigModule = require(script.ConfigModule)
local DebugModule = require(script.DebugModule)
local ProductModule = require(script.ProductModule)

-- ============================================
-- 🌐 SETUP REMOTES
-- ============================================
local getProductsRemote = Instance.new("RemoteFunction")
getProductsRemote.Name = "GetDeveloperProducts"
getProductsRemote.Parent = replicatedStorage

-- ============================================
-- 🎯 MAIN HANDLER
-- ============================================
getProductsRemote.OnServerInvoke = function(player)
	DebugModule.log("PLAYER", player.Name .. " requesting products")

	local success, products = pcall(function()
		return ProductModule.getDeveloperProducts()
	end)

	if success and products then
		return products
	else
		DebugModule.warn("ERROR", "Failed to get products:", products)
		return {}
	end
end

-- ============================================
-- 🚀 INITIALIZATION
-- ============================================
task.spawn(function()
	task.wait(2)
	DebugModule.log("LOADING", "Pre-loading products...")
	ProductModule.getDeveloperProducts()
end)

DebugModule.log("LOADING", "Donation Server Handler (Refactored) initialized!")