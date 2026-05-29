local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
 
local Player = Players.LocalPlayer
local ApplyEvent = RS:WaitForChild("ApplyCustomTitle")
 
local ADMINS = {"adamzz3372","",""}
if not table.find(ADMINS, Player.Name) then return end
 
local playerGui = Player:WaitForChild("PlayerGui")

-- Langsung tunggu ListGui di luar, karena wujud aslinya memang ada di luar
local listGui = playerGui:WaitForChild("ListGui")

local toggleBtn = listGui:WaitForChild("TitleButton")
toggleBtn.Visible = true
 
local PRESETS = {
{Name = "Cyber Dreams", Colors = {
Color3.fromRGB(0, 255, 255),
Color3.fromRGB(180, 0, 255),
Color3.fromRGB(255, 215, 0),
Color3.fromRGB(255, 105, 180)
}},
{Name = "Primary Mix", Colors = {
Color3.fromRGB(0, 0, 255),
Color3.fromRGB(255, 0, 0),
Color3.fromRGB(255, 255, 0)
}},
{Name = "Pastel Dreams", Colors = {
Color3.fromRGB(135, 206, 250),
Color3.fromRGB(255, 255, 0),
Color3.fromRGB(255, 192, 203)
}},
{Name = "Neon Vibes", Colors = {
Color3.fromRGB(138, 43, 226),
Color3.fromRGB(255, 20, 147),
Color3.fromRGB(0, 255, 255)
}},
{Name = "Sunset Fire", Colors = {
Color3.fromRGB(255, 215, 0),
Color3.fromRGB(255, 140, 0),
Color3.fromRGB(255, 69, 0)
}}
}
 
local SOLIDS = {
Color3.fromRGB(255, 0, 0),
Color3.fromRGB(255, 215, 0),
Color3.fromRGB(0, 100, 255),
Color3.fromRGB(0, 255, 255),
Color3.fromRGB(255, 105, 180)
}
 
local ANIMS = {"Gradient360", "LeftRight", "Diagonal", "Wave", "Pulse"}
 
local TitleData = {}
for i = 1, 10 do
    TitleData[i] = {Text = "", Mode = "PRESET", PresetIdx = 1, AnimIdx = 1, SolidIdx = 1}
end
 
local selectedPlayer = nil
local selectedBtn = nil
local activeLine = 1
local activeAnims = {}
 
local function clearAnim(lbl)
    if not lbl then return end
    for i = #activeAnims, 1, -1 do
        local rec = activeAnims[i]
        if rec and rec.lbl == lbl then
            if rec.conn then
                pcall(function() rec.conn:Disconnect() end)
                end
                    table.remove(activeAnims, i)
                end
            end
            if lbl and lbl.Parent then
                for _, g in pairs(lbl:GetChildren()) do
                    if g and g:IsA("UIGradient") then
                        pcall(function() g:Destroy() end)
                        end
                        end
                        end
                        end
                            
                            local function buildSeq(colors)
                                local kp = {}
                                local n = #colors
                                for i, c in ipairs(colors) do
                                    table.insert(kp, ColorSequenceKeypoint.new((i - 1) / math.max(1, n - 1), c))
                                end
                                return ColorSequence.new(kp)
                            end
                            
                            local function applyAnim(lbl, animType, colors)
                                if not lbl or not lbl.Parent then return end
                                clearAnim(lbl)
                                
                                local grad = Instance.new("UIGradient")
                                grad.Parent = lbl
                                grad.Color = buildSeq(colors)
                                
                                local offset, dir, rotation = 0, 1, 0
                                
                                local conn = RunService.Heartbeat:Connect(function(dt)
                                    if not lbl or not lbl.Parent or not grad or not grad.Parent then
                                        if conn then pcall(function() conn:Disconnect() end) end
                                        return
                                    end
                                    
                                    pcall(function()
                                        if animType == "Gradient360" then
                                            rotation = (rotation + dt * 100) % 360
                                            grad.Rotation = rotation
                                        elseif animType == "LeftRight" then
                                            offset = offset + dt * 0.25 * dir
                                            if offset >= 1 then offset, dir = 1, -1
                                            elseif offset <= 0 then offset, dir = 0, 1 end
                                                grad.Offset = Vector2.new(offset, 0)
                                            elseif animType == "Diagonal" then
                                                offset = offset + dt * 0.2
                                                if offset >= 1 then offset = 0 end
                                                grad.Offset = Vector2.new(offset, offset)
                                            elseif animType == "Wave" then
                                                offset = offset + dt * 0.35
                                                local wave = math.sin(offset * math.pi * 2) * 0.5
                                                grad.Offset = Vector2.new(wave, 0)
                                            elseif animType == "Pulse" then
                                                offset = offset + dt * 0.5 * dir
                                                if offset >= 1 then offset, dir = 1, -1
                                                elseif offset <= 0 then offset, dir = 0, 1 end
                                                    grad.Offset = Vector2.new(offset, 0)
                                                end
                                            end)
                                        end)
                                        
                                        table.insert(activeAnims, {lbl = lbl, conn = conn})
                                    end
                                    
                                    local function applySolid(lbl, color)
                                        if not lbl or not lbl.Parent then return end
                                        clearAnim(lbl)
                                        pcall(function()
                                            lbl.TextColor3 = color
                                        end)
                                    end
                                    
                                    local gui = Instance.new("ScreenGui")
                                    gui.Name = "TitlePanel_V3"
                                    gui.ResetOnSpawn = false
                                    gui.Enabled = true
                                    gui.Parent = Player:WaitForChild("PlayerGui")
                                    
                                    local frame = Instance.new("Frame")
                                    frame.Size = UDim2.new(0, 340, 0, 380)
                                    frame.Position = UDim2.new(0.5, -170, 0.5, -190)
                                    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                                    frame.BorderSizePixel = 0
                                    frame.Active = true
                                    frame.Draggable = true
                                    frame.Visible = false
                                    frame.Parent = gui
                                    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
                                    
                                    toggleBtn.MouseButton1Click:Connect(function()
                                        frame.Visible = not frame.Visible
                                    end)
                                    
                                    local header = Instance.new("Frame")
                                    header.Size = UDim2.new(1, 0, 0, 35)
                                    header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                                    header.Parent = frame
                                    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
                                    
                                    local title = Instance.new("TextLabel")
                                    title.Position = UDim2.new(0, 8, 0, 0)
                                    title.Size = UDim2.new(1, -45, 1, 0)
                                    title.BackgroundTransparency = 1
                                    title.Font = Enum.Font.GothamBold
                                    title.TextSize = 14
                                    title.TextColor3 = Color3.new(1, 1, 1)
                                    title.Text = "🎮 Title Manager"
                                    title.TextXAlignment = Enum.TextXAlignment.Left
                                    title.Parent = header
                                    
                                    local closeBtn = Instance.new("TextButton")
                                    closeBtn.Size = UDim2.new(0, 28, 0, 22)
                                    closeBtn.Position = UDim2.new(1, -32, 0.5, -11)
                                    closeBtn.Text = "X"
                                    closeBtn.Font = Enum.Font.GothamBold
                                    closeBtn.TextSize = 13
                                    closeBtn.TextColor3 = Color3.new(1, 1, 1)
                                    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                                    closeBtn.Parent = header
                                    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
                                    
                                    closeBtn.MouseButton1Click:Connect(function()
                                        frame.Visible = false
                                    end)
                                    
                                    local plLabel = Instance.new("TextLabel")
                                    plLabel.Position = UDim2.new(0, 8, 0, 42)
                                    plLabel.Size = UDim2.new(1, -16, 0, 16)
                                    plLabel.BackgroundTransparency = 1
                                    plLabel.Font = Enum.Font.GothamBold
                                    plLabel.TextSize = 12
                                    plLabel.TextColor3 = Color3.new(1, 1, 1)
                                    plLabel.Text = "Player:"
                                    plLabel.TextXAlignment = Enum.TextXAlignment.Left
                                    plLabel.Parent = frame
                                    
                                    local plScroll = Instance.new("ScrollingFrame")
                                    plScroll.Position = UDim2.new(0.04, 0, 0, 62)
                                    plScroll.Size = UDim2.new(0.92, 0, 0, 60)
                                    plScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                                    plScroll.ScrollBarThickness = 3
                                    plScroll.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                                    plScroll.BorderSizePixel = 0
                                    plScroll.Parent = frame
                                    Instance.new("UICorner", plScroll).CornerRadius = UDim.new(0, 6)
                                    
                                    local plLayout = Instance.new("UIListLayout")
                                    plLayout.Padding = UDim.new(0, 3)
                                    plLayout.Parent = plScroll
                                    
                                    local lineLabel = Instance.new("TextLabel")
                                    lineLabel.Position = UDim2.new(0, 8, 0, 128)
                                    lineLabel.Size = UDim2.new(0.5, -4, 0, 16)
                                    lineLabel.BackgroundTransparency = 1
                                    lineLabel.Font = Enum.Font.GothamBold
                                    lineLabel.TextSize = 12
                                    lineLabel.TextColor3 = Color3.new(1, 1, 1)
                                    lineLabel.Text = "Line:"
                                    lineLabel.TextXAlignment = Enum.TextXAlignment.Left
                                    lineLabel.Parent = frame
                                    
                                    local lineSwitch = Instance.new("TextButton")
                                    lineSwitch.Position = UDim2.new(0.5, 4, 0, 128)
                                    lineSwitch.Size = UDim2.new(0.46, 0, 0, 22)
                                    lineSwitch.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                                    lineSwitch.TextColor3 = Color3.new(1, 1, 1)
                                    lineSwitch.Font = Enum.Font.GothamBold
                                    lineSwitch.TextSize = 12
                                    lineSwitch.Text = "Line 1"
                                    lineSwitch.Parent = frame
                                    Instance.new("UICorner", lineSwitch).CornerRadius = UDim.new(0, 5)
                                    
                                    local textBox, preview, modeSwitch, infoLabel
                                    
                                    local function updateLineDisplay()
                                        local d = TitleData[activeLine]
                                        lineSwitch.Text = "Line " .. activeLine
                                        
                                        if textBox and textBox.Parent then
                                            textBox.Text = d.Text
                                        end
                                        
                                        if preview and preview.Parent then
                                            preview.Text = d.Text ~= "" and d.Text or "PREVIEW"
                                            
                                            if d.Mode == "PRESET" then
                                                local preset = PRESETS[d.PresetIdx]
                                                if preset then
                                                    applyAnim(preview, ANIMS[d.AnimIdx], preset.Colors)
                                                    if infoLabel and infoLabel.Parent then
                                                        infoLabel.Text = preset.Name .. " - " .. ANIMS[d.AnimIdx]
                                                    end
                                                end
                                            else
                                                applySolid(preview, SOLIDS[d.SolidIdx])
                                                if infoLabel and infoLabel.Parent then
                                                    infoLabel.Text = "Solid " .. d.SolidIdx
                                                end
                                            end
                                        end
                                        
                                        if modeSwitch and modeSwitch.Parent then
                                            modeSwitch.Text = d.Mode
                                        end
                                    end
                                    
                                    lineSwitch.MouseButton1Click:Connect(function()
                                        activeLine = (activeLine % 10) + 1
                                        updateLineDisplay()
                                    end)
                                    
                                    local editor = Instance.new("Frame")
                                    editor.Position = UDim2.new(0, 0, 0, 156)
                                    editor.Size = UDim2.new(1, 0, 0, 178)
                                    editor.BackgroundTransparency = 1
                                    editor.Parent = frame
                                    
                                    textBox = Instance.new("TextBox")
                                    textBox.Position = UDim2.new(0.04, 0, 0, 0)
                                    textBox.Size = UDim2.new(0.92, 0, 0, 26)
                                    textBox.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
                                    textBox.TextColor3 = Color3.new(1, 1, 1)
                                    textBox.Font = Enum.Font.Gotham
                                    textBox.TextSize = 12
                                    textBox.PlaceholderText = "Enter Text..."
                                    textBox.Text = ""
                                    textBox.Parent = editor
                                    Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)
                                    
                                    modeSwitch = Instance.new("TextButton")
                                    modeSwitch.Position = UDim2.new(0.04, 0, 0, 32)
                                    modeSwitch.Size = UDim2.new(0.28, 0, 0, 22)
                                    modeSwitch.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                                    modeSwitch.TextColor3 = Color3.new(1, 1, 1)
                                    modeSwitch.Text = "PRESET"
                                    modeSwitch.Font = Enum.Font.GothamBold
                                    modeSwitch.TextSize = 10
                                    modeSwitch.Parent = editor
                                    Instance.new("UICorner", modeSwitch).CornerRadius = UDim.new(0, 5)
                                    
                                    local colorBtn = Instance.new("TextButton")
                                    colorBtn.Position = UDim2.new(0.36, 0, 0, 32)
                                    colorBtn.Size = UDim2.new(0.28, 0, 0, 22)
                                    colorBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                                    colorBtn.TextColor3 = Color3.new(1, 1, 1)
                                    colorBtn.Text = "🎨"
                                    colorBtn.Font = Enum.Font.GothamBold
                                    colorBtn.TextSize = 10
                                    colorBtn.Parent = editor
                                    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 5)
                                    
                                    local animBtn = Instance.new("TextButton")
                                    animBtn.Position = UDim2.new(0.68, 0, 0, 32)
                                    animBtn.Size = UDim2.new(0.28, 0, 0, 22)
                                    animBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                                    animBtn.TextColor3 = Color3.new(1, 1, 1)
                                    animBtn.Text = "⚡"
                                    animBtn.Font = Enum.Font.GothamBold
                                    animBtn.TextSize = 10
                                    animBtn.Parent = editor
                                    Instance.new("UICorner", animBtn).CornerRadius = UDim.new(0, 5)
                                    
                                    infoLabel = Instance.new("TextLabel")
                                    infoLabel.Position = UDim2.new(0.04, 0, 0, 60)
                                    infoLabel.Size = UDim2.new(0.92, 0, 0, 14)
                                    infoLabel.BackgroundTransparency = 1
                                    infoLabel.Font = Enum.Font.Gotham
                                    infoLabel.TextSize = 9
                                    infoLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
                                    infoLabel.Text = "Style 1"
                                    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
                                    infoLabel.Parent = editor
                                    
                                    preview = Instance.new("TextLabel")
                                    preview.Position = UDim2.new(0.04, 0, 0, 79)
                                    preview.Size = UDim2.new(0.92, 0, 0, 28)
                                    preview.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
                                    preview.Font = Enum.Font.GothamBold
                                    preview.TextColor3 = Color3.new(1, 1, 1)
                                    preview.TextSize = 12
                                    preview.Text = "PREVIEW"
                                    preview.Parent = editor
                                    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
                                    
                                    local infoBox = Instance.new("Frame")
                                    infoBox.Position = UDim2.new(0.04, 0, 0, 113)
                                    infoBox.Size = UDim2.new(0.92, 0, 0, 60)
                                    infoBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                                    infoBox.BorderSizePixel = 0
                                    infoBox.Parent = editor
                                    Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 6)
                                    
                                    local infoText = Instance.new("TextLabel")
                                    infoText.Size = UDim2.new(1, -8, 1, -8)
                                    infoText.Position = UDim2.new(0, 4, 0, 4)
                                    infoText.BackgroundTransparency = 1
                                    infoText.Font = Enum.Font.Gotham
                                    infoText.TextSize = 9
                                    infoText.TextColor3 = Color3.fromRGB(180, 180, 180)
                                    infoText.TextWrapped = true
                                    infoText.TextXAlignment = Enum.TextXAlignment.Left
                                    infoText.TextYAlignment = Enum.TextYAlignment.Top
                                    infoText.Text = "Click 'Line' button to cycle 1→10\nPRESET: Color + Animation\nSOLID: Single color only"
                                    infoText.Parent = infoBox
                                    
                                    modeSwitch.MouseButton1Click:Connect(function()
                                        local d = TitleData[activeLine]
                                        d.Mode = (d.Mode == "PRESET") and "SOLID" or "PRESET"
                                        modeSwitch.Text = d.Mode
                                        
                                        if d.Mode == "PRESET" then
                                            local preset = PRESETS[d.PresetIdx]
                                            if preset then
                                                applyAnim(preview, ANIMS[d.AnimIdx], preset.Colors)
                                                infoLabel.Text = preset.Name .. " - " .. ANIMS[d.AnimIdx]
                                            end
                                        else
                                            applySolid(preview, SOLIDS[d.SolidIdx])
                                            infoLabel.Text = "Solid " .. d.SolidIdx
                                        end
                                    end)
                                    
                                    colorBtn.MouseButton1Click:Connect(function()
                                        local d = TitleData[activeLine]
                                        if d.Mode == "PRESET" then
                                            d.PresetIdx = (d.PresetIdx % #PRESETS) + 1
                                            local preset = PRESETS[d.PresetIdx]
                                            if preset then
                                                applyAnim(preview, ANIMS[d.AnimIdx], preset.Colors)
                                                infoLabel.Text = preset.Name .. " - " .. ANIMS[d.AnimIdx]
                                            end
                                        else
                                            d.SolidIdx = (d.SolidIdx % #SOLIDS) + 1
                                            applySolid(preview, SOLIDS[d.SolidIdx])
                                            colorBtn.BackgroundColor3 = SOLIDS[d.SolidIdx]
                                            infoLabel.Text = "Solid " .. d.SolidIdx
                                        end
                                    end)
                                    
                                    animBtn.MouseButton1Click:Connect(function()
                                        local d = TitleData[activeLine]
                                        if d.Mode == "PRESET" then
                                            d.AnimIdx = (d.AnimIdx % #ANIMS) + 1
                                            local preset = PRESETS[d.PresetIdx]
                                            if preset then
                                                applyAnim(preview, ANIMS[d.AnimIdx], preset.Colors)
                                                infoLabel.Text = preset.Name .. " - " .. ANIMS[d.AnimIdx]
                                            end
                                        end
                                    end)
                                    
                                    textBox:GetPropertyChangedSignal("Text"):Connect(function()
                                        if textBox and textBox.Parent then
                                            TitleData[activeLine].Text = textBox.Text
                                            if preview and preview.Parent then
                                                preview.Text = textBox.Text ~= "" and textBox.Text or "PREVIEW"
                                            end
                                        end
                                    end)
                                    
                                    local footer = Instance.new("Frame")
                                    footer.Size = UDim2.new(1, 0, 0, 42)
                                    footer.Position = UDim2.new(0, 0, 1, -42)
                                    footer.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
                                    footer.BorderSizePixel = 0
                                    footer.Parent = frame
                                    Instance.new("UICorner", footer).CornerRadius = UDim.new(0, 8)
                                    
                                    local applyBtn = Instance.new("TextButton")
                                    applyBtn.Size = UDim2.new(0.46, 0, 0.6, 0)
                                    applyBtn.Position = UDim2.new(0.03, 0, 0.2, 0)
                                    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
                                    applyBtn.TextColor3 = Color3.new(1, 1, 1)
                                    applyBtn.Font = Enum.Font.GothamBold
                                    applyBtn.Text = "✓ APPLY"
                                    applyBtn.TextSize = 12
                                    applyBtn.Parent = footer
                                    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)
                                    
                                    applyBtn.MouseButton1Click:Connect(function()
                                        if not selectedPlayer then return end
                                        
                                        local packet = {Target = selectedPlayer.Name}
                                        for i = 1, 10 do
                                            local d = TitleData[i]
                                            packet["T" .. i] = d.Text
                                            packet["M" .. i] = d.Mode
                                            packet["P" .. i] = d.PresetIdx
                                            packet["A" .. i] = d.AnimIdx
                                            packet["S" .. i] = d.SolidIdx
                                        end
                                        ApplyEvent:FireServer(packet)
                                    end)
                                    
                                    local clearBtn = Instance.new("TextButton")
                                    clearBtn.Size = UDim2.new(0.46, 0, 0.6, 0)
                                    clearBtn.Position = UDim2.new(0.51, 0, 0.2, 0)
                                    clearBtn.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
                                    clearBtn.TextColor3 = Color3.new(1, 1, 1)
                                    clearBtn.Font = Enum.Font.GothamBold
                                    clearBtn.Text = "🗑 CLEAR"
                                    clearBtn.TextSize = 12
                                    clearBtn.Parent = footer
                                    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)
                                    
                                    clearBtn.MouseButton1Click:Connect(function()
                                        if not selectedPlayer then return end
                                        ApplyEvent:FireServer({Target = selectedPlayer.Name, ClearLine = activeLine})
                                    end)
                                    
                                    local function refreshPlayers()
                                        for _, c in ipairs(plScroll:GetChildren()) do
                                            if c:IsA("TextButton") then c:Destroy() end
                                        end
                                        
                                        for _, plr in ipairs(Players:GetPlayers()) do
                                            local btn = Instance.new("TextButton")
                                            btn.Parent = plScroll
                                            btn.Size = UDim2.new(1, -6, 0, 20)
                                            btn.Text = plr.Name
                                            btn.Font = Enum.Font.GothamBold
                                            btn.TextSize = 11
                                            btn.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
                                            btn.TextColor3 = Color3.new(1, 1, 1)
                                            btn.BorderSizePixel = 0
                                            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                                            
                                            btn.MouseButton1Click:Connect(function()
                                                if selectedPlayer == plr then
                                                    if selectedBtn then
                                                        selectedBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
                                                    end
                                                    selectedPlayer = nil
                                                    selectedBtn = nil
                                                    return
                                                end
                                                
                                                if selectedBtn then
                                                    selectedBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
                                                end
                                                
                                                selectedPlayer = plr
                                                selectedBtn = btn
                                                btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                                                
                                                ApplyEvent:FireServer({RequestData = true, TargetName = plr.Name})
                                            end)
                                        end
                                        
                                        plScroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 23)
                                    end
                                    
                                    Players.PlayerAdded:Connect(refreshPlayers)
                                    Players.PlayerRemoving:Connect(refreshPlayers)
                                    refreshPlayers()
                                    
                                    ApplyEvent.OnClientEvent:Connect(function(packet)
                                        if not packet or not packet.LoadedData then return end
                                        if not selectedPlayer or packet.Target ~= selectedPlayer.Name then return end
                                        
                                        local d = packet.LoadedData
                                        for i = 1, 10 do
                                            TitleData[i].Text = d["T" .. i] or ""
                                            TitleData[i].Mode = d["M" .. i] or "PRESET"
                                            TitleData[i].PresetIdx = d["P" .. i] or 1
                                            TitleData[i].AnimIdx = d["A" .. i] or 1
                                            TitleData[i].SolidIdx = d["S" .. i] or 1
                                        end
                                        
                                        updateLineDisplay()
                                    end)
                                    
                                    updateLineDisplay()

