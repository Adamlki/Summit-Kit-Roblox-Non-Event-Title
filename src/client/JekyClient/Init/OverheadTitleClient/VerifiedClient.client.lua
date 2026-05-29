-- StarterPlayer/StarterPlayerScripts/VerifiedClient
-- Client-side verified UI controller - ALL PLAYERS VERSION
 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local LocalPlayer = Players.LocalPlayer
 
-- ============================================================
-- GET REMOTE EVENTS
-- ============================================================
local VandraEvents = ReplicatedStorage:WaitForChild("VandraEvents")
local VS_UpdateVerifiedUI = VandraEvents:WaitForChild("VS_UpdateVerifiedUI")
 
-- ============================================================
-- SAFE INSTANCE CHECK
-- ============================================================
local function isValid(instance)
    if not instance then return false end
    if typeof(instance) ~= "Instance" then return false end
    
    local success = pcall(function()
        return instance.Parent ~= nil
    end)
    
    return success
end
 
-- ============================================================
-- WAIT FOR BILLBOARD WITH RETRY
-- ============================================================
local function waitForBillboard(character, maxWait)
    if not character or not isValid(character) then
        return nil
    end
    
    maxWait = maxWait or 10
    local waited = 0
    
    while waited < maxWait do
        if not character or not isValid(character) then
            return nil
        end
        
        local head = character:FindFirstChild("Head")
        if head and isValid(head) then
            local billboard = head:FindFirstChild("VandraOverhead")
            if billboard and isValid(billboard) and billboard:IsA("BillboardGui") then
                local iconFrame = billboard:FindFirstChild("Icon")
                if iconFrame and isValid(iconFrame) then
                    return billboard, iconFrame
                end
            end
        end
        
        task.wait(0.5)
        waited = waited + 0.5
    end
    
    return nil
end
 
-- ============================================================
-- VERIFIED UI FUNCTIONS - FOR ANY PLAYER
-- ============================================================
local function updateVerifiedIconForPlayer(player)
    if not player or not isValid(player) or not player.Parent then
        return false
    end
    
    local character = player.Character
    if not character or not isValid(character) then 
        return false
    end
    
    local billboard, iconFrame = waitForBillboard(character, 5)
    
    if not billboard or not iconFrame then
        return false
    end
    
    local success = pcall(function()
        local verifiedIcon = iconFrame:FindFirstChild("Verified")
        if verifiedIcon and verifiedIcon:IsA("ImageLabel") then
            local isVerified = player:GetAttribute("IsVerified") or false
            verifiedIcon.Visible = isVerified == true
        end
    end)
    
    return success
end
 
-- ============================================================
-- UPDATE WITH RETRY MECHANISM
-- ============================================================
local function updateWithRetry(player, maxRetries)
    maxRetries = maxRetries or 5
    
    for attempt = 1, maxRetries do
        if not player or not player.Parent then
            break
        end
        
        local success = updateVerifiedIconForPlayer(player)
        
        if success then
            return true
        else
            if attempt < maxRetries then
                task.wait(1)
            end
        end
    end
    
    return false
end
 
-- ============================================================
-- MONITOR PLAYER CHARACTER
-- ============================================================
local function monitorPlayer(player)
    if not player or not isValid(player) then
        return
    end
    
    local function onCharacter(character)
        if not character or not isValid(character) then
            return
        end
        
        local head = character:FindFirstChild("Head")
        if not head or not isValid(head) then
            head = character:WaitForChild("Head", 5)
        end
        
        if not head or not isValid(head) then
            return
        end
        
        pcall(function()
            head.ChildAdded:Connect(function(child)
                if child.Name == "VandraOverhead" and isValid(child) and child:IsA("BillboardGui") then
                    task.wait(0.5)
                    updateVerifiedIconForPlayer(player)
                end
            end)
        end)
        
        local existingBillboard = head:FindFirstChild("VandraOverhead")
        if existingBillboard and isValid(existingBillboard) then
            task.wait(0.5)
            updateWithRetry(player, 3)
        end
    end
    
    pcall(function()
        player:GetAttributeChangedSignal("IsVerified"):Connect(function()
            updateWithRetry(player, 3)
        end)
    end)
    
    pcall(function()
        player.CharacterAdded:Connect(onCharacter)
        
        if player.Character then
            onCharacter(player.Character)
        end
    end)
end
 
-- ============================================================
-- EVENT HANDLERS
-- ============================================================
VS_UpdateVerifiedUI.OnClientEvent:Connect(function(isVerified)
    updateWithRetry(LocalPlayer, 3)
end)
 
-- ============================================================
-- MONITOR ALL PLAYERS
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    monitorPlayer(player)
end)
 
Players.PlayerRemoving:Connect(function(player)
    -- Cleanup handled automatically
end)
 
-- ============================================================
-- INITIAL SETUP
-- ============================================================
local function initialize()
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            monitorPlayer(player)
        end)
    end
    
    if LocalPlayer.Character and isValid(LocalPlayer.Character) then
        task.spawn(function()
            task.wait(2)
            updateWithRetry(LocalPlayer, 5)
        end)
    end
end
 
-- ============================================================
-- PERIODIC RE-CHECK ALL PLAYERS
-- ============================================================
task.spawn(function()
    while true do
        task.wait(10)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player and isValid(player) and player.Parent and player.Character then
                pcall(function()
                    updateVerifiedIconForPlayer(player)
                end)
            end
        end
    end
end)
 
-- ============================================================
-- START CLIENT
-- ============================================================
task.spawn(initialize)

