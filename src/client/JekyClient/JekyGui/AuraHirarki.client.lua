--==================================================
-- AURA SYSTEM - CLIENT (UPDATED VERSION)
-- Location: StarterPlayer > StarterPlayerScripts > AuraShopClient
-- Sync with: AuraServer, VipSystem
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- VARIABLES
-- ============================================
local ListGui, IsiGui
local AurasButton
local AuraPanel, CloseButton, ScrollingFrame, Label

local isFrameOpen = false
local originalPosition
local hiddenPosition
local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local AuraPack
local AuraList = {}
local ownedAuras = {}
local equippedAura = nil

local GetOwnedAurasRF
local GetEquippedAuraRF
local ApplyAuraRE
local HideAuraRE
local AuraDataUpdatedRE

-- ============================================
-- WAIT FOR GUI ELEMENTS
-- ============================================
local function waitForElements()
    local attempts = 0
    while attempts < 100 do
        ListGui = playerGui:FindFirstChild("ListGui")
        IsiGui = playerGui:FindFirstChild("IsiGui")
        
        if ListGui and IsiGui then
            local listGuiKiri = ListGui:FindFirstChild("ListGuiKiri")
            if listGuiKiri then
                AurasButton = listGuiKiri:FindFirstChild("AurasButton")
            end
            
            AuraPanel = IsiGui:FindFirstChild("AuraPanel")
            
            if AuraPanel then
                CloseButton = AuraPanel:FindFirstChild("CloseButton")
                ScrollingFrame = AuraPanel:FindFirstChild("ScrollingFrame")
                Label = AuraPanel:FindFirstChild("Label")
                
                if AurasButton and CloseButton and ScrollingFrame and Label then
                    return true
                end
            end
        end
        
        attempts = attempts + 1
        task.wait(0.1)
    end
    
    return false
end

-- ============================================
-- CHECK VIP STATUS
-- ============================================
local function checkVIPStatus()
    return player:GetAttribute("HasVipAura") == true
end

-- ============================================
-- UPDATE VIP UI
-- ============================================
local function updateVIPUI()
    local hasVIP = checkVIPStatus()
    
    if hasVIP then
        Label.Visible = false
        ScrollingFrame.Visible = true
    else
        Label.Visible = true
        ScrollingFrame.Visible = false
    end
end

-- ============================================
-- CLEAR ALL AURA BUTTONS
-- ============================================
local function clearAllAuraButtons()
    for _, frame in ipairs(ScrollingFrame:GetChildren()) do
        if frame:IsA("ImageLabel") and frame.Name:match("AuraFrame_") then
            local button = frame:FindFirstChild("Button")
            
            if button and button:IsA("TextButton") then
                button.Text = "Pakai"
            end
        end
    end
end

-- ============================================
-- APPLY AURA
-- ============================================
local function applyAura(auraName)
    if not auraName then return end
    
    if ApplyAuraRE then
        ApplyAuraRE:FireServer(auraName)
        
        clearAllAuraButtons()
        
        for _, frame in ipairs(ScrollingFrame:GetChildren()) do
            if frame:IsA("ImageLabel") then
                local auraLabel = frame:FindFirstChild("AuraLabel")
                if auraLabel and auraLabel.Text == auraName then
                    local button = frame:FindFirstChild("Button")
                    if button then
                        button.Text = "Lepas"
                    end
                    break
                end
            end
        end
        
        equippedAura = auraName
    end
end

-- ============================================
-- REMOVE AURA
-- ============================================
local function removeAura()
    if HideAuraRE then
        HideAuraRE:FireServer()
        clearAllAuraButtons()
        equippedAura = nil
    end
end

-- ============================================
-- LOAD AURA LIST
-- ============================================
local function loadAuraList()
    local templateFrame = ScrollingFrame:FindFirstChild("ImageLabel")
    if not templateFrame then return end
    
    templateFrame.Visible = false
    
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("ImageLabel") and child ~= templateFrame then
            child:Destroy()
        end
    end
    
    for index, auraName in ipairs(AuraList) do
        local frame = templateFrame:Clone()
        frame.Name = "AuraFrame_" .. index
        frame.Visible = true
        
        local auraLabel = frame:FindFirstChild("AuraLabel")
        local button = frame:FindFirstChild("Button")
        
        if auraLabel and button then
            auraLabel.Text = auraName
            
            local isOwned = table.find(ownedAuras, auraName) ~= nil
            
            if isOwned then
                if equippedAura == auraName then
                    button.Text = "Lepas"
                else
                    button.Text = "Pakai"
                end
                
                button.MouseButton1Click:Connect(function()
                    if button.Text == "Pakai" then
                        applyAura(auraName)
                    else
                        removeAura()
                    end
                end)
            else
                button.Visible = false
            end
        end
        
        frame.Parent = ScrollingFrame
    end
end

-- ============================================
-- SYNC AURA DATA
-- ============================================
local function syncAuraData()
    if not GetOwnedAurasRF or not GetEquippedAuraRF then return end
    
    local success1, result1 = pcall(function()
        return GetOwnedAurasRF:InvokeServer()
    end)
    
    if success1 and result1 then
        ownedAuras = result1
    end
    
    local success2, result2 = pcall(function()
        return GetEquippedAuraRF:InvokeServer()
    end)
    
    if success2 then
        equippedAura = result2
    end
    
    loadAuraList()
end

-- ============================================
-- OPEN/CLOSE FRAME
-- ============================================
local function openFrame()
    isFrameOpen = true
    AuraPanel.Visible = true
    TweenService:Create(AuraPanel, tweenInfo, {Position = originalPosition}):Play()
    
    updateVIPUI()
    
    if checkVIPStatus() then
        syncAuraData()
    end
end

local function closeFrame()
    isFrameOpen = false
    TweenService:Create(AuraPanel, tweenInfo, {Position = hiddenPosition}):Play()
    
    task.wait(0.4)
    AuraPanel.Visible = false
end

-- ============================================
-- CLOSE OTHER FRAMES
-- ============================================
local function closeOtherFrames()
    if IsiGui then
        for _, child in ipairs(IsiGui:GetChildren()) do
            if child:IsA("Frame") and child ~= AuraPanel and child.Visible then
                child.Visible = false
            end
        end
    end
end

-- ============================================
-- INITIALIZE SYSTEM
-- ============================================
local function initializeSystem()
    if not waitForElements() then return end
    
    AuraPack = ReplicatedStorage:WaitForChild("AuraPack", 10)
    if not AuraPack then return end
    
    for _, auraModel in ipairs(AuraPack:GetChildren()) do
        if auraModel:IsA("Model") or auraModel:IsA("Folder") then
            table.insert(AuraList, auraModel.Name)
        end
    end
    
    GetOwnedAurasRF = ReplicatedStorage:WaitForChild("Aura_GetOwnedAuras", 10)
    GetEquippedAuraRF = ReplicatedStorage:WaitForChild("Aura_GetEquippedAura", 10)
    ApplyAuraRE = ReplicatedStorage:WaitForChild("Aura_Apply", 10)
    HideAuraRE = ReplicatedStorage:WaitForChild("Aura_Hide", 10)
    AuraDataUpdatedRE = ReplicatedStorage:WaitForChild("Aura_DataUpdated", 10)
    
    if not GetOwnedAurasRF or not ApplyAuraRE or not HideAuraRE then return end
    
    if AuraDataUpdatedRE then
        AuraDataUpdatedRE.OnClientEvent:Connect(function(newOwnedAuras, newEquippedAura)
            ownedAuras = newOwnedAuras or {}
            equippedAura = newEquippedAura
            
            if isFrameOpen then
                loadAuraList()
            end
        end)
    end
    
    originalPosition = AuraPanel.Position
    hiddenPosition = UDim2.new(-0.2, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    
    AuraPanel.Visible = false
    AuraPanel.Position = hiddenPosition
    
    if AurasButton then
        AurasButton.MouseButton1Click:Connect(function()
            if isFrameOpen then
                closeFrame()
            else
                closeOtherFrames()
                openFrame()
            end
        end)
    end
    
    if CloseButton then
        CloseButton.MouseButton1Click:Connect(function()
            closeFrame()
        end)
    end
    
    if ListGui then
        local listGuiKiri = ListGui:FindFirstChild("ListGuiKiri")
        if listGuiKiri then
            for _, button in ipairs(listGuiKiri:GetChildren()) do
                if button:IsA("TextButton") and button ~= AurasButton then
                    button.MouseButton1Click:Connect(function()
                        if isFrameOpen then
                            closeFrame()
                        end
                    end)
                end
            end
        end
    end
    
    player:GetAttributeChangedSignal("HasVipAura"):Connect(function()
        updateVIPUI()
        
        if isFrameOpen then
            syncAuraData()
        end
    end)
end

-- ============================================
-- MAIN EXECUTION
-- ============================================
task.spawn(function()
    task.wait(2)
    initializeSystem()
    
    player.CharacterAdded:Connect(function()
        task.wait(2)
        if waitForElements() then
            updateVIPUI()
        end
    end)
end)

