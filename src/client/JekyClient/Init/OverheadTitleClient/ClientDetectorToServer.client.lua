-- StarterPlayerScripts/CompleteDeviceDetector.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ============================================
-- PART 1: DEVICE DETECTION (untuk local player)
-- ============================================

-- WAIT FOR CAMERA TO BE READY
local function waitForCamera()
    local camera = workspace.CurrentCamera
    if not camera then
        camera = workspace:WaitForChild("Camera", 10)
    end
    
    local maxWait = 50
    local waited = 0
    while waited < maxWait do
        local viewportSize = camera.ViewportSize
        if viewportSize and viewportSize.X > 0 and viewportSize.Y > 0 then
            return camera, viewportSize
        end
        task.wait(0.1)
        waited = waited + 1
    end
    
    return nil, nil
end

-- GET SAFE SCREEN SIZE
local function getSafeScreenSize()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end
    
    local success, viewportSize = pcall(function()
        return camera.ViewportSize
    end)
    
    if not success or not viewportSize or viewportSize.X <= 0 or viewportSize.Y <= 0 then
        return nil
    end
    
    return viewportSize
end

-- TABLET DETECTION METHOD 1: Scoring System
local function detectMethod1()
    local screenSize = getSafeScreenSize()
    if not screenSize then return nil end
    
    local success, result = pcall(function()
        local aspectRatio = screenSize.X / screenSize.Y
        local screenArea = screenSize.X * screenSize.Y
        local diagonal = math.sqrt(screenSize.X^2 + screenSize.Y^2)
        
        local confidence = 0
        
        -- Aspect Ratio Check (30%)
        if aspectRatio >= 1.2 and aspectRatio <= 1.8 then
            confidence = confidence + 30
        elseif aspectRatio > 2.0 then
            confidence = confidence - 20
        end
        
        -- Diagonal Check (40%)
        if diagonal > 1000 then
            confidence = confidence + 40
        elseif diagonal < 700 then
            confidence = confidence - 30
        end
        
        -- Screen Area Check (30%)
        if screenArea > 2000000 then
            confidence = confidence + 30
        elseif screenArea < 1500000 then
            confidence = confidence - 20
        end
        
        local isTablet = confidence >= 40
        return isTablet and "Tablet" or "Phone"
    end)
    
    return success and result or nil
end

-- TABLET DETECTION METHOD 2: Simple Diagonal
local function detectMethod2()
    local screenSize = getSafeScreenSize()
    if not screenSize then return nil end
    
    local success, result = pcall(function()
        local diagonal = math.sqrt(screenSize.X^2 + screenSize.Y^2)
        
        if diagonal > 850 then
            return "Tablet"
        else
            return "Phone"
        end
    end)
    
    return success and result or nil
end

-- MAIN DEVICE DETECTION
local function detectDeviceType()
    -- 1. VR Check
    local vrSuccess, vrEnabled = pcall(function()
        return UserInputService.VREnabled
    end)
    
    if vrSuccess and vrEnabled then
        return "VR"
    end
    
    -- 2. Gamepad Check
    local gamepadSuccess, gamepads = pcall(function()
        return UserInputService:GetConnectedGamepads()
    end)
    
    if gamepadSuccess and gamepads and #gamepads > 0 then
        return "Console"
    end
    
    -- 3. Touch Device Check
    local touchSuccess, touchEnabled = pcall(function()
        return UserInputService.TouchEnabled
    end)
    
    if touchSuccess and touchEnabled then
        -- Try multiple detection methods
        local method1 = detectMethod1()
        local method2 = detectMethod2()
        
        -- Vote system
        local tabletVotes = 0
        local phoneVotes = 0
        
        if method1 == "Tablet" then tabletVotes = tabletVotes + 1
        elseif method1 == "Phone" then phoneVotes = phoneVotes + 1 end
            
            if method2 == "Tablet" then tabletVotes = tabletVotes + 1
            elseif method2 == "Phone" then phoneVotes = phoneVotes + 1 end
                
                if tabletVotes > phoneVotes then
                    return "Tablet"
                else
                    return "Phone"
                end
            end
            
            -- 4. Default to PC
            return "PC"
        end
        
        -- ============================================
        -- PART 2: REPORT TO SERVER
        -- ============================================
        
        local ReportDeviceEvent = ReplicatedStorage:WaitForChild("ReportDeviceType", 5)
        
        local function reportToServer(deviceType)
            if not ReportDeviceEvent then
                return false
            end
            
            local success = pcall(function()
                ReportDeviceEvent:FireServer(deviceType)
            end)
            
            return success
        end
        
        -- ============================================
        -- PART 3: LISTEN FOR OTHER PLAYERS' DEVICES
        -- ============================================
        
        local DeviceChangedEvent = ReplicatedStorage:WaitForChild("DeviceChanged", 5)
        local deviceCache = {}
        
        -- Update device cache
        local function updateDeviceCache(player, deviceType)
            if not player or not player:IsDescendantOf(game) then
                return
            end
            
            deviceCache[player.UserId] = deviceType
        end
        
        -- Listen for broadcasts
        if DeviceChangedEvent then
            DeviceChangedEvent.OnClientEvent:Connect(function(player, deviceType)
                if not player or not player:IsDescendantOf(game) then
                    return
                end
                
                updateDeviceCache(player, deviceType)
            end)
        end
        
        -- Listen for attribute changes (backup method)
        Players.PlayerAdded:Connect(function(player)
            if player == LocalPlayer then return end
            
            player:GetAttributeChangedSignal("DeviceType"):Connect(function()
                local device = player:GetAttribute("DeviceType")
                if device then
                    updateDeviceCache(player, device)
                end
            end)
            
            -- Initial device
            task.wait(1)
            local device = player:GetAttribute("DeviceType")
            if device then
                updateDeviceCache(player, device)
            end
        end)
        
        -- Cleanup on player leave
        Players.PlayerRemoving:Connect(function(player)
            if deviceCache[player.UserId] then
                deviceCache[player.UserId] = nil
            end
        end)
        
        -- Public function to get any player's device
        _G.GetPlayerDevice = function(player)
            if not player or not player:IsDescendantOf(game) then
                return "Unknown"
            end
            
            -- If it's local player, check attribute first
            if player == LocalPlayer then
                return player:GetAttribute("DeviceType") or "Unknown"
            end
            
            -- Try cache
            local cached = deviceCache[player.UserId]
            if cached then
                return cached
            end
            
            -- Fallback to attribute
            local attr = player:GetAttribute("DeviceType")
            if attr then
                deviceCache[player.UserId] = attr
                return attr
            end
            
            return "Unknown"
        end
        
        -- ============================================
        -- PART 4: INITIALIZATION
        -- ============================================
        
        task.spawn(function()
            -- Wait for camera
            local camera, viewportSize = waitForCamera()
            task.wait(1)
            
            -- Detect local device
            local maxRetries = 3
            local myDevice = nil
            
            for attempt = 1, maxRetries do
                local success, deviceType = pcall(detectDeviceType)
                
                if success and deviceType then
                    myDevice = deviceType
                    LocalPlayer:SetAttribute("DeviceType", deviceType)
                    
                    -- Report to server
                    if reportToServer(deviceType) then
                        break
                    end
                end
                
                if attempt < maxRetries then
                    task.wait(2)
                end
            end
            
            -- Fallback if all failed
            if not myDevice then
                myDevice = "Phone"
                LocalPlayer:SetAttribute("DeviceType", myDevice)
                reportToServer(myDevice)
            end
            
            -- Initialize cache for existing players
            task.wait(2)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player:IsDescendantOf(game) then
                    local device = player:GetAttribute("DeviceType") or "Unknown"
                    deviceCache[player.UserId] = device
                end
            end
        end)

