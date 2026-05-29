local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
COLOR_UNVISITED = Color3.fromRGB(255, 0, 0),
COLOR_VISITED   = Color3.fromRGB(0, 255, 0),

SOUND_CP     = "rbxassetid://123301789997223",
SOUND_SUMMIT = "rbxassetid://119348994415738",
SOUND_APEX   = "rbxassetid://119348994415738",

NOTIF_DURATION       = 3,
SUMMIT_ANIM_DURATION = 2,
FADE_TIME            = 0.3,

SHAKE_INTENSITY = 0.35,
SHAKE_DURATION  = 0.45,
SHAKE_FREQUENCY = 0.03,
}

local ROMAN_LUT = { "I","II","III","IV","V","VI","VII","VIII","IX","X" }
local ROMAN_VALS = {
{1000,"M"},{900,"CM"},{500,"D"},{400,"CD"},
{100,"C"},{90,"XC"},{50,"L"},{40,"XL"},
{10,"X"},{9,"IX"},{5,"V"},{4,"IV"},{1,"I"},
}

local function toRoman(n)
    if n <= 0 then return "0" end
    if n <= 10 then return ROMAN_LUT[n] end
    local result = ""
    for _, pair in ipairs(ROMAN_VALS) do
        while n >= pair[1] do
            result = result .. pair[2]
            n = n - pair[1]
        end
    end
    return result
end

local SummitGUI
local NotifFrame
local NotifLabel
local AngkaLabel

local VisitedCheckpoints     = {}
local CurrentCheckpoint      = "BC"
local LastNotifiedCheckpoint = nil
local BCNotifiedThisRound    = false

local VandraEvents
local CheckpointFolder

local OriginalColors         = {}
local OriginalParticleColors = {}

-- ============================================================
-- SCREEN SHAKE (gerak NotifFrame, bukan kamera)
-- ============================================================

local shakeActive     = false
local shakeConnection = nil

local function screenShake(intensity, duration, frequency)
    if shakeActive then return end
    if not NotifFrame then return end
    
    shakeActive = true
    local elapsed  = 0
    local lastTick = os.clock()
    local basePos  = NotifFrame.Position
    
    shakeConnection = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= duration then
            if shakeConnection then shakeConnection:Disconnect(); shakeConnection = nil end
            shakeActive = false
            NotifFrame.Position = basePos
            return
        end
        local now = os.clock()
        if (now - lastTick) >= frequency then
            lastTick = now
            local decay = 1 - (elapsed / duration)
            local mag   = intensity * decay * 12
            local ox    = math.random(-100, 100) / 100 * mag
            local oy    = math.random(-100, 100) / 100 * mag
            NotifFrame.Position = UDim2.new(
            basePos.X.Scale,  basePos.X.Offset + ox,
            basePos.Y.Scale,  basePos.Y.Offset + oy
            )
        end
    end)
end

-- ============================================================
-- LABEL FADE
-- ============================================================

local function tweenLabelAlpha(label, target, duration)
    if not label then return end
    local info = TweenInfo.new(duration or CONFIG.FADE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(label, info, { TextTransparency = target, TextStrokeTransparency = target }):Play()
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if stroke then TweenService:Create(stroke, info, { Transparency = target }):Play() end
end

local function setLabelAlpha(label, alpha)
    if not label then return end
    label.TextTransparency       = alpha
    label.TextStrokeTransparency = alpha
    local stroke = label:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Transparency = alpha end
end

local notifThread

local function cancelNotif()
    if notifThread then task.cancel(notifThread); notifThread = nil end
end

-- ============================================================
-- NOTIFICATION
-- Checkpoint CP → angka Romawi
-- Summit / ApexSummit → angka biasa (tanpa Romawi sama sekali)
-- ============================================================

local function showNotif(checkpointId, summitValue, oldTotal, newTotal)
    if not NotifFrame or not NotifLabel then return end
    
    cancelNotif()
    
    setLabelAlpha(NotifLabel, 1)
    if AngkaLabel then setLabelAlpha(AngkaLabel, 1); AngkaLabel.Visible = false end
    
    local isSummitType = (checkpointId == "Summit" or checkpointId == "ApexSummit")
    local showAngka    = true
    local notifText    = ""
    
    if checkpointId == "BC" then
        notifText = "GO!!"
        showAngka = false
        
    elseif isSummitType then
        -- Summit: judul saja, tanpa romawi
        notifText = "SUMMIT COUNT"
        
    elseif string.match(checkpointId, "^CP(%d+)$") then
        local num = tonumber(string.match(checkpointId, "%d+"))
        notifText = "CHECKPOINT"
        -- CP tetap pakai angka Romawi
        if AngkaLabel then AngkaLabel.Text = toRoman(num) end
        
    else
        notifText = checkpointId
        showAngka = false
    end
    
    NotifLabel.Text    = notifText
    NotifFrame.Visible = true
    
    if showAngka and AngkaLabel then
        if isSummitType then
            -- Tampilan awal Summit: angka biasa (angka acak sementara animasi)
            AngkaLabel.Text = tostring(oldTotal)
            .. "   +   " .. tostring(math.random(1, 10))
            .. "   =   " .. tostring(math.random(1, 10))
        end
        AngkaLabel.Visible = true
        setLabelAlpha(AngkaLabel, 1)
    end
    
    tweenLabelAlpha(NotifLabel, 0, CONFIG.FADE_TIME)
    if showAngka and AngkaLabel then tweenLabelAlpha(AngkaLabel, 0, CONFIG.FADE_TIME) end
    
    screenShake(CONFIG.SHAKE_INTENSITY, CONFIG.SHAKE_DURATION, CONFIG.SHAKE_FREQUENCY)
    
    notifThread = task.spawn(function()
        if isSummitType and showAngka and AngkaLabel then
            -- Animasi 2 detik: oldTotal tetap angka biasa, +value & =total angka acak biasa
            local endAt = os.clock() + CONFIG.SUMMIT_ANIM_DURATION
            while os.clock() < endAt do
                AngkaLabel.Text = tostring(oldTotal)
                .. "   +   " .. tostring(math.random(1, 99))
                .. "   =   " .. tostring(math.random(1, 99))
                task.wait(0.08)
            end
            
            -- Tampilkan nilai asli Summit: semua angka biasa
            AngkaLabel.Text = tostring(oldTotal)
            .. "   +   " .. tostring(summitValue)
            .. "   =   " .. tostring(newTotal)
            
            task.wait(4)
        else
            task.wait(CONFIG.NOTIF_DURATION)
        end
        
        tweenLabelAlpha(NotifLabel, 1, CONFIG.FADE_TIME)
        if showAngka and AngkaLabel then tweenLabelAlpha(AngkaLabel, 1, CONFIG.FADE_TIME) end
        task.wait(CONFIG.FADE_TIME + 0.05)
        NotifFrame.Visible = false
        if AngkaLabel then AngkaLabel.Visible = false end
    end)
end

-- ============================================================
-- GUI SETUP
-- ============================================================

local function setupGUI()
    SummitGUI = PlayerGui:WaitForChild("SummitGUI", 10)
    if not SummitGUI then return false end
    
    NotifFrame = SummitGUI:WaitForChild("NotifCp", 5)
    if NotifFrame then
        NotifLabel = NotifFrame:FindFirstChild("NotifLabel")
        AngkaLabel = NotifFrame:FindFirstChild("AngkaLabel")
        NotifFrame.Visible = false
        if AngkaLabel then AngkaLabel.Visible = false end
    end
    
    return true
end

local function setupCheckpointFolder()
    local vandra = workspace:WaitForChild("AllPartSummitkitVandra", 10)
    if not vandra then return false end
    CheckpointFolder = vandra:WaitForChild("Checkpoint", 5)
    if not CheckpointFolder then return false end
    return true
end

local function setupBillboardLabels()
    if not CheckpointFolder then return end
    for _, model in ipairs(CheckpointFolder:GetChildren()) do
        if not model:IsA("Model") then continue end
        local num = tonumber(string.match(model.Name, "^CP(%d+)$"))
        if not num then continue end
        local spawnLoc = model:FindFirstChildOfClass("SpawnLocation")
        if not spawnLoc then continue end
        local billboard = spawnLoc:FindFirstChildOfClass("BillboardGui")
        if not billboard then continue end
        local textLabel = billboard:FindFirstChildOfClass("TextLabel")
        if not textLabel then continue end
        textLabel.Text = "CHECKPOINT " .. num
    end
end

-- ============================================================
-- SOUND
-- ============================================================

local function playSound(soundId)
    if not soundId or soundId == "" then return end
    task.spawn(function()
        local sound   = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume  = 5
        sound.Parent  = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
        end)
        end
            
            local function playSoundForCheckpoint(checkpointId)
                if checkpointId == "BC" then return
                elseif checkpointId == "ApexSummit" then playSound(CONFIG.SOUND_APEX)
                elseif checkpointId == "Summit"     then playSound(CONFIG.SOUND_SUMMIT)
                elseif string.match(checkpointId, "^CP%d+$") then playSound(CONFIG.SOUND_CP)
                end
                end
                    
                    -- ============================================================
                    -- PART COLOR
                    -- ============================================================
                    
                    local function cacheOriginalColor(part)
                        if not part or not part:IsA("BasePart") then return end
                        local key = part:GetFullName()
                        if not OriginalColors[key] then OriginalColors[key] = part.Color end
                        for _, d in ipairs(part:GetDescendants()) do
                            local dk = d:GetFullName()
                            if OriginalParticleColors[dk] then continue end
                            if d:IsA("ParticleEmitter") then
                                OriginalParticleColors[dk] = { Type = "ParticleEmitter", Color = d.Color }
                            elseif d:IsA("Beam") then
                                OriginalParticleColors[dk] = { Type = "Beam", Color = d.Color }
                            elseif d:IsA("Trail") then
                                OriginalParticleColors[dk] = { Type = "Trail", Color = d.Color }
                            elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                                OriginalParticleColors[dk] = { Type = "Light", Color = d.Color }
                            end
                        end
                    end
                    
                    local function setPartColor(part, color)
                        if not part or not part:IsA("BasePart") then return end
                        cacheOriginalColor(part)
                        part.Color = color
                        for _, d in ipairs(part:GetDescendants()) do
                            if d:IsA("ParticleEmitter")  then d.Color = ColorSequence.new(color)
                            elseif d:IsA("Beam")         then d.Color = ColorSequence.new(color)
                            elseif d:IsA("Trail")        then d.Color = ColorSequence.new(color)
                            elseif d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                                d.Color = color
                            end
                        end
                    end
                    
                    local function resolveColorPart(checkpointId)
                        if not CheckpointFolder then return nil end
                        local model = CheckpointFolder:FindFirstChild(checkpointId)
                        if not model then
                            local map = { Summit = "SUMMIT", ApexSummit = "BIGSUMMIT" }
                            local alt = map[checkpointId]
                            if alt then model = CheckpointFolder:FindFirstChild(alt) end
                        end
                        if not model or not model:IsA("Model") then return nil end
                        return model:FindFirstChildOfClass("SpawnLocation") or model:FindFirstChildOfClass("BasePart")
                    end
                    
                    local function updatePartColor(checkpointId, isVisited)
                        local part = resolveColorPart(checkpointId)
                        if not part then return end
                        if isVisited then
                            setPartColor(part, CONFIG.COLOR_VISITED)
                            VisitedCheckpoints[checkpointId] = true
                        else
                            setPartColor(part, CONFIG.COLOR_UNVISITED)
                            VisitedCheckpoints[checkpointId] = nil
                        end
                    end
                    
                    local function resetAllPartColors()
                        if not CheckpointFolder then return end
                        VisitedCheckpoints = {}
                        for _, child in ipairs(CheckpointFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local part = child:FindFirstChildOfClass("SpawnLocation") or child:FindFirstChildOfClass("BasePart")
                                if part then setPartColor(part, CONFIG.COLOR_UNVISITED) end
                            end
                        end
                    end
                    
                    -- ============================================================
                    -- REMOTE EVENTS
                    -- ============================================================
                    
                    local function setupRemoteEvents()
                        VandraEvents = ReplicatedStorage:WaitForChild("VandraEvents", 10)
                        if not VandraEvents then return false end
                        
                        local cpUpdated = VandraEvents:WaitForChild("CP_CheckpointUpdated", 5)
                        if cpUpdated then
                            cpUpdated.OnClientEvent:Connect(function(checkpointId)
                                CurrentCheckpoint = checkpointId
                                if checkpointId == "BC" then
                                    resetAllPartColors()
                                    VisitedCheckpoints["BC"] = true
                                    updatePartColor("BC", true)
                                    BCNotifiedThisRound = false
                                else
                                    VisitedCheckpoints[checkpointId] = true
                                end
                            end)
                        end
                        
                        local cpTouched = VandraEvents:WaitForChild("CP_PlayerTouched", 5)
                        if cpTouched then
                            cpTouched.OnClientEvent:Connect(function(data)
                                local checkpointId = data.CheckpointId
                                local summitValue  = data.SummitValue or 0
                                local isNewRound   = data.IsNewRound
                                
                                local isNew = (LastNotifiedCheckpoint ~= checkpointId)
                                
                                if isNewRound then
                                    LastNotifiedCheckpoint = nil
                                    isNew               = true
                                    BCNotifiedThisRound = false
                                end
                                
                                if not isNew then return end
                                
                                if checkpointId == "BC" then
                                    if not BCNotifiedThisRound then
                                        BCNotifiedThisRound    = true
                                        LastNotifiedCheckpoint = "BC"
                                        showNotif("BC", 0, 0, 0)
                                    end
                                    
                                elseif checkpointId == "Summit" or checkpointId == "ApexSummit" then
                                    task.spawn(function()
                                        task.wait(0.15)
                                        local ls       = LocalPlayer:FindFirstChild("leaderstats")
                                        local newTotal = ls and ls:FindFirstChild("Summit") and ls.Summit.Value or 0
                                        local oldTotal = math.max(0, newTotal - summitValue)
                                        showNotif(checkpointId, summitValue, oldTotal, newTotal)
                                        LastNotifiedCheckpoint = checkpointId
                                        BCNotifiedThisRound    = false
                                    end)
                                    
                                elseif string.match(checkpointId, "^CP%d+$") then
                                    showNotif(checkpointId, 0, 0, 0)
                                    LastNotifiedCheckpoint = checkpointId
                                end
                                
                                playSoundForCheckpoint(checkpointId)
                            end)
                        end
                        
                        local skippedWarning = VandraEvents:WaitForChild("CP_SkippedWarning", 5)
                        if skippedWarning then
                            skippedWarning.OnClientEvent:Connect(function(expectedCP)
                                if not NotifFrame or not NotifLabel then return end
                                cancelNotif()
                                NotifLabel.Text = "CP TERLEWAT!"
                                setLabelAlpha(NotifLabel, 1)
                                if AngkaLabel then
                                    -- CP terlewat tetap pakai Romawi
                                    AngkaLabel.Text    = toRoman(expectedCP)
                                    AngkaLabel.Visible = true
                                    setLabelAlpha(AngkaLabel, 1)
                                end
                                NotifFrame.Visible = true
                                tweenLabelAlpha(NotifLabel, 0, CONFIG.FADE_TIME)
                                if AngkaLabel then tweenLabelAlpha(AngkaLabel, 0, CONFIG.FADE_TIME) end
                                screenShake(CONFIG.SHAKE_INTENSITY * 0.6, CONFIG.SHAKE_DURATION, CONFIG.SHAKE_FREQUENCY)
                                
                                notifThread = task.spawn(function()
                                    task.wait(CONFIG.NOTIF_DURATION)
                                    tweenLabelAlpha(NotifLabel, 1, CONFIG.FADE_TIME)
                                    if AngkaLabel then tweenLabelAlpha(AngkaLabel, 1, CONFIG.FADE_TIME) end
                                    task.wait(CONFIG.FADE_TIME + 0.05)
                                    NotifFrame.Visible = false
                                    if AngkaLabel then AngkaLabel.Visible = false end
                                end)
                            end)
                        end
                        
                        local colorUpdate = VandraEvents:WaitForChild("CP_PartColorUpdate", 5)
                        if colorUpdate then
                            colorUpdate.OnClientEvent:Connect(function(checkpointId, colorType)
                                if colorType == "visited"       then updatePartColor(checkpointId, true)
                                elseif colorType == "unvisited" then updatePartColor(checkpointId, false)
                                elseif colorType == "reset"     then resetAllPartColors()
                                end
                                end)
                                end
                                    
                                    return true
                                end
                                
                                -- ============================================================
                                -- LEADERSTATS MONITOR
                                -- ============================================================
                                
                                local function monitorLeaderstats()
                                    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
                                    if not leaderstats then return end
                                    local checkpoint = leaderstats:WaitForChild("Checkpoint", 5)
                                    if checkpoint then
                                        checkpoint.Changed:Connect(function(newValue)
                                            CurrentCheckpoint = newValue
                                            if newValue == "BC" then
                                                resetAllPartColors()
                                                VisitedCheckpoints["BC"] = true
                                                updatePartColor("BC", true)
                                            end
                                        end)
                                        CurrentCheckpoint = checkpoint.Value
                                    end
                                end
                                
                                -- ============================================================
                                -- INIT
                                -- ============================================================
                                
                                local function initialize()
                                    if not setupGUI() then return end
                                    if not setupCheckpointFolder() then return end
                                    if not setupRemoteEvents() then return end
                                    
                                    setupBillboardLabels()
                                    
                                    resetAllPartColors()
                                    VisitedCheckpoints["BC"] = true
                                    updatePartColor("BC", true)
                                    
                                    monitorLeaderstats()
                                end
                                
                                task.spawn(initialize)
                                
                                _G.VandraClientDebug = {
                                GetVisitedCheckpoints = function() return VisitedCheckpoints end,
                                    GetCurrentCheckpoint  = function() return CurrentCheckpoint end,
                                        TestNotif             = function(id) showNotif(id or "BC", 0, 0, 0) end,
                                            TestSummitNotif       = function(val, old, new_)
                                                showNotif("Summit", val or 100, old or 900, new_ or 1000)
                                            end,
                                            TestSound = function(t)
                                                if t == "CP" then playSound(CONFIG.SOUND_CP)
                                                elseif t == "Summit" then playSound(CONFIG.SOUND_SUMMIT)
                                                elseif t == "Apex" then playSound(CONFIG.SOUND_APEX) end
                                                end,
                                                    ResetColors = function() resetAllPartColors() end,
                                                        }

