-- StarterPlayerScripts/IconVisibility.lua
-- REVISI: Mencari billboard di Head, bukan di folder Overhead
local Players = game:GetService("Players")

-- Safe instance check
local function isValid(instance)
    if not instance then return false end
    if typeof(instance) ~= "Instance" then return false end
    
    local success = pcall(function()
        return instance.Parent ~= nil
    end)
    
    return success
end

-- Wait for billboard in Head with retry
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
        
        -- PERBAIKAN: Cari di Head, bukan di folder Overhead
        local head = character:FindFirstChild("Head")
        if head and isValid(head) then
            -- Cari BillboardGui bernama "JekyOverhead" di dalam Head
            local billboard = head:FindFirstChild("JekyOverhead")
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

-- Update icon visibility
local function updateIconVisibility(player)
    if not player or not isValid(player) then
        return false
    end
    
    local character = player.Character
    if not character or not isValid(character) then
        return false
    end
    
    -- Wait for billboard
    local billboard, iconFrame = waitForBillboard(character, 5)
    
    if not billboard or not iconFrame then
        return false
    end
    
    -- [OPTIMASI] Gunakan MaxDistance agar engine Roblox otomatis menyembunyikan BillboardGui
    -- Ini jauh lebih ringan daripada menghitung (X, Y, Z) / Magnitude di RunService
    billboard.MaxDistance = 75
    
    local success = pcall(function()
        -- Hide ALL device icons first
        local deviceIcons = {"Phone", "Tablet", "Pc", "Consol", "Vr", "Unknow"}
        for _, iconName in ipairs(deviceIcons) do
            local icon = iconFrame:FindFirstChild(iconName)
            if icon and isValid(icon) then
                icon.Visible = false
            end
        end
        
        -- Get device type
        local deviceType = player:GetAttribute("DeviceType")
        
        if deviceType and deviceType ~= "" then
            -- Icon name mapping
            local iconNameMap = {
            Phone = "Phone",
            Tablet = "Tablet",
            PC = "Pc",
            Console = "Consol",
            VR = "Vr"
            }
            
            local targetIconName = iconNameMap[deviceType] or "Unknow"
            local targetIcon = iconFrame:FindFirstChild(targetIconName)
            
            if targetIcon and isValid(targetIcon) then
                targetIcon.Visible = true
            else
                -- Show unknown if target icon not found
                local unknownIcon = iconFrame:FindFirstChild("Unknow")
                if unknownIcon and isValid(unknownIcon) then
                    unknownIcon.Visible = true
                end
            end
        else
            -- No device type, show unknown
            local unknownIcon = iconFrame:FindFirstChild("Unknow")
            if unknownIcon and isValid(unknownIcon) then
                unknownIcon.Visible = true
            end
        end
        
        -- Update Premium icon
        local premiumIcon = iconFrame:FindFirstChild("Premium")
        if premiumIcon and isValid(premiumIcon) then
            local hasPremium = player:GetAttribute("HasPremium") == true
            premiumIcon.Visible = hasPremium
        end
    end)
    
    return success
end

-- Setup monitoring with retry
local function setupPlayerMonitoring(player)
    if not player or not isValid(player) then
        return
    end
    
    -- DeviceType change listener
    pcall(function()
        player:GetAttributeChangedSignal("DeviceType"):Connect(function()
            task.defer(function()
                if player and isValid(player) and player.Parent then
                    updateIconVisibility(player)
                end
            end)
        end)
    end)
    
    -- HasPremium change listener
    pcall(function()
        player:GetAttributeChangedSignal("HasPremium"):Connect(function()
            task.defer(function()
                if player and isValid(player) and player.Parent then
                    updateIconVisibility(player)
                end
            end)
        end)
    end)
    
    -- Character added listener
    pcall(function()
        player.CharacterAdded:Connect(function(character)
            if not character or not isValid(character) then
                return
            end
            
            -- Wait for character to stabilize
            task.wait(1)
            
            -- Retry mechanism
            local maxRetries = 5
            for attempt = 1, maxRetries do
                if not player or not isValid(player) or not player.Parent then
                    break
                end
                
                local success = updateIconVisibility(player)
                
                if success then
                    break
                else
                    if attempt < maxRetries then
                        task.wait(1)
                    end
                end
            end
        end)
    end)
    
    -- Initial update if character exists
    if player.Character and isValid(player.Character) then
        task.spawn(function()
            task.wait(2) -- Wait longer for initial setup
            
            local maxRetries = 5
            for attempt = 1, maxRetries do
                if not player or not isValid(player) or not player.Parent then
                    break
                end
                
                local success = updateIconVisibility(player)
                
                if success then
                    break
                else
                    if attempt < maxRetries then
                        task.wait(1)
                    end
                end
            end
        end)
    end
end

-- Monitor for billboard recreation (when JekyOverhead is recreated in Head)
local function monitorBillboardRecreation(player)
    if not player or not isValid(player) then
        return
    end
    
    local function onCharacter(character)
        if not character or not isValid(character) then
            return
        end
        
        -- PERBAIKAN: Monitor Head, bukan folder Overhead
        local head = character:FindFirstChild("Head")
        if not head or not isValid(head) then
            -- Wait for Head if not found yet
            head = character:WaitForChild("Head", 5)
        end
        
        if not head or not isValid(head) then
            return
        end
        
        -- Monitor for JekyOverhead being added/changed in Head
        pcall(function()
            head.ChildAdded:Connect(function(child)
                if child.Name == "JekyOverhead" and isValid(child) and child:IsA("BillboardGui") then
                    task.wait(0.5) -- Wait for Icon frame to be added
                    updateIconVisibility(player)
                end
            end)
        end)
        
        -- Also check if JekyOverhead already exists
        local existingBillboard = head:FindFirstChild("JekyOverhead")
        if existingBillboard and isValid(existingBillboard) then
            task.wait(0.5)
            updateIconVisibility(player)
        end
    end
    
    pcall(function()
        player.CharacterAdded:Connect(onCharacter)
        
        if player.Character then
            onCharacter(player.Character)
        end
    end)
end

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        setupPlayerMonitoring(player)
        monitorBillboardRecreation(player)
    end)
end

-- Setup for new players
Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        setupPlayerMonitoring(player)
        monitorBillboardRecreation(player)
    end)
end)

-- Periodic re-check (every 10 seconds) for any missed updates
task.spawn(function()
    while true do
        task.wait(10)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player and isValid(player) and player.Parent and player.Character then
                pcall(function()
                    updateIconVisibility(player)
                end)
            end
        end
    end
end)

