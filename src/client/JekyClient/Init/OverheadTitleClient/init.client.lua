-- StarterPlayer/StarterPlayerScripts/OverheadTitlesClient
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
 
local LocalPlayer = Players.LocalPlayer
 
local OverheadFolder = ReplicatedStorage:WaitForChild("Overhead")
local TEMPLATE       = OverheadFolder:WaitForChild("BillboardGui")
 
local VandraEvents  = ReplicatedStorage:WaitForChild("VandraEvents")
local OT_TitleUpdate = VandraEvents:WaitForChild("OT_TitleUpdate")
 
local TitlesHidden     = false
local ActiveBillboards = {}
local ActiveAnimations = {}
 
-- Warna random cerah untuk NameLabel (unik per UserId)
local NAME_BRIGHT_COLORS = {
Color3.fromRGB(255, 80,  80),   -- merah
Color3.fromRGB(180, 80,  255),  -- ungu
Color3.fromRGB(80,  180, 255),  -- biru muda
Color3.fromRGB(255, 100, 200),  -- pink
Color3.fromRGB(80,  220, 100),  -- hijau
Color3.fromRGB(255, 200, 60),   -- kuning
Color3.fromRGB(60,  220, 220),  -- cyan
Color3.fromRGB(255, 140, 60),   -- oranye
}
 
local function getNameColorForUser(userId)
    local idx = (userId % #NAME_BRIGHT_COLORS) + 1
    return NAME_BRIGHT_COLORS[idx]
end
 
-- Gradient animasi gaya VIP (untuk Owner & Community)
local VIP_GRADIENT_COLORS = {
ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,   255, 255)),
ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 0,   255)),
ColorSequenceKeypoint.new(0.50, Color3.fromRGB(170, 0, 255)),
ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 0)),
ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0,   255, 255)),
}
 
local SPECIAL_GRADIENTS = {
Minus = {
Colors = { Color3.fromRGB(138, 43, 226), Color3.fromRGB(75, 0, 130), Color3.fromRGB(25, 25, 112) },
Speed = 0.02, RotationSpeed = 3,
},
Gradient1K = {
Colors = { Color3.fromRGB(0, 100, 255), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 0) },
Speed = 0.02, RotationSpeed = 3,
},
Gradient2K = {
Colors = { Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 0) },
Speed = 0.02, RotationSpeed = 3,
},
Gradient3K = {
Colors = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 127, 0), Color3.fromRGB(255, 255, 0) },
Speed = 0.02, RotationSpeed = 3,
},
Gradient5K = {
Colors = {
Color3.fromRGB(148, 0, 211), Color3.fromRGB(75, 0, 130), Color3.fromRGB(0, 0, 255),
Color3.fromRGB(0, 255, 0),   Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 127, 0),
Color3.fromRGB(255, 0, 0),
},
Speed = 0.02, RotationSpeed = 4,
},
}
 
-- ============================================================
-- UTILITY
-- ============================================================
 
local function cleanupDuplicates(character)
    if not character or not character.Parent then return end
    local allTitles = {}
    local function findTitlesIn(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "VandraOverhead" and child:IsA("BillboardGui") then
                table.insert(allTitles, child)
            end
        end
    end
    findTitlesIn(character:FindFirstChild("Head"))
    findTitlesIn(character)
    table.sort(allTitles, function(a, b)
        return (a:GetAttribute("CreationTime") or 0) > (b:GetAttribute("CreationTime") or 0)
    end)
    for i = 2, #allTitles do
        pcall(function() allTitles[i]:Destroy() end)
        end
        end
 
            local function forceCreateTitle(character)
                if not character or not character.Parent then return nil end
                cleanupDuplicates(character)
                local head = character:FindFirstChild("Head")
                if not head then head = character:WaitForChild("Head", 3) end
                if not head then return nil end
                local bill = TEMPLATE:Clone()
                bill.Name = "VandraOverhead"
                bill:SetAttribute("CreationTime", tick())
                bill.Enabled = not TitlesHidden
                bill.Parent = head
                return bill
            end
 
            local function ensureTitle(character)
                if not character or not character.Parent then return nil end
                cleanupDuplicates(character)
                local head = character:FindFirstChild("Head")
                local bill = head and head:FindFirstChild("VandraOverhead")
                if bill and bill:IsA("BillboardGui") and bill.Parent then
                    bill.Enabled = not TitlesHidden
                    return bill
                end
                return forceCreateTitle(character)
            end
 
            -- ============================================================
            -- ANIMASI
            -- ============================================================
 
            local function stopAnimation(key)
                if ActiveAnimations[key] then
                    ActiveAnimations[key].active = false
                    ActiveAnimations[key] = nil
                end
            end
 
            local function cleanupLabel(label)
                if not label then return end
                for _, child in ipairs(label:GetChildren()) do
                    if child:IsA("UIGradient") then child:Destroy() end
                end
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
 
            -- Gradient animasi VIP (flow kiri ke kanan, loop)
            local function startVipGradientAnimation(label, key)
                if not label then return end
                stopAnimation(key)
                cleanupLabel(label)
 
                local uiGradient = Instance.new("UIGradient")
                uiGradient.Color    = ColorSequence.new(VIP_GRADIENT_COLORS)
                uiGradient.Rotation = 0
                uiGradient.Offset   = Vector2.new(-1, 0)
                uiGradient.Parent   = label
 
                local token = { active = true }
                ActiveAnimations[key] = token
 
                local tween = TweenService:Create(
                uiGradient,
                TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
                { Offset = Vector2.new(1, 0) }
                )
                tween:Play()
 
                task.spawn(function()
                    while token.active and label.Parent and label:IsDescendantOf(game) do
                        task.wait(1)
                    end
                    tween:Cancel()
                end)
            end
 
            -- Gradient berotasi untuk summit special
            local function startRotatingGradientAnimation(label, config, key)
                if not label or not config or not config.Colors then return end
                stopAnimation(key)
                cleanupLabel(label)
 
                local uiGradient = Instance.new("UIGradient")
                local keypoints  = {}
                for i, color in ipairs(config.Colors) do
                    local pos = (i - 1) / math.max(1, #config.Colors - 1)
                    table.insert(keypoints, ColorSequenceKeypoint.new(pos, color))
                end
                uiGradient.Color    = ColorSequence.new(keypoints)
                uiGradient.Rotation = 0
                uiGradient.Parent   = label
 
                local token = { active = true }
                ActiveAnimations[key] = token
 
                task.spawn(function()
                    local rotation      = 0
                    local rotationSpeed = config.RotationSpeed or 3
                    local speed         = config.Speed or 0.02
                    while token.active and label.Parent and label:IsDescendantOf(game) do
                        rotation = rotation + rotationSpeed
                        if rotation >= 360 then rotation = 0 end
                        uiGradient.Rotation = rotation
                        task.wait(speed)
                    end
                end)
            end
 
            -- ============================================================
            -- REFRESH TITLE
            -- ============================================================
 
            local function getSpecialGradientForTotal(total)
                total = tonumber(total) or 0
                if total < 0       then return SPECIAL_GRADIENTS.Minus
                elseif total >= 5000 then return SPECIAL_GRADIENTS.Gradient5K
                elseif total >= 3000 then return SPECIAL_GRADIENTS.Gradient3K
                elseif total >= 2000 then return SPECIAL_GRADIENTS.Gradient2K
                elseif total >= 1000 then return SPECIAL_GRADIENTS.Gradient1K
                end
                    return nil
                end
 
                local function refreshTitle(plr)
                    if not plr or not plr.Parent then return false end
                    local char = plr.Character
                    if not char or not char.Parent then return false end
                    local bill = ensureTitle(char)
                    if not bill then return false end
                    bill.Enabled = not TitlesHidden
 
                    local overFrame = bill:FindFirstChild("Over")
                    if not overFrame then return false end
 
                    local roleLabel  = overFrame:FindFirstChild("Role")
                    local totalLabel = overFrame:FindFirstChild("Total")
                    local levelLabel = overFrame:FindFirstChild("Level")
 
                    -- NameLabel: Label > NameLabel
                    local labelFrame = overFrame:FindFirstChild("Label")
                    local nameLabel  = labelFrame and labelFrame:FindFirstChild("NameLabel")
 
                    -- ============ NAME LABEL ============
                    pcall(function()
                        local overheadName = plr:GetAttribute("OverheadNameText") or plr.DisplayName or plr.Name
                        if nameLabel then
                            nameLabel.Text = tostring(overheadName)
                            -- Warna solid random cerah berdasarkan UserId
                            stopAnimation("Name_" .. plr.UserId)
                            cleanupLabel(nameLabel)
                            nameLabel.TextColor3 = getNameColorForUser(plr.UserId)
                        end
                    end)
 
                    -- ============ ROLE LABEL ============
                    pcall(function()
                        local roleTitle      = plr:GetAttribute("RoleTitle") or ""
                        local roleDisplay    = plr:GetAttribute("RoleDisplayText") or ""
                        local roleColor      = plr:GetAttribute("RoleColor")
                        local roleUsesGradient = plr:GetAttribute("RoleUsesGradient")
 
                        if roleLabel then
                            if roleTitle ~= "" and roleDisplay ~= "" then
                                roleLabel.Text = roleDisplay
                                roleLabel.TextTransparency      = 0
                                roleLabel.TextStrokeTransparency = 0.5
 
                                if roleUsesGradient then
                                    -- Owner & Community: gradient gaya VIP
                                    startVipGradientAnimation(roleLabel, "Role_" .. plr.UserId)
                                else
                                    -- Semua role lain: solid color
                                    stopAnimation("Role_" .. plr.UserId)
                                    cleanupLabel(roleLabel)
                                    if typeof(roleColor) == "Color3" then
                                        roleLabel.TextColor3 = roleColor
                                    else
                                        roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            else
                                roleLabel.Text = ""
                                roleLabel.TextTransparency      = 1
                                roleLabel.TextStrokeTransparency = 1
                                stopAnimation("Role_" .. plr.UserId)
                                cleanupLabel(roleLabel)
                            end
                        end
                    end)
 
                    -- ============ LEVEL & TOTAL (summit) ============
                    pcall(function()
                        local summitTitle        = plr:GetAttribute("SummitTitle") or "NEWBIE EXPLORER"
                        local summitTotal        = plr:GetAttribute("TotalSummitText") or "SUMMIT: 0"
                        local summitColor        = plr:GetAttribute("SummitColor")
                        local useSpecialGradient = plr:GetAttribute("UseSpecialSummitGradient")
                        local numericTotal       = tonumber(summitTotal:match("%d+")) or 0
 
                        if levelLabel then
                            levelLabel.Text = summitTitle
                            if useSpecialGradient then
                                local specialGradient = getSpecialGradientForTotal(numericTotal)
                                if specialGradient then
                                    startRotatingGradientAnimation(levelLabel, specialGradient, "Level_" .. plr.UserId)
                                end
                            else
                                stopAnimation("Level_" .. plr.UserId)
                                cleanupLabel(levelLabel)
                                if typeof(summitColor) == "Color3" then
                                    levelLabel.TextColor3 = summitColor
                                else
                                    levelLabel.TextColor3 = Color3.fromRGB(135, 206, 250)
                                end
                            end
                        end
 
                        if totalLabel then
                            totalLabel.Text = summitTotal
                            if useSpecialGradient then
                                local specialGradient = getSpecialGradientForTotal(numericTotal)
                                if specialGradient then
                                    startRotatingGradientAnimation(totalLabel, specialGradient, "Total_" .. plr.UserId)
                                end
                            else
                                stopAnimation("Total_" .. plr.UserId)
                                cleanupLabel(totalLabel)
                                if typeof(summitColor) == "Color3" then
                                    totalLabel.TextColor3 = summitColor
                                else
                                    totalLabel.TextColor3 = Color3.fromRGB(135, 206, 250)
                                end
                            end
                        end
                    end)
 
                    -- ============ VIP IMAGE LABEL ============
                    pcall(function()
                        local iconFrame = bill:FindFirstChild("Icon")
                        if iconFrame then
                            local vipImage = iconFrame:FindFirstChild("Vip")
                            if vipImage then
                                local hasVip = plr:GetAttribute("HasVipTitle") == true
                                vipImage.Visible = hasVip
                            end
                        end
                    end)
 
                    ActiveBillboards[plr.UserId] = bill
                    return true
                end
 
                -- ============================================================
                -- VISIBILITY
                -- ============================================================
 
                local function setTitlesHidden(hidden)
                    TitlesHidden = hidden
                    task.spawn(function()
                        for _, p in ipairs(Players:GetPlayers()) do
                            pcall(function()
                                local char = p.Character
                                if char then
                                    local head = char:FindFirstChild("Head")
                                    if head then
                                        local bill = head:FindFirstChild("VandraOverhead")
                                        if bill then bill.Enabled = not hidden end
                                    end
                                end
                            end)
                        end
                    end)
                end
 
                _G.OverheadTitleAPI = _G.OverheadTitleAPI or {}
                _G.OverheadTitleAPI.setHideTitle = setTitlesHidden
 
                -- ============================================================
                -- HOOK PLAYER
                -- ============================================================
 
                local function hookPlayer(plr)
                    local connections = {}
 
                    local function onCharacterAdded(char)
                        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
                        connections = {}
                        cleanupDuplicates(char)
 
                        local head = char:WaitForChild("Head", 3)
                        if not head then return end
 
                        task.wait(0.3)
                        local success  = false
                        local attempts = 0
                        while not success and attempts < 3 and char.Parent and plr.Parent do
                            attempts = attempts + 1
                            cleanupDuplicates(char)
                            task.wait(0.1)
                            success = refreshTitle(plr)
                            if not success then
                                forceCreateTitle(char)
                                    task.wait(0.1)
                                    success = refreshTitle(plr)
                                end
                                if not success and attempts < 3 then task.wait(0.2) end
                            end
 
                            local conn = char.ChildAdded:Connect(function(child)
                                if child.Name == "Head" then task.wait(0.1); refreshTitle(plr) end
                            end)
                            table.insert(connections, conn)
                        end
 
                        plr.CharacterAdded:Connect(onCharacterAdded)
                        if plr.Character then onCharacterAdded(plr.Character) end
 
                        plr.CharacterRemoving:Connect(function(char)
                            cleanupDuplicates(char)
                            for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
                            connections = {}
                        end)
 
                        local lastAttributeUpdate = 0
                        local function onAttributeChange()
                            local now = tick()
                            if (now - lastAttributeUpdate) > 0.1 then
                                lastAttributeUpdate = now
                                task.defer(function() refreshTitle(plr) end)
                                end
                                end
 
                                    plr:GetAttributeChangedSignal("RoleTitle"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("RoleDisplayText"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("RoleColor"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("RoleUsesGradient"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("SummitTitle"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("TotalSummitText"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("OverheadNameText"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("SummitColor"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("UseSpecialSummitGradient"):Connect(onAttributeChange)
                                    plr:GetAttributeChangedSignal("HasVipTitle"):Connect(onAttributeChange)
                                end
 
                                OT_TitleUpdate.OnClientEvent:Connect(function()
                                    if LocalPlayer and LocalPlayer.Parent then
                                        task.defer(function() refreshTitle(LocalPlayer) end)
                                        end
                                        end)
 
                                            local function cleanupPlayer(plr)
                                                local uid = plr.UserId
                                                ActiveBillboards[uid] = nil
                                                stopAnimation("Role_"  .. uid)
                                                stopAnimation("Name_"  .. uid)
                                                stopAnimation("Level_" .. uid)
                                                stopAnimation("Total_" .. uid)
                                            end
 
                                            for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
                                            Players.PlayerAdded:Connect(function(p) hookPlayer(p) end)
                                                Players.PlayerRemoving:Connect(function(p) cleanupPlayer(p) end)
 
                                                    -- Periodic check
                                                    task.spawn(function()
                                                        while true do
                                                            task.wait(3)
                                                            for _, plr in ipairs(Players:GetPlayers()) do
                                                                pcall(function()
                                                                    local char = plr.Character
                                                                    if char and char.Parent then
                                                                        local head = char:FindFirstChild("Head")
                                                                        if head then
                                                                            local bill = head:FindFirstChild("VandraOverhead")
                                                                            if not bill or not bill.Parent then
                                                                                ensureTitle(char)
                                                                                refreshTitle(plr)
                                                                            else
                                                                                bill.Enabled = not TitlesHidden
                                                                            end
                                                                        end
                                                                    end
                                                                end)
                                                            end
                                                        end
                                                    end)

