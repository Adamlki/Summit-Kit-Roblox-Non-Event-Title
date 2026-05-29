--==================================================
-- AURA SYSTEM - SERVER (UPDATED VERSION)
-- Location: ServerScriptService > AuraServer
-- Sync with: AuraShopClient, VipSystem
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsServer() then return end

-- ============================================
-- LOAD AURA DATA (STRUKTUR BARU)
-- ============================================
local AuraPack = ReplicatedStorage:WaitForChild("AuraPack", 10)
if not AuraPack then return end

local AuraList = {}
for _, auraModel in ipairs(AuraPack:GetChildren()) do
    if auraModel:IsA("Model") or auraModel:IsA("Folder") then
        table.insert(AuraList, auraModel.Name)
    end
end

-- ============================================
-- CREATE REMOTES
-- ============================================
local function createRemote(className, name)
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing then return existing end
    
    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = ReplicatedStorage
    return remote
end

local GetOwnedAurasRF = createRemote("RemoteFunction", "Aura_GetOwnedAuras")
local GetEquippedAuraRF = createRemote("RemoteFunction", "Aura_GetEquippedAura")
local ApplyAuraRE = createRemote("RemoteEvent", "Aura_Apply")
local HideAuraRE = createRemote("RemoteEvent", "Aura_Hide")
local AuraDataUpdatedRE = createRemote("RemoteEvent", "Aura_DataUpdated")

-- ============================================
-- PLAYER DATA STRUCTURE (IN-MEMORY ONLY)
-- ============================================
local PlayerAuraData = {}

-- ============================================
-- VIP INTEGRATION
-- ============================================
local function hasVIPAura(player)
    return player:GetAttribute("HasVipAura") == true
end

-- ============================================
-- AURA FUNCTIONS
-- ============================================

local function removeExistingAuras(character)
    if character then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant.Name:find("^Aura_") or descendant:GetAttribute("AuraShop") then
                descendant:Destroy()
            end
        end
    end
end

local function clearPlayerAura(player)
    local character = player.Character
    if not character then return end
    
    removeExistingAuras(character)
    
    local uid = player.UserId
    if PlayerAuraData[uid] then
        PlayerAuraData[uid].auraComponents = {}
    end
end

local function applyAuraToPlayer(player, auraName)
    local character = player.Character
    if not character then return false end
    
    if not character:FindFirstChildOfClass("Humanoid") then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local auraModel = AuraPack:FindFirstChild(auraName)
    if not auraModel then return false end
    
    clearPlayerAura(player)
    
    local uid = player.UserId
    local clonedComponents = {}
    local processedParts = {}
    
    local bodyParts = {
    "HumanoidRootPart", "Head",
    "UpperTorso", "LowerTorso",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"
    }
    
    for _, partName in ipairs(bodyParts) do
        local auraPart = auraModel:FindFirstChild(partName)
        local characterPart = character:FindFirstChild(partName)
        
        if auraPart and characterPart and auraPart:IsA("BasePart") then
            local clone = auraPart:Clone()
            clone.Name = "Aura_" .. partName
            clone:SetAttribute("AuraShop", true)
            clone.Transparency = 1
            clone.CanCollide = false
            clone.CanTouch = false
            clone.Massless = true
            clone.Anchored = false
            clone.CFrame = characterPart.CFrame
            clone.Parent = characterPart
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = clone
            weld.Part1 = characterPart
            weld.Parent = clone
            weld:SetAttribute("IsAura", true)
            
            table.insert(clonedComponents, clone)
            table.insert(clonedComponents, weld)
            
            processedParts[partName] = true
        end
    end
    
    for _, child in ipairs(auraModel:GetChildren()) do
        if child:IsA("BasePart") and not processedParts[child.Name] then
            local clone = child:Clone()
            clone.Name = "Aura_" .. child.Name
            clone:SetAttribute("AuraShop", true)
            clone.Transparency = 1
            clone.CanCollide = false
            clone.CanTouch = false
            clone.Massless = true
            clone.Anchored = false
            clone.CFrame = humanoidRootPart.CFrame
            clone.Parent = humanoidRootPart
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = clone
            weld.Part1 = humanoidRootPart
            weld.Parent = clone
            weld:SetAttribute("IsAura", true)
            
            table.insert(clonedComponents, clone)
            table.insert(clonedComponents, weld)
        end
    end
    
    for _, child in ipairs(auraModel:GetChildren()) do
        if not child:IsA("BasePart") and 
            not child:IsA("Humanoid") and 
            not child:IsA("BillboardGui") and 
            child.Name ~= "HumanoidRootPart" then
            
            local clone = child:Clone()
            clone.Name = "Aura_" .. child.Name
            clone.Parent = humanoidRootPart
            
            if clone:IsA("BasePart") then
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = clone
                weld.Part1 = humanoidRootPart
                weld.Parent = clone
            end
            
            table.insert(clonedComponents, clone)
        end
    end
    
    if #clonedComponents > 0 then
        if not PlayerAuraData[uid] then
            PlayerAuraData[uid] = {}
        end
        
        PlayerAuraData[uid].auraComponents = clonedComponents
        PlayerAuraData[uid].equippedAura = auraName
        
        return true
    else
        return false
    end
end

-- ============================================
-- REMOTE FUNCTIONS
-- ============================================

GetOwnedAurasRF.OnServerInvoke = function(player)
    if hasVIPAura(player) then
        return AuraList
    else
        return {}
    end
end

GetEquippedAuraRF.OnServerInvoke = function(player)
    local uid = player.UserId
    if not PlayerAuraData[uid] then return nil end
    return PlayerAuraData[uid].equippedAura
end

-- ============================================
-- APPLY & HIDE AURA
-- ============================================

ApplyAuraRE.OnServerEvent:Connect(function(player, auraName)
    if not auraName or typeof(auraName) ~= "string" then return end
    if not hasVIPAura(player) then return end
    
    local success = applyAuraToPlayer(player, auraName)
    
    if success then
        AuraDataUpdatedRE:FireClient(player, AuraList, auraName)
    end
end)

HideAuraRE.OnServerEvent:Connect(function(player)
    local uid = player.UserId
    
    clearPlayerAura(player)
    
    if PlayerAuraData[uid] then
        PlayerAuraData[uid].equippedAura = nil
    end
    
    local ownedAuras = {}
    if hasVIPAura(player) then
        ownedAuras = AuraList
    end
    AuraDataUpdatedRE:FireClient(player, ownedAuras, nil)
end)

-- ============================================
-- PLAYER LIFECYCLE
-- ============================================

Players.PlayerAdded:Connect(function(player)
    local uid = player.UserId
    
    PlayerAuraData[uid] = {
    equippedAura = nil,
    auraComponents = {}
    }
    
    player.CharacterAdded:Connect(function(character)
        task.wait(2)
        
        if PlayerAuraData[uid] and PlayerAuraData[uid].equippedAura then
            local auraName = PlayerAuraData[uid].equippedAura
            applyAuraToPlayer(player, auraName)
        end
    end)
    
    if player.Character and PlayerAuraData[uid].equippedAura then
        task.wait(1)
        applyAuraToPlayer(player, PlayerAuraData[uid].equippedAura)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local uid = player.UserId
    clearPlayerAura(player)
    PlayerAuraData[uid] = nil
end)

