local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
 
local Player = Players.LocalPlayer
local ApplyEvent = RS:WaitForChild("ApplyCustomTitle")
 
local JekyConfig = require(RS:WaitForChild("Shared"):WaitForChild("JekyConfig"))
local isAdmin = JekyConfig.IsAdmin(Player.UserId, Player.Name)
 
local playerGui = Player:WaitForChild("PlayerGui")

-- Cek ListGui dan tombol toggle
local listGui = playerGui:WaitForChild("ListGui", 10)
if not listGui then
    warn("[TittlegiverNew] ListGui tidak ditemukan di PlayerGui!")
    return
end

local toggleBtn = listGui:WaitForChild("TitleButton")

if not isAdmin then
    toggleBtn.Visible = false
    return
end

toggleBtn.Visible = true
 
local PRESETS = {
	{Name = "Cyber Dreams", Colors = {Color3.fromRGB(0, 255, 255), Color3.fromRGB(180, 0, 255), Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 105, 180)}},
	{Name = "Primary Mix", Colors = {Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0)}},
	{Name = "Pastel Dreams", Colors = {Color3.fromRGB(135, 206, 250), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 192, 203)}},
	{Name = "Neon Vibes", Colors = {Color3.fromRGB(138, 43, 226), Color3.fromRGB(255, 20, 147), Color3.fromRGB(0, 255, 255)}},
	{Name = "Sunset Fire", Colors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 69, 0)}}
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

-- =========================================================
-- MENGHUBUNGKAN VARIABEL KE GUI YANG SUDAH DIBUAT
-- =========================================================
local titlePanel = playerGui:WaitForChild("TitlePanel", 10)
if not titlePanel then
    warn("[TittlegiverNew] UI TitlePanel_V3 tidak ditemukan! Pastikan GUI sudah ada di StarterGui.")
    return
end

local frame = titlePanel:WaitForChild("MainFrame")
local header = frame:WaitForChild("Header")
local closeBtn = header:WaitForChild("CloseBtn")
local plScroll = frame:WaitForChild("PlayerScroll")
local lineSwitch = frame:WaitForChild("LineSwitch")

local editor = frame:WaitForChild("Editor")
local textBox = editor:WaitForChild("TextBox")
local modeSwitch = editor:WaitForChild("ModeSwitch")
local colorBtn = editor:WaitForChild("ColorBtn")
local animBtn = editor:WaitForChild("AnimBtn")
local infoLabel = editor:WaitForChild("InfoLabel")
local preview = editor:WaitForChild("Preview")

local footer = frame:WaitForChild("Footer")
local applyBtn = footer:WaitForChild("ApplyBtn")
local clearBtn = footer:WaitForChild("ClearBtn")

-- Sembunyikan frame secara default
frame.Visible = false

-- Event Toggle Button dari ListGui
toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Event Close Button
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
end)
                                    
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