-- StarterGui/SummitGUI/SpeedRunGUI (LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
local summitGUI = playerGui:WaitForChild("SummitGUI", 30)
if not summitGUI then return end
 
-- STRUKTUR
local speedRun = summitGUI:WaitForChild("SpeedRun", 10)
if not speedRun then return end
 
local detik  = speedRun:WaitForChild("Detik", 10)
local memory = speedRun:WaitForChild("Memory", 10)
if not detik or not memory then return end
 
-- Remote Events
local VandraEvents = ReplicatedStorage:WaitForChild("VandraEvents", 30)
if not VandraEvents then return end
 
local SR_Start        = VandraEvents:WaitForChild("SR_Start", 10)
local SR_Finish       = VandraEvents:WaitForChild("SR_Finish", 10)
local SR_UpdateMemory = VandraEvents:WaitForChild("SR_UpdateMemory", 10)
local SR_Cheat        = VandraEvents:WaitForChild("SR_Cheat", 10)
if not SR_Start or not SR_Finish or not SR_UpdateMemory or not SR_Cheat then return end
 
-- ══════════════════════════════════════
-- CONFIG ANIMASI
-- ══════════════════════════════════════
local ORIGIN_POS = speedRun.Position
local HIDDEN_POS = UDim2.new(
ORIGIN_POS.X.Scale + 1.2,
ORIGIN_POS.X.Offset,
ORIGIN_POS.Y.Scale,
ORIGIN_POS.Y.Offset
)
 
local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
 
local function showFrame()
    speedRun.Position = HIDDEN_POS
    speedRun.Visible  = true
    TweenService:Create(speedRun, tweenInfo, { Position = ORIGIN_POS }):Play()
end
 
local function hideFrame()
    local tween = TweenService:Create(speedRun, tweenInfo, { Position = HIDDEN_POS })
    tween:Play()
    tween.Completed:Connect(function()
        speedRun.Visible = false
    end)
end
 
-- ══════════════════════════════════════
-- FUNCTIONS
-- ══════════════════════════════════════
local isRunning   = false
local startTime   = 0
local timerActive = false
 
local function formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end
 
local function startTimer()
    if timerActive then
        timerActive = false
        task.wait(0.1)
    end
    isRunning   = true
    startTime   = os.clock()
    timerActive = true
    
    task.spawn(function()
        while timerActive and isRunning do
            local elapsed = os.clock() - startTime
            detik.Text = formatTime(elapsed)
            task.wait(0.1)
        end
    end)
end
 
local function stopTimer(displayText)
    timerActive = false
    isRunning   = false
    if displayText then
        detik.Text = displayText
    end
end
 
-- ══════════════════════════════════════
-- INIT
-- ══════════════════════════════════════
speedRun.Visible = false
detik.Text       = "00:00:00"
memory.Text      = "BT: 00:00:00"
 
-- ══════════════════════════════════════
-- EVENT HANDLERS
-- ══════════════════════════════════════
SR_Start.OnClientEvent:Connect(function()
    detik.Text = "00:00:00"
    
    if not speedRun.Visible then  -- hanya buka jika belum terbuka
        showFrame()
    end
    
    startTimer()  -- selalu reset & jalankan timer tanpa ganggu frame
end)
 
SR_Finish.OnClientEvent:Connect(function()
    stopTimer("FINISH 🏁")
    task.delay(3, function()
        hideFrame()
    end)
end)
 
SR_UpdateMemory.OnClientEvent:Connect(function(bestTime)
    if bestTime and bestTime > 0 then
        memory.Text = "BT: " .. formatTime(bestTime)
    else
        memory.Text = "BT: 00:00:00"
    end
    -- tidak buka/tutup frame, update text saja
end)
 
SR_Cheat.OnClientEvent:Connect(function()
    stopTimer("UR CHEAT 🚫")
    task.delay(3, function()
        hideFrame()
    end)
end)

