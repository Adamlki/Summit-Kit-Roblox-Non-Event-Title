-- StarterPlayer/StarterPlayerScripts/SettingsSystemClient.lua
 
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
local IsiGui
local SettingPanel
local ScrollingFrame
local CloseButton
local SettingButton
 
local isPanelOpen = false
 
local hideTitle = false
local hidePlayer = false
local hideShadow = false
local graphicMode = false
local hideAura = false
 
local playerVisibilityStates = {}
local originalLightingSettings = {}
local jumpControlGui = nil
local originalJumpSize = UDim2.new(0, 90, 0, 90)
local originalJumpPos = UDim2.new(1, -100, 1, -100)
 
local jumpSettings = {
Size = UDim2.new(0, 90, 0, 90),
Position = UDim2.new(1, -100, 1, -100),
Locked = true
}
 
local dragging = false
local dragStart, startPos
local dragConnections = {}
 
local plusHolding = false
local minusHolding = false
local holdConnection = nil
 
local hiddenAuras = {}
local allMapEffects = {}
local hasScannedEffects = false
 
-- ============================================================
-- SHIFT LOCK SETTINGS
-- ============================================================
 
local shiftControlGui = nil
local shiftDragConnections = {}
local shiftDragging = false
local shiftDragStart, shiftStartPos
 
local shiftPlusHolding = false
local shiftMinusHolding = false
local shiftHoldConnection = nil
 
local originalShiftSize = nil
local originalShiftPos  = nil
 
local shiftSettings = {
Size     = nil,
Position = nil,
Locked   = true
}
 
-- ============================================================
-- AURA
-- ============================================================
 
local function removeAurasFromCharacter(character, includeOwnPlayer)
    if not character then return end
    if not includeOwnPlayer and character == player.Character then return end
    
    if not hiddenAuras[character] then hiddenAuras[character] = {} end
    
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:GetAttribute("AuraShop") or descendant:GetAttribute("IsAura") or descendant.Name:find("^Aura_") then
            table.insert(hiddenAuras[character], {
            object  = descendant,
            parent  = descendant.Parent,
            visible = descendant:IsA("BasePart") and descendant.Transparency or nil
            })
            descendant.Parent = nil
        end
    end
end
 
local function restoreAurasToCharacter(character)
    if not character or not hiddenAuras[character] then return end
    for _, data in ipairs(hiddenAuras[character]) do
        if data.object and data.parent then
            data.object.Parent = data.parent
        end
    end
    hiddenAuras[character] = nil
end
 
-- ============================================================
-- TOGGLE FUNCTIONS
-- ============================================================
 
local function toggleHideTitle(hide)
    hideTitle = hide
    if _G.OverheadTitleAPI and _G.OverheadTitleAPI.setHideTitle then
        _G.OverheadTitleAPI.setHideTitle(hide)
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                for _, gui in pairs(head:GetChildren()) do
                    if gui:IsA("BillboardGui") then gui.Enabled = not hide end
                end
            end
        end
    end
end
 
local function togglePlayerVisibility(hide)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            if not playerVisibilityStates[p.UserId] then
                playerVisibilityStates[p.UserId] = {parts = {}}
            end
            local state = playerVisibilityStates[p.UserId]
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if hide then
                        if not state.parts[part] then state.parts[part] = part.Transparency end
                        part.Transparency = 1
                    else
                        if state.parts[part] then
                            part.Transparency = state.parts[part]
                            state.parts[part] = nil
                        else
                            part.Transparency = 0
                        end
                    end
                elseif part:IsA("Decal") then
                    if hide then
                        if not state.parts[part] then state.parts[part] = part.Transparency end
                        part.Transparency = 1
                    else
                        if state.parts[part] then
                            part.Transparency = state.parts[part]
                            state.parts[part] = nil
                        else
                            part.Transparency = 0
                        end
                    end
                end
            end
        end
    end
end
 
local function toggleShadow(hide)
    Lighting.GlobalShadows = not hide
    if hide then
        if player.Character then removeAurasFromCharacter(player.Character, true) end
    else
        if player.Character then restoreAurasToCharacter(player.Character) end
    end
end
 
-- Fungsi khusus untuk scan map SATU KALI saja
local function scanMapEffects()
    if hasScannedEffects then return end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            -- Simpan objeknya dan status aslinya (apakah awalnya nyala atau mati)
            table.insert(allMapEffects, {
                object = obj,
                originalState = obj.Enabled
            })
        end
    end
    hasScannedEffects = true
end

local function applyGraphicMode(isLow)
    -- Pastikan map di-scan dulu (Hanya berjalan di klik pertama)
    if not hasScannedEffects then
        scanMapEffects()
    end

    if not isLow then
        -- [HIGH GRAPHIC] Kembalikan settingan map dan aura
        for key, value in pairs(originalLightingSettings) do
            pcall(function() Lighting[key] = value end)
        end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then restoreAurasToCharacter(p.Character) end
        end
        
        -- Nyalakan kembali semua efek visual di map secara instan
        for _, data in ipairs(allMapEffects) do
            if data.object and data.object.Parent then
                pcall(function() data.object.Enabled = data.originalState end)
            end
        end
    else
        -- [LOW GRAPHIC] Matikan Shadow & Aura
        pcall(function() Lighting.GlobalShadows = false end)
        
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then removeAurasFromCharacter(p.Character, true) end
        end
        
        -- Matikan semua efek visual di map secara instan
        for _, data in ipairs(allMapEffects) do
            if data.object and data.object.Parent then
                pcall(function() data.object.Enabled = false end)
            end
        end
    end
end
                        -- ============================================================
                        -- JUMP BUTTON SYSTEM
                        -- ============================================================
                        
                        local function findTouchGuiElements()
                            local touchGui = playerGui:FindFirstChild("TouchGui")
                            if not touchGui then return nil, nil, nil end
                            local controlFrame = touchGui:FindFirstChild("TouchControlFrame")
                            if not controlFrame then return touchGui, nil, nil end
                            local jumpBtn = controlFrame:FindFirstChild("JumpButton")
                            return touchGui, controlFrame, jumpBtn
                        end
                        
                        local function applyJumpSettings()
                            local _, _, jumpBtn = findTouchGuiElements()
                            if jumpBtn then
                                jumpBtn.Size = jumpSettings.Size
                                jumpBtn.Position = jumpSettings.Position
                            end
                        end
                        
                        local function cleanupDragConnections()
                            for _, conn in pairs(dragConnections) do
                                if conn then conn:Disconnect() end
                            end
                            dragConnections = {}
                        end
                        
                        local function setupDragSystem(jumpBtn)
                            if not jumpBtn then return end
                            cleanupDragConnections()
                            if not jumpSettings.Locked then
                                local conn1 = jumpBtn.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        dragging = true
                                        dragStart = input.Position
                                        startPos  = jumpBtn.Position
                                    end
                                end)
                                local conn2 = jumpBtn.InputChanged:Connect(function(input)
                                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                        local delta = input.Position - dragStart
                                        jumpBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                                    end
                                end)
                                local conn3 = jumpBtn.InputEnded:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        dragging = false
                                    end
                                end)
                                table.insert(dragConnections, conn1)
                                table.insert(dragConnections, conn2)
                                table.insert(dragConnections, conn3)
                            end
                        end
                        
                        local function createJumpControlGUI()
                            if jumpControlGui then jumpControlGui:Destroy() jumpControlGui = nil end
                            local _, _, jumpBtn = findTouchGuiElements()
                            if not jumpBtn then return end
                            
                            applyJumpSettings()
                            setupDragSystem(jumpBtn)
                            
                            if not jumpSettings.Locked then
                                jumpControlGui = Instance.new("ScreenGui")
                                jumpControlGui.Name = "JumpControlGui"
                                jumpControlGui.ResetOnSpawn = false
                                jumpControlGui.Parent = playerGui
                                
                                local controlContainer = Instance.new("Frame")
                                controlContainer.Name = "ControlContainer"
                                controlContainer.Size = UDim2.new(0, 170, 0, 40)
                                controlContainer.BackgroundTransparency = 1
                                controlContainer.Parent = jumpControlGui
                                
                                local function updateControlPosition()
                                    local jumpPos  = jumpBtn.AbsolutePosition
                                    local jumpSize = jumpBtn.AbsoluteSize
                                    controlContainer.Position = UDim2.new(0, jumpPos.X + (jumpSize.X / 2) - 85, 0, math.max(10, jumpPos.Y - 60))
                                end
                                
                                updateControlPosition()
                                
                                -- makeBtn dengan UIStroke di background
                                local function makeBtn(text, xOffset, fontSize)
                                    local btn = Instance.new("TextButton")
                                    btn.Size = UDim2.new(0, 35, 0, 35)
                                    btn.Position = UDim2.new(0, xOffset, 0, 2.5)
                                    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                    btn.Text = text
                                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    btn.Font = Enum.Font.GothamBold
                                    btn.TextSize = fontSize or 20
                                    btn.Parent = controlContainer
                                    
                                    local corner = Instance.new("UICorner")
                                    corner.CornerRadius = UDim.new(0.15, 0)
                                    corner.Parent = btn
                                    
                                    -- UIStroke di luar (background outline), bukan di text
                                    local stroke = Instance.new("UIStroke")
                                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                    stroke.Color = Color3.fromRGB(255, 0, 0)
                                    stroke.Thickness = 1.5
                                    stroke.Transparency = 0
                                    stroke.Parent = btn
                                    
                                    return btn
                                end
                                
                                local minusBtn = makeBtn("-", 0)
                                local resetBtn = makeBtn("Reset", 40, 11); resetBtn.Size = UDim2.new(0, 45, 0, 35)
                                local saveBtn  = makeBtn("Save", 90, 11);  saveBtn.Size  = UDim2.new(0, 45, 0, 35)
                                local plusBtn  = makeBtn("+", 140)
                                
                                local function stopHolding()
                                    plusHolding = false
                                    minusHolding = false
                                    if holdConnection then holdConnection:Disconnect() holdConnection = nil end
                                end
                                
                                minusBtn.MouseButton1Down:Connect(function()
                                    minusHolding = true
                                    jumpBtn.Size = UDim2.new(0, math.max(30, jumpBtn.Size.X.Offset - 10), 0, math.max(30, jumpBtn.Size.X.Offset - 10))
                                    updateControlPosition()
                                    task.wait(0.3)
                                    if minusHolding then
                                        holdConnection = RunService.Heartbeat:Connect(function()
                                            if minusHolding then
                                                local s = math.max(30, jumpBtn.Size.X.Offset - math.min(5, jumpBtn.Size.X.Offset * 0.02))
                                                jumpBtn.Size = UDim2.new(0, s, 0, s)
                                                updateControlPosition()
                                            end
                                        end)
                                    end
                                end)
                                minusBtn.MouseButton1Up:Connect(stopHolding)
                                minusBtn.MouseLeave:Connect(stopHolding)
                                
                                plusBtn.MouseButton1Down:Connect(function()
                                    plusHolding = true
                                    local screenH = jumpBtn.Parent.AbsoluteSize.Y
                                    local s = math.min(screenH, jumpBtn.Size.X.Offset + 10)
                                    jumpBtn.Size = UDim2.new(0, s, 0, s)
                                    updateControlPosition()
                                    task.wait(0.3)
                                    if plusHolding then
                                        holdConnection = RunService.Heartbeat:Connect(function()
                                            if plusHolding then
                                                local screenH2 = jumpBtn.Parent.AbsoluteSize.Y
                                                local s2 = math.min(screenH2, jumpBtn.Size.X.Offset + math.min(5, jumpBtn.Size.X.Offset * 0.02))
                                                jumpBtn.Size = UDim2.new(0, s2, 0, s2)
                                                updateControlPosition()
                                            end
                                        end)
                                    end
                                end)
                                plusBtn.MouseButton1Up:Connect(stopHolding)
                                plusBtn.MouseLeave:Connect(stopHolding)
                                
                                resetBtn.MouseButton1Click:Connect(function()
                                    jumpBtn.Size = originalJumpSize
                                    jumpBtn.Position = originalJumpPos
                                    updateControlPosition()
                                end)
                                
                                saveBtn.MouseButton1Click:Connect(function()
                                    jumpSettings.Size = jumpBtn.Size
                                    jumpSettings.Position = jumpBtn.Position
                                    jumpSettings.Locked = true
                                    
                                    for _, child in pairs({minusBtn, resetBtn, saveBtn, plusBtn}) do
                                        TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                                    end
                                    task.wait(0.3)
                                    
                                    if jumpControlGui then jumpControlGui:Destroy() jumpControlGui = nil end
                                    cleanupDragConnections()
                                    applyJumpSettings()
                                    
                                    -- Reset toggle TextLabel ke "OFF"
                                    local settingJump = ScrollingFrame and ScrollingFrame:FindFirstChild("SetingJump")
                                    if settingJump then
                                        local childFrame = settingJump:FindFirstChild("Frame")
                                        if childFrame then
                                            local button = childFrame:FindFirstChild("Button")
                                            if button then
                                                local label = button:FindFirstChildOfClass("TextLabel")
                                                if label then
                                                    label.Text = "OFF"
                                                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                                end
                                            end
                                        end
                                    end
                                end)
                                
                                local updateConn
                                updateConn = RunService.RenderStepped:Connect(function()
                                    if jumpControlGui and jumpControlGui.Parent then
                                        updateControlPosition()
                                    else
                                        if updateConn then updateConn:Disconnect() end
                                    end
                                end)
                                
                                jumpControlGui.Destroying:Connect(function()
                                    cleanupDragConnections()
                                    stopHolding()
                                end)
                            end
                        end
                        
                        -- ============================================================
                        -- SHIFT LOCK SYSTEM
                        -- ============================================================
                        
                        local function findShiftButton()
                            local listGui = playerGui:FindFirstChild("ListGui")
                            if not listGui then return nil, nil end
                            local shiftFrame = listGui:FindFirstChild("Shift")
                            if not shiftFrame then return nil, nil end
                            local shiftBtn = shiftFrame:FindFirstChild("ShiftButton")
                            return shiftBtn, shiftFrame
                        end
                        
                        local function getOrCreateShiftDragFrame(shiftBtn)
                            if not shiftBtn then return nil end
                            local dragFrame = shiftBtn:FindFirstChild("DragFrame")
                            if not dragFrame then
                                dragFrame = Instance.new("Frame")
                                dragFrame.Name = "DragFrame"
                                dragFrame.Size = UDim2.new(1, 0, 1, 0)
                                dragFrame.Position = UDim2.new(0, 0, 0, 0)
                                dragFrame.BackgroundTransparency = 1
                                dragFrame.ZIndex = (shiftBtn.ZIndex or 1) + 1
                                dragFrame.Parent = shiftBtn
                            end
                            return dragFrame
                        end
                        
                        local function captureOriginalShiftValues(shiftBtn, shiftFrame)
                            if originalShiftSize == nil and shiftBtn then
                                originalShiftSize = shiftBtn.Size
                            end
                            if originalShiftPos == nil and shiftFrame then
                                originalShiftPos = shiftFrame.Position
                            end
                            if shiftSettings.Size == nil and originalShiftSize then
                                shiftSettings.Size = originalShiftSize
                            end
                            if shiftSettings.Position == nil and originalShiftPos then
                                shiftSettings.Position = originalShiftPos
                            end
                        end
                        
                        local function applyShiftSettings()
                            local shiftBtn, shiftFrame = findShiftButton()
                            if not shiftBtn or not shiftFrame then return end
                            
                            captureOriginalShiftValues(shiftBtn, shiftFrame)
                            
                            if shiftSettings.Size then
                                shiftBtn.Size = shiftSettings.Size
                                local img = shiftBtn:FindFirstChildOfClass("ImageLabel")
                                if img then img.Size = UDim2.new(1, 0, 1, 0) end
                            end
                            if shiftSettings.Position then
                                shiftFrame.Position = shiftSettings.Position
                            end
                        end
                        
                        local function cleanupShiftDragConnections()
                            for _, conn in pairs(shiftDragConnections) do
                                if conn then conn:Disconnect() end
                            end
                            shiftDragConnections = {}
                        end
                        
                        local function setupShiftDragSystem(shiftBtn, shiftFrame)
                            if not shiftBtn or not shiftFrame then return end
                            cleanupShiftDragConnections()
                            
                            if not shiftSettings.Locked then
                                local dragFrame = getOrCreateShiftDragFrame(shiftBtn)
                                if not dragFrame then return end
                                
                                local conn1 = dragFrame.InputBegan:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        shiftDragging = true
                                        shiftDragStart = input.Position
                                        shiftStartPos  = shiftFrame.Position
                                    end
                                end)
                                local conn2 = dragFrame.InputChanged:Connect(function(input)
                                    if shiftDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                        local delta = input.Position - shiftDragStart
                                        shiftFrame.Position = UDim2.new(
                                        shiftStartPos.X.Scale, shiftStartPos.X.Offset + delta.X,
                                        shiftStartPos.Y.Scale, shiftStartPos.Y.Offset + delta.Y
                                        )
                                    end
                                end)
                                local conn3 = dragFrame.InputEnded:Connect(function(input)
                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        shiftDragging = false
                                    end
                                end)
                                table.insert(shiftDragConnections, conn1)
                                table.insert(shiftDragConnections, conn2)
                                table.insert(shiftDragConnections, conn3)
                            end
                        end
                        
                        local function createShiftControlGUI()
                            if shiftControlGui then shiftControlGui:Destroy() shiftControlGui = nil end
                            local shiftBtn, shiftFrame = findShiftButton()
                            if not shiftBtn or not shiftFrame then return end
                            
                            captureOriginalShiftValues(shiftBtn, shiftFrame)
                            applyShiftSettings()
                            setupShiftDragSystem(shiftBtn, shiftFrame)
                            
                            if not shiftSettings.Locked then
                                shiftControlGui = Instance.new("ScreenGui")
                                shiftControlGui.Name = "ShiftControlGui"
                                shiftControlGui.ResetOnSpawn = false
                                shiftControlGui.Parent = playerGui
                                
                                local controlContainer = Instance.new("Frame")
                                controlContainer.Name = "ControlContainer"
                                controlContainer.Size = UDim2.new(0, 170, 0, 40)
                                controlContainer.BackgroundTransparency = 1
                                controlContainer.Parent = shiftControlGui
                                
                                local function updateControlPosition()
                                    local pos  = shiftBtn.AbsolutePosition
                                    local size = shiftBtn.AbsoluteSize
                                    controlContainer.Position = UDim2.new(0, pos.X + (size.X / 2) - 85, 0, math.max(10, pos.Y - 60))
                                end
                                
                                updateControlPosition()
                                
                                -- makeBtn dengan UIStroke di background
                                local function makeBtn(text, xOffset, fontSize, width)
                                    local btn = Instance.new("TextButton")
                                    btn.Size = UDim2.new(0, width or 35, 0, 35)
                                    btn.Position = UDim2.new(0, xOffset, 0, 2.5)
                                    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                    btn.Text = text
                                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    btn.Font = Enum.Font.GothamBold
                                    btn.TextSize = fontSize or 20
                                    btn.Parent = controlContainer
                                    
                                    local corner = Instance.new("UICorner")
                                    corner.CornerRadius = UDim.new(0.15, 0)
                                    corner.Parent = btn
                                    
                                    -- UIStroke di luar (background outline), bukan di text
                                    local stroke = Instance.new("UIStroke")
                                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                    stroke.Color = Color3.fromRGB(255, 0, 0)
                                    stroke.Thickness = 1.5
                                    stroke.Transparency = 0
                                    stroke.Parent = btn
                                    
                                    return btn
                                end
                                
                                local minusBtn = makeBtn("-", 0)
                                local resetBtn = makeBtn("Reset", 40, 11, 45)
                                local saveBtn  = makeBtn("Save", 90, 11, 45)
                                local plusBtn  = makeBtn("+", 140)
                                
                                local function stopShiftHolding()
                                    shiftPlusHolding = false
                                    shiftMinusHolding = false
                                    if shiftHoldConnection then shiftHoldConnection:Disconnect() shiftHoldConnection = nil end
                                end
                                
                                local function resizeShift(newSize)
                                    shiftBtn.Size = UDim2.new(0, newSize, 0, newSize)
                                    local img = shiftBtn:FindFirstChildOfClass("ImageLabel")
                                    if img then img.Size = UDim2.new(1, 0, 1, 0) end
                                    updateControlPosition()
                                end
                                
                                minusBtn.MouseButton1Down:Connect(function()
                                    shiftMinusHolding = true
                                    resizeShift(math.max(30, shiftBtn.Size.X.Offset - 10))
                                    task.wait(0.3)
                                    if shiftMinusHolding then
                                        shiftHoldConnection = RunService.Heartbeat:Connect(function()
                                            if shiftMinusHolding then
                                                resizeShift(math.max(30, shiftBtn.Size.X.Offset - math.min(5, shiftBtn.Size.X.Offset * 0.02)))
                                            end
                                        end)
                                    end
                                end)
                                minusBtn.MouseButton1Up:Connect(stopShiftHolding)
                                minusBtn.MouseLeave:Connect(stopShiftHolding)
                                
                                plusBtn.MouseButton1Down:Connect(function()
                                    shiftPlusHolding = true
                                    local screenH = workspace.CurrentCamera.ViewportSize.Y
                                    resizeShift(math.min(screenH, shiftBtn.Size.X.Offset + 10))
                                    task.wait(0.3)
                                    if shiftPlusHolding then
                                        shiftHoldConnection = RunService.Heartbeat:Connect(function()
                                            if shiftPlusHolding then
                                                local screenH2 = workspace.CurrentCamera.ViewportSize.Y
                                                resizeShift(math.min(screenH2, shiftBtn.Size.X.Offset + math.min(5, shiftBtn.Size.X.Offset * 0.02)))
                                            end
                                        end)
                                    end
                                end)
                                plusBtn.MouseButton1Up:Connect(stopShiftHolding)
                                plusBtn.MouseLeave:Connect(stopShiftHolding)
                                
                                resetBtn.MouseButton1Click:Connect(function()
                                    if originalShiftSize then
                                        resizeShift(originalShiftSize.X.Offset)
                                    end
                                    if originalShiftPos and shiftFrame then
                                        shiftFrame.Position = originalShiftPos
                                    end
                                    updateControlPosition()
                                end)
                                
                                saveBtn.MouseButton1Click:Connect(function()
                                    shiftSettings.Size     = shiftBtn.Size
                                    shiftSettings.Position = shiftFrame.Position
                                    shiftSettings.Locked   = true
                                    
                                    for _, child in pairs({minusBtn, resetBtn, saveBtn, plusBtn}) do
                                        TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                                    end
                                    task.wait(0.3)
                                    
                                    if shiftControlGui then shiftControlGui:Destroy() shiftControlGui = nil end
                                    cleanupShiftDragConnections()
                                    applyShiftSettings()
                                    
                                    local btn, _ = findShiftButton()
                                    if btn then
                                        local df = btn:FindFirstChild("DragFrame")
                                        if df then df:Destroy() end
                                    end
                                    
                                    -- Reset toggle TextLabel ke "OFF"
                                    local settingShift = ScrollingFrame and ScrollingFrame:FindFirstChild("SetingShiftLock")
                                    if settingShift then
                                        local childFrame = settingShift:FindFirstChild("Frame")
                                        if childFrame then
                                            local button = childFrame:FindFirstChild("Button")
                                            if button then
                                                local label = button:FindFirstChildOfClass("TextLabel")
                                                if label then
                                                    label.Text = "OFF"
                                                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                                end
                                            end
                                        end
                                    end
                                end)
                                
                                local updateConn
                                updateConn = RunService.RenderStepped:Connect(function()
                                    if shiftControlGui and shiftControlGui.Parent then
                                        updateControlPosition()
                                    else
                                        if updateConn then updateConn:Disconnect() end
                                    end
                                end)
                                
                                shiftControlGui.Destroying:Connect(function()
                                    cleanupShiftDragConnections()
                                    stopShiftHolding()
                                end)
                            end
                        end
                        
                        -- ============================================================
                        -- TOGGLE UI HELPER
                        -- Mengganti logika Togle/innerFrame dengan TextLabel di dalam Button
                        -- Setting biasa (HideName, HidePlayer, dll) → ON / OFF
                        -- SetingJump & SetingShiftLock → GO / OFF
                        -- ============================================================
                        
                        local function updateToggleUI(settingFrame, isOn, isGoMode)
                            local childFrame = settingFrame:FindFirstChild("Frame")
                            if not childFrame then return end
                            local button = childFrame:FindFirstChild("Button")
                            if not button then return end
                            
                            -- Cari atau buat TextLabel di dalam Button
                            local label = button:FindFirstChildOfClass("TextLabel")
                            if not label then
                                label = Instance.new("TextLabel")
                                label.Name = "StateLabel"
                                label.Size = UDim2.new(1, 0, 1, 0)
                                label.Position = UDim2.new(0, 0, 0, 0)
                                label.BackgroundTransparency = 1
                                label.Font = Enum.Font.GothamBold
                                label.TextSize = 13
                                label.ZIndex = (button.ZIndex or 1) + 1
                                label.Parent = button
                            end
                            
                            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            
                            if isOn then
                                local onText = isGoMode and "ON" or "ON"
                                label.Text = onText
                                TweenService:Create(label, tweenInfo, {
                                TextColor3 = Color3.fromRGB(255, 255, 255)
                                }):Play()
                            else
                                label.Text = "OFF"
                                TweenService:Create(label, tweenInfo, {
                                TextColor3 = Color3.fromRGB(255, 255, 255)
                                }):Play()
                            end
                        end
                        
                        -- ============================================================
                        -- SETUP SETTING TOGGLES
                        -- ============================================================
                        
                        local function setupSettingToggle(settingFrame, settingName)
                            local childFrame = settingFrame:FindFirstChild("Frame")
                            if not childFrame then return end
                            local button = childFrame:FindFirstChild("Button")
                            if not button then return end
                            
                            -- Tentukan apakah ini mode GO (Jump & ShiftLock)
                            local isGoMode = (settingName == "SetingJump" or settingName == "SetingShiftLock")
                            
                            button.MouseButton1Click:Connect(function()
                                if settingName == "HideName" then
                                    hideTitle = not hideTitle
                                    updateToggleUI(settingFrame, hideTitle, false)
                                    toggleHideTitle(hideTitle)
                                    
                                elseif settingName == "HidePlayer" then
                                    hidePlayer = not hidePlayer
                                    updateToggleUI(settingFrame, hidePlayer, false)
                                    togglePlayerVisibility(hidePlayer)
                                    
                                elseif settingName == "HideShadow" then
                                    hideShadow = not hideShadow
                                    updateToggleUI(settingFrame, hideShadow, false)
                                    toggleShadow(hideShadow)
                                    
                                elseif settingName == "HideGrafik" then
                                    graphicMode = not graphicMode
                                    updateToggleUI(settingFrame, graphicMode, false)
                                    applyGraphicMode(graphicMode)
                                    
                                elseif settingName == "HideAura" then
                                    hideAura = not hideAura
                                    updateToggleUI(settingFrame, hideAura, false)
                                    toggleHideAura(hideAura)
                                    
                                elseif settingName == "SetingJump" then
                                    jumpSettings.Locked = not jumpSettings.Locked
                                    if jumpSettings.Locked then
                                        -- Terkunci → OFF
                                        updateToggleUI(settingFrame, false, true)
                                        cleanupDragConnections()
                                        applyJumpSettings()
                                        if jumpControlGui then
                                            local cc = jumpControlGui:FindFirstChild("ControlContainer")
                                            if cc then
                                                for _, child in pairs(cc:GetChildren()) do
                                                    if child:IsA("GuiObject") then
                                                        TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                                                    end
                                                end
                                                task.wait(0.3)
                                            end
                                            jumpControlGui:Destroy()
                                            jumpControlGui = nil
                                        end
                                    else
                                        -- Terbuka → GO
                                        updateToggleUI(settingFrame, true, true)
                                        createJumpControlGUI()
                                    end
                                    
                                elseif settingName == "SetingShiftLock" then
                                    shiftSettings.Locked = not shiftSettings.Locked
                                    if shiftSettings.Locked then
                                        -- Terkunci → OFF
                                        updateToggleUI(settingFrame, false, true)
                                        cleanupShiftDragConnections()
                                        applyShiftSettings()
                                        
                                        local btn, _ = findShiftButton()
                                        if btn then
                                            local df = btn:FindFirstChild("DragFrame")
                                            if df then df:Destroy() end
                                        end
                                        
                                        if shiftControlGui then
                                            local cc = shiftControlGui:FindFirstChild("ControlContainer")
                                            if cc then
                                                for _, child in pairs(cc:GetChildren()) do
                                                    if child:IsA("GuiObject") then
                                                        TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
                                                    end
                                                end
                                                task.wait(0.3)
                                            end
                                            shiftControlGui:Destroy()
                                            shiftControlGui = nil
                                        end
                                    else
                                        -- Terbuka → GO
                                        updateToggleUI(settingFrame, true, true)
                                        createShiftControlGUI()
                                    end
                                end
                            end)
                        end
                        
                        -- ============================================================
                        -- LOAD SETTINGS
                        -- ============================================================
                        
                        local function loadSettings()
                            if not ScrollingFrame then return end
                            local settingNames = {"HideName", "HideAura", "HidePlayer", "HideShadow", "HideGrafik", "SetingJump", "SetingShiftLock"}
                            for _, name in ipairs(settingNames) do
                                local settingFrame = ScrollingFrame:FindFirstChild(name)
                                if settingFrame then
                                    setupSettingToggle(settingFrame, name)
                                end
                            end
                            applyJumpSettings()
                            local shiftBtn, shiftFrame = findShiftButton()
                            if shiftBtn and shiftFrame then
                                captureOriginalShiftValues(shiftBtn, shiftFrame)
                            end
                        end
                        
                        -- ============================================================
                        -- PANEL OPEN/CLOSE
                        -- ============================================================
                        
                        local function openPanel()
                            if isPanelOpen then return end
                            isPanelOpen = true
                            SettingPanel.Visible = true
                        end
                        
                        local function closePanel()
                            if not isPanelOpen then return end
                            isPanelOpen = false
                            SettingPanel.Visible = false
                        end
                        
                        local function setupAutoCloseForOtherButtons()
                            for _, gui in ipairs(playerGui:GetDescendants()) do
                                if gui:IsA("TextButton") and gui.Name ~= "SettingButton" then
                                    local isInsideSettingPanel = false
                                    local parent = gui.Parent
                                    while parent do
                                        if parent == SettingPanel then isInsideSettingPanel = true break end
                                        parent = parent.Parent
                                    end
                                    if not isInsideSettingPanel then
                                        gui.MouseButton1Click:Connect(function()
                                            if isPanelOpen then closePanel() end
                                        end)
                                    end
                                end
                            end
                            
                            playerGui.DescendantAdded:Connect(function(descendant)
                                if descendant:IsA("TextButton") and descendant.Name ~= "SettingButton" then
                                    local isInsideSettingPanel = false
                                    local parent = descendant.Parent
                                    while parent do
                                        if parent == SettingPanel then isInsideSettingPanel = true break end
                                        parent = parent.Parent
                                    end
                                    if not isInsideSettingPanel then
                                        descendant.MouseButton1Click:Connect(function()
                                            if isPanelOpen then closePanel() end
                                        end)
                                    end
                                end
                            end)
                        end
                        
                        local function findSettingButton()
                            local listGui = playerGui:FindFirstChild("ListGui")
                            if not listGui then return nil end
                            local listGuiKiri = listGui:FindFirstChild("ListTopBar")
                            if not listGuiKiri then return nil end
                            return listGuiKiri:FindFirstChild("SettingButton")
                        end
                        
                        local function waitForElements()
                            local attempts = 0
                            while attempts < 100 do
                                IsiGui = playerGui:FindFirstChild("IsiGui")
                                if IsiGui then
                                    SettingPanel = IsiGui:FindFirstChild("SettingPanel")
                                    if SettingPanel then
                                        ScrollingFrame = SettingPanel:FindFirstChild("ScrollingFrame")
                                        CloseButton    = SettingPanel:FindFirstChild("CloseButton")
                                        if ScrollingFrame and CloseButton then return true end
                                    end
                                end
                                attempts = attempts + 1
                                task.wait(0.1)
                            end
                            return false
                        end
                        
                        local function initializeSystem()
                            if not waitForElements() then return end
                            
                            originalLightingSettings = {
                            Brightness               = Lighting.Brightness,
                            Ambient                  = Lighting.Ambient,
                            GlobalShadows            = Lighting.GlobalShadows,
                            OutdoorAmbient           = Lighting.OutdoorAmbient,
                            EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
                            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
                            }
                            
                            SettingPanel.Visible = false
                            loadSettings()
                            
                            SettingButton = findSettingButton()
                            if SettingButton then
                                SettingButton.MouseButton1Click:Connect(function()
                                    if isPanelOpen then closePanel() else openPanel() end
                                end)
                            end
                            
                            if CloseButton then
                                CloseButton.MouseButton1Click:Connect(function() closePanel() end)
                                end
                                    
                                    setupAutoCloseForOtherButtons()
                                end
                                
                                -- ============================================================
                                -- CHARACTER / PLAYER EVENTS
                                -- ============================================================
                                
                                Players.PlayerAdded:Connect(function(p)
                                    if p == player then return end
                                    p.CharacterAdded:Connect(function()
                                        task.wait(1)
                                        if hideTitle then toggleHideTitle(true) end
                                        if hidePlayer then togglePlayerVisibility(true) end
                                        if hideAura then toggleHideAura(true) end
                                        if graphicMode then removeAurasFromCharacter(p.Character, false) end
                                    end)
                                end)
                                
                                player.CharacterAdded:Connect(function()
                                    task.wait(1)
                                    if hideTitle then toggleHideTitle(true) end
                                    if hidePlayer then togglePlayerVisibility(true) end
                                    if hideAura then toggleHideAura(true) end
                                    if hideShadow then toggleShadow(true) end
                                    if graphicMode then removeAurasFromCharacter(player.Character, true) end
                                    applyJumpSettings()
                                    local shiftBtn, shiftFrame = findShiftButton()
                                    if shiftBtn and shiftFrame then
                                        captureOriginalShiftValues(shiftBtn, shiftFrame)
                                        if shiftSettings.Size and shiftSettings.Position then
                                            applyShiftSettings()
                                        end
                                    end
                                end)
                                
                                task.spawn(function()
                                    if not player.Character then player.CharacterAdded:Wait() end
                                    task.wait(1)
                                    initializeSystem()
                                end)

