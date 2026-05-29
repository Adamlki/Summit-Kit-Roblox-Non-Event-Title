-- ServerScriptService/DevicePremiumServer.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- Create atau ambil existing RemoteEvent
local ReportDeviceEvent = ReplicatedStorage:FindFirstChild("ReportDeviceType")
if not ReportDeviceEvent then
    ReportDeviceEvent = Instance.new("RemoteEvent")
    ReportDeviceEvent.Name = "ReportDeviceType"
    ReportDeviceEvent.Parent = ReplicatedStorage
end
 
-- Create RemoteEvent untuk broadcast device changes ke semua client
local DeviceChangedEvent = ReplicatedStorage:FindFirstChild("DeviceChanged")
if not DeviceChangedEvent then
    DeviceChangedEvent = Instance.new("RemoteEvent")
    DeviceChangedEvent.Name = "DeviceChanged"
    DeviceChangedEvent.Parent = ReplicatedStorage
end
 
-- Storage untuk tracking
local playerDevices = {}
 
-- Function untuk broadcast device change ke SEMUA player
local function broadcastDeviceChange(player, deviceType)
    if not player or not player:IsDescendantOf(game) then
        return
    end
    
    -- Broadcast ke SEMUA client
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer:IsDescendantOf(game) then
            pcall(function()
                DeviceChangedEvent:FireClient(otherPlayer, player, deviceType)
            end)
        end
    end
end
 
-- Terima device type dari client
ReportDeviceEvent.OnServerEvent:Connect(function(player, deviceType)
    if not player or not player:IsDescendantOf(game) then
        return
    end
    
    -- Validasi device type
    local validTypes = {
    ["Phone"] = true,
    ["Tablet"] = true,
    ["PC"] = true,
    ["Console"] = true,
    ["VR"] = true,
    }
    
    if not validTypes[deviceType] then
        deviceType = "Unknown"
    end
    
    -- Set attribute (ini yang bikin replicate ke semua client automatically)
    local success = pcall(function()
        player:SetAttribute("DeviceType", deviceType)
    end)
    
    if success then
        -- Save to table
        playerDevices[player.UserId] = deviceType
        
        -- BROADCAST ke semua player lain (double insurance)
        broadcastDeviceChange(player, deviceType)
    end
end)
 
-- Set premium status dan default device
Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    
    if not player or not player:IsDescendantOf(game) then
        return
    end
    
    -- Set premium status
    local isPremium = false
    pcall(function()
        isPremium = player.MembershipType == Enum.MembershipType.Premium
    end)
    
    pcall(function()
        player:SetAttribute("HasPremium", isPremium)
    end)
    
    -- Set default device type
    pcall(function()
        player:SetAttribute("DeviceType", "Unknown")
    end)
    
    playerDevices[player.UserId] = "Unknown"
    
    -- Kirim info semua player yang sudah ada ke player baru ini
    task.spawn(function()
        task.wait(2) -- Tunggu client ready
        
        if not player or not player:IsDescendantOf(game) then
            return
        end
        
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer:IsDescendantOf(game) then
                local otherDevice = otherPlayer:GetAttribute("DeviceType") or "Unknown"
                
                pcall(function()
                    DeviceChangedEvent:FireClient(player, otherPlayer, otherDevice)
                end)
            end
        end
    end)
    
    -- Timeout warning jika tidak report dalam 15 detik
    task.spawn(function()
        task.wait(15)
    end)
end)
 
-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
    if playerDevices[player.UserId] then
        playerDevices[player.UserId] = nil
    end
end)
 
-- Initialize existing players (jika server restart tapi ada player)
task.spawn(function()
    task.wait(1)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player and player:IsDescendantOf(game) then
            pcall(function()
                -- Premium status
                local isPremium = player.MembershipType == Enum.MembershipType.Premium
                player:SetAttribute("HasPremium", isPremium)
                
                -- Device type (default)
                if not player:GetAttribute("DeviceType") then
                    player:SetAttribute("DeviceType", "Unknown")
                    playerDevices[player.UserId] = "Unknown"
                end
            end)
        end
    end
end)

