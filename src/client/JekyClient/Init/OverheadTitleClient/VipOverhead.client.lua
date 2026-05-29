-- StarterPlayer/StarterPlayerScripts/VipTitleClient
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local player = Players.LocalPlayer
 
local UpdateVipStatus = ReplicatedStorage:WaitForChild("UpdateVipStatus", 10)
 
local function isValid(instance)
    if not instance then return false end
    if typeof(instance) ~= "Instance" then return false end
    local success = pcall(function() return instance.Parent ~= nil end)
        return success
    end
 
    local function waitForBillboard(character, maxWait)
        if not character or not isValid(character) then return nil end
        maxWait = maxWait or 10
        local waited = 0
        while waited < maxWait do
            if not character or not isValid(character) then return nil end
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
 
    -- Toggle Visible pada ImageLabel "Vip" di dalam Icon frame
    local function updateVipTitleForPlayer(targetPlayer)
        if not targetPlayer or not isValid(targetPlayer) or not targetPlayer.Parent then return false end
        local character = targetPlayer.Character
        if not character or not isValid(character) then return false end
 
        local billboard, iconFrame = waitForBillboard(character, 5)
        if not billboard or not iconFrame then return false end
 
        local success = pcall(function()
            local vipImage = iconFrame:FindFirstChild("Vip")
            if not vipImage then return end
            local hasTitle = targetPlayer:GetAttribute("HasVipTitle") == true
            vipImage.Visible = hasTitle
        end)
 
        return success
    end
 
    local function updateWithRetry(targetPlayer, maxRetries)
        maxRetries = maxRetries or 5
        for attempt = 1, maxRetries do
            if not targetPlayer or not targetPlayer.Parent then break end
            local success = updateVipTitleForPlayer(targetPlayer)
            if success then return true end
            if attempt < maxRetries then task.wait(1) end
        end
        return false
    end
 
    local function monitorPlayer(targetPlayer)
        if not targetPlayer or not isValid(targetPlayer) then return end
 
        local function onCharacter(character)
            if not character or not isValid(character) then return end
            local head = character:FindFirstChild("Head")
            if not head or not isValid(head) then
                head = character:WaitForChild("Head", 5)
            end
            if not head or not isValid(head) then return end
 
            pcall(function()
                head.ChildAdded:Connect(function(child)
                    if child.Name == "VandraOverhead" and isValid(child) and child:IsA("BillboardGui") then
                        task.wait(0.5)
                        updateVipTitleForPlayer(targetPlayer)
                    end
                end)
            end)
 
            local existingBillboard = head:FindFirstChild("VandraOverhead")
            if existingBillboard and isValid(existingBillboard) then
                task.wait(0.5)
                updateWithRetry(targetPlayer, 3)
            end
        end
 
        pcall(function()
            targetPlayer:GetAttributeChangedSignal("HasVipTitle"):Connect(function()
                updateWithRetry(targetPlayer, 3)
            end)
        end)
 
        pcall(function()
            targetPlayer.CharacterAdded:Connect(function(character)
                task.wait(1)
                onCharacter(character)
            end)
            if targetPlayer.Character then
                onCharacter(targetPlayer.Character)
            end
        end)
    end
 
    if UpdateVipStatus then
        UpdateVipStatus.OnClientEvent:Connect(function(statusData)
            if statusData and statusData.hasTitle ~= nil then
                task.wait(0.5)
                updateWithRetry(player, 3)
            end
        end)
    end
 
    Players.PlayerAdded:Connect(function(newPlayer)
        task.wait(0.5)
        monitorPlayer(newPlayer)
    end)
 
    local function initialize()
        for _, existingPlayer in ipairs(Players:GetPlayers()) do
            task.spawn(function() monitorPlayer(existingPlayer) end)
            end
                if player.Character and isValid(player.Character) then
                    task.spawn(function()
                        task.wait(2)
                        updateWithRetry(player, 5)
                    end)
                end
            end
 
            task.spawn(function()
                while true do
                    task.wait(10)
                    for _, existingPlayer in ipairs(Players:GetPlayers()) do
                        if existingPlayer and isValid(existingPlayer) and existingPlayer.Parent and existingPlayer.Character then
                            pcall(function()
                                updateVipTitleForPlayer(existingPlayer)
                            end)
                        end
                    end
                end
            end)
 
            task.spawn(initialize)

