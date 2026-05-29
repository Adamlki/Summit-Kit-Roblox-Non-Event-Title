-- ServerScriptService > VipSystemServer
 
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage      = game:GetService("ServerStorage")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
 
local VandraTitle   = require(ServerStorage:WaitForChild("VandraModules"):WaitForChild("VandraTitle"))
local VandraConfig  = require(ServerStorage:WaitForChild("VandraModules"):WaitForChild("VandraConfig"))
local VandraVipData = require(ServerStorage:WaitForChild("VandraModules"):WaitForChild("VandraVipData"))
 
-- ============================================================
-- CONFIG 
-- ============================================================
local VIP_GAMEPASS_ID   = 1772317027  -- ganti dengan ID gamepass asli
local VIP_PRICE_DISPLAY = "$ 50"      -- ganti sesuai harga tampilan
 
-- ============================================================
-- REMOTE EVENTS / FUNCTIONS
-- ============================================================
local function getOrCreateRE(name)
    local e = ReplicatedStorage:FindFirstChild(name)
    if not e then e = Instance.new("RemoteEvent"); e.Name = name; e.Parent = ReplicatedStorage end
    return e
end
local function getOrCreateRF(name)
    local e = ReplicatedStorage:FindFirstChild(name)
    if not e then e = Instance.new("RemoteFunction"); e.Name = name; e.Parent = ReplicatedStorage end
    return e
end
 
local RE_RequestVipPurchase = getOrCreateRE("RequestVipPurchase")
local RE_UpdateVipStatus    = getOrCreateRE("UpdateVipStatus")
local RF_GetVipStatus       = getOrCreateRF("GetVipStatus")
local RF_GetVipPrice        = getOrCreateRF("GetVipPrice")
 
-- ============================================================
-- TOOLS
-- ============================================================
local function giveVipTools(player)
    if not player or not player.Parent then return end
    local toolsFolder = ServerStorage:FindFirstChild("VipTols")
    if not toolsFolder then return end
    
    local backpack   = player:FindFirstChild("Backpack")
    local character  = player.Character
    
    for _, tool in ipairs(toolsFolder:GetChildren()) do
        if not tool:IsA("Tool") then continue end
        local name = tool.Name
        if backpack and backpack:FindFirstChild(name) then continue end
        if character and character:FindFirstChild(name) then continue end
        local clone = tool:Clone()
        clone.Parent = backpack or player:FindFirstChild("Backpack")
    end
end
 
local function removeVipTools(player)
    if not player or not player.Parent then return end
    local toolsFolder = ServerStorage:FindFirstChild("VipTols")
    if not toolsFolder then return end
    
    local toolNames = {}
    for _, t in ipairs(toolsFolder:GetChildren()) do
        if t:IsA("Tool") then toolNames[t.Name] = true end
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if toolNames[t.Name] then t:Destroy() end
        end
    end
    if player.Character then
        for _, t in ipairs(player.Character:GetChildren()) do
            if toolNames[t.Name] then t:Destroy() end
        end
    end
end
 
-- ============================================================
-- SET VIP STATUS
-- ============================================================
local function setVipStatus(player, isVip)
    if not player or not player.Parent then return end
    
    player:SetAttribute("HasVipTitle", isVip)
    player:SetAttribute("HasVipAura",  isVip)
    
    VandraVipData:Save(player.UserId, isVip)
    
    pcall(function()
        RE_UpdateVipStatus:FireClient(player, { hasVip = isVip })
    end)
    
    if isVip then
        giveVipTools(player)
    else
        removeVipTools(player)
    end
end
 
-- ============================================================
-- INIT PLAYER
-- ============================================================
local function initPlayer(player)
    task.spawn(function()
        task.wait(2)
        if not player or not player.Parent then return end
        
        local userId = player.UserId
        
        local ownsPass = false
        local ok, result = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(userId, VIP_GAMEPASS_ID)
        end)
        if ok then ownsPass = result end
        
        local storedVip = VandraVipData:Load(userId)
        local isVip     = ownsPass or storedVip
        
        if ownsPass and not storedVip then
            VandraVipData:Save(userId, true)
        end
        
        setVipStatus(player, isVip)
    end)
end
 
-- ============================================================
-- PLAYERS
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("HasVipTitle", false)
    player:SetAttribute("HasVipAura",  false)
    
    -- Tools lagi setiap respawn
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if player and player.Parent and player:GetAttribute("HasVipTitle") then
            giveVipTools(player)
        end
    end)
    
    initPlayer(player)
    
    -- Chat commands
    player.Chatted:Connect(function(message)
        local roleTitle = VandraTitle.GetRoleTitle(player)
        if not roleTitle then return end
        
        local parts   = message:split(" ")
        local command = parts[1]
        
        if command == "_Gift" and parts[2] then
            if not VandraConfig:HasCommandAccess(roleTitle, "_Gift") then return end
            local targetName = parts[2]
            for _, p in ipairs(Players:GetPlayers()) do
                if string.lower(p.Name) == string.lower(targetName)
                    or string.lower(p.DisplayName) == string.lower(targetName) then
                    setVipStatus(p, true)
                    break
                end
            end
            
        elseif command == "_DVip" and parts[2] then
            if not VandraConfig:HasCommandAccess(roleTitle, "_DVip") then return end
            local targetName = parts[2]
            for _, p in ipairs(Players:GetPlayers()) do
                if string.lower(p.Name) == string.lower(targetName)
                    or string.lower(p.DisplayName) == string.lower(targetName) then
                    setVipStatus(p, false)
                    break
                end
            end
        end
    end)
end)
 
Players.PlayerRemoving:Connect(function(player)
    local isVip = player:GetAttribute("HasVipTitle") == true
    VandraVipData:SaveOnLeave(player.UserId, isVip)
end)
 
-- ============================================================
-- PURCHASE
-- ============================================================
RE_RequestVipPurchase.OnServerEvent:Connect(function(player)
    if not player or not player.Parent then return end
    pcall(function()
        MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID)
    end)
end)
 
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    if not purchased or passId ~= VIP_GAMEPASS_ID then return end
    if not player or not player.Parent then return end
    task.wait(1)
    VandraVipData:Save(player.UserId, true)
    setVipStatus(player, true)
end)
 
RF_GetVipPrice.OnServerInvoke = function(_player)
    return VIP_PRICE_DISPLAY
end
 
RF_GetVipStatus.OnServerInvoke = function(player)
    if not player or not player.Parent then return false end
    return player:GetAttribute("HasVipTitle") == true
end
 
-- ============================================================
-- GLOBAL API
-- ============================================================
local VipAPI = {}
 
function VipAPI.IsVip(player)
    if not player or not player.Parent then return false end
    return player:GetAttribute("HasVipTitle") == true
end
 
function VipAPI.GiftVip(player)   setVipStatus(player, true)  end
function VipAPI.RemoveVip(player) setVipStatus(player, false) end
 
_G.VipSystem = VipAPI

