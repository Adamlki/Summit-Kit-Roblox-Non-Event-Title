-- StarterPlayer/StarterPlayerScripts/MusicSystemClient.lua
 
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
 
-- ============================================
-- SETTINGS
-- ============================================
local AUTO_PLAY = true  -- Set ke true agar musik otomatis play saat masuk game
 
-- ============================================
-- CORE VARIABLES
-- ============================================
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
local IsiGui
local MusikPanel
local PlayButton
local PauseButton
local NextButton
local PrevButton
local CloseButton
local NameLagu
local DetikLagu
local VolumeBar
local VolumeSlider
 
local currentSound = nil
local currentIndex = 1
local isPlaying = false
local isFrameOpen = false
local volume = 1
 
local musicFolder
local soundList = {}
 
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local originalPosition
local hiddenPosition
 
-- ============================================
-- INITIALIZE MUSIC FOLDER
-- ============================================
local function initializeMusicFolder()
    local root = Workspace:WaitForChild("AllPartSummitkitJeky", 10)
    if not root then
        warn("[MusicSystem] AllPartSummitkitJeky not found")
        return false
    end
 
    musicFolder = root:WaitForChild("MusikFolder", 10)
    if not musicFolder then
        warn("[MusicSystem] MusikFolder not found")
        return false
    end
 
    soundList = {}
    for _, sound in ipairs(musicFolder:GetChildren()) do
        if sound:IsA("Sound") then
            table.insert(soundList, sound)
        end
    end
 
    return #soundList > 0
end
 
-- ============================================
-- UPDATE SONG NAME & TIME
-- ============================================
local function updateSongName()
    if NameLagu then
        NameLagu.Text = currentSound and currentSound.Name or "No Music"
    end
end
 
local function updateTimeDisplay()
    task.spawn(function()
        while true do
            if currentSound and currentSound.IsPlaying and DetikLagu then
                local cur = currentSound.TimePosition
                local tot = currentSound.TimeLength
                DetikLagu.Text = string.format(
                "%02d:%02d / %02d:%02d",
                math.floor(cur / 60), math.floor(cur % 60),
                math.floor(tot / 60), math.floor(tot % 60)
                )
            elseif DetikLagu then
                DetikLagu.Text = "00:00 / 00:00"
            end
            task.wait(0.5)
        end
    end)
end
 
-- ============================================
-- VOLUME CONTROL (VERTICAL SLIDER)
-- ============================================
local function updateVolume()
    if currentSound then
        currentSound.Volume = volume
    end
 
    if VolumeSlider and VolumeBar then
        local normalizedVolume = (volume - 0.1) / 0.9
        local yScale = 1 - normalizedVolume
        VolumeSlider.Position = UDim2.new(0.5, 0, yScale, 0)
    end
end
 
local function setVolumeFromSlider(positionY)
    if not VolumeBar then return end
 
    local minY = VolumeBar.AbsolutePosition.Y
    local maxY = minY + VolumeBar.AbsoluteSize.Y
    local clampedY = math.clamp(positionY, minY, maxY)
    local relativeY = (clampedY - minY) / (maxY - minY)
 
    volume = math.clamp(1 - (relativeY * 0.9), 0.1, 1)
    updateVolume()
end
 
local function initializeVolumeSlider()
    if not VolumeBar or not VolumeSlider then return end
 
    local isDragging = false
 
    VolumeSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)
 
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
 
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            setVolumeFromSlider(input.Position.Y)
        end
    end)
 
    VolumeBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch then
            setVolumeFromSlider(input.Position.Y)
        end
    end)
 
    volume = 1
    updateVolume()
end
 
-- ============================================
-- PLAY / PAUSE / STOP
-- ============================================
local function playMusic()
    if not currentSound then return end
 
    for _, sound in ipairs(soundList) do
        if sound ~= currentSound and sound.IsPlaying then
            sound:Stop()
        end
    end
 
    currentSound.Volume = volume
    currentSound:Play()
    isPlaying = true
 
    if PlayButton then PlayButton.Visible = false end
    if PauseButton then PauseButton.Visible = true end
 
    updateSongName()
end
 
local function pauseMusic()
    if currentSound then currentSound:Pause() end
    isPlaying = false
 
    if PlayButton then PlayButton.Visible = true end
    if PauseButton then PauseButton.Visible = false end
end
 
local function stopMusic()
    if currentSound then currentSound:Stop() end
    isPlaying = false
 
    if PlayButton then PlayButton.Visible = true end
    if PauseButton then PauseButton.Visible = false end
end
 
-- ============================================
-- NEXT / PREV SONG
-- ============================================
local function nextSong()
    if #soundList == 0 then return end
    currentIndex = (currentIndex % #soundList) + 1
    stopMusic()
    currentSound = soundList[currentIndex]
    playMusic()
end
 
local function prevSong()
    if #soundList == 0 then return end
    currentIndex = currentIndex - 1
    if currentIndex < 1 then currentIndex = #soundList end
    stopMusic()
    currentSound = soundList[currentIndex]
    playMusic()
end
 
-- ============================================
-- OPEN / CLOSE PANEL
-- ============================================
local function openFrame()
    if not MusikPanel then return end
    isFrameOpen = true
    MusikPanel.Visible = true
    TweenService:Create(MusikPanel, tweenInfo, {Position = originalPosition}):Play()
end
 
local function closeFrame()
    if not MusikPanel then return end
    isFrameOpen = false
    TweenService:Create(MusikPanel, tweenInfo, {Position = hiddenPosition}):Play()
    task.wait(0.3)
    MusikPanel.Visible = false
end
 
-- ============================================
-- WAIT FOR GUI ELEMENTS (reliable WaitForChild)
-- ============================================
local function waitForElements()
    -- Tunggu IsiGui dengan WaitForChild agar tidak bergantung pada polling
    local ok, result = pcall(function()
        IsiGui = playerGui:WaitForChild("IsiGui", 15)
    end)
    if not ok or not IsiGui then
        warn("[MusicSystem] IsiGui tidak ditemukan!")
        return false
    end
 
    local ok2, result2 = pcall(function()
        MusikPanel = IsiGui:WaitForChild("MusikPanel", 15)
    end)
    if not ok2 or not MusikPanel then
        warn("[MusicSystem] MusikPanel tidak ditemukan!")
        return false
    end
 
    -- Fungsi helper untuk WaitForChild yang aman
    local function safeWait(parent, name, timeout)
        local ok3, child = pcall(function()
            return parent:WaitForChild(name, timeout or 5)
        end)
        return ok3 and child or nil
    end
 
    PlayButton  = safeWait(MusikPanel, "PlayButton")
    PauseButton = safeWait(MusikPanel, "PauseButton")
    NextButton  = safeWait(MusikPanel, "NextButton")
    PrevButton  = safeWait(MusikPanel, "PrevButton")
    CloseButton = safeWait(MusikPanel, "CloseButton")
    NameLagu    = safeWait(MusikPanel, "NameLagu")
    DetikLagu   = safeWait(MusikPanel, "DetikLagu")
    VolumeBar   = safeWait(MusikPanel, "VolumeBar")
 
    if VolumeBar then
        VolumeSlider = safeWait(VolumeBar, "VolumeSlider")
    end
 
    return true
end
 
-- ============================================
-- FIND MUSIK BUTTON
-- ============================================
local function findMusikButton()
    -- Cari dulu di semua GUI yang sudah ada
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Name == "MusikButton" then
            return gui
        end
    end
    -- Kalau belum ada, tunggu sebentar lalu cari lagi
    task.wait(2)
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Name == "MusikButton" then
            return gui
        end
    end
    warn("[MusicSystem] MusikButton tidak ditemukan!")
    return nil
end
 
-- ============================================
-- AUTO CLOSE PANEL WHEN OTHER GUI CLICKED
-- ============================================
local function setupAutoClose()
    local skipButtons = {
    MusikButton = true,
    PlayButton = true,
    PauseButton = true,
    NextButton = true,
    PrevButton = true,
    CloseButton = true,
    VolumeSlider = true,
    }
 
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") and not skipButtons[gui.Name] then
            gui.MouseButton1Click:Connect(function()
                if isFrameOpen then
                    closeFrame()
                end
            end)
        end
    end
end
 
-- ============================================
-- INITIALIZE SYSTEM
-- ============================================
local function initializeSystem()
    if not waitForElements() then return end
    if not initializeMusicFolder() then return end
 
    if #soundList == 0 then
        warn("[MusicSystem] Tidak ada lagu tersedia!")
        return
    end
 
    currentSound = soundList[currentIndex]
    if currentSound then
        currentSound.Volume = volume
    end
 
    -- Simpan posisi panel
    originalPosition = MusikPanel.Position
    hiddenPosition = UDim2.new(
    originalPosition.X.Scale,
    -MusikPanel.AbsoluteSize.X - 50,
    originalPosition.Y.Scale,
    originalPosition.Y.Offset
    )
 
    -- State awal panel
    MusikPanel.Visible = false
    MusikPanel.Position = hiddenPosition
 
    if PlayButton then PlayButton.Visible = true end
    if PauseButton then PauseButton.Visible = false end
 
    updateSongName()
    updateTimeDisplay()
 
    if VolumeBar and VolumeSlider then
        initializeVolumeSlider()
    end
 
    -- Tombol MusikButton
    local mainMusikButton = findMusikButton()
    if mainMusikButton then
        mainMusikButton.MouseButton1Click:Connect(function()
            if isFrameOpen then
                closeFrame()
            else
                openFrame()
            end
        end)
    end
 
    -- Hubungkan tombol kontrol
    if PlayButton  then PlayButton.MouseButton1Click:Connect(playMusic)   end
    if PauseButton then PauseButton.MouseButton1Click:Connect(pauseMusic) end
    if NextButton  then NextButton.MouseButton1Click:Connect(nextSong)    end
    if PrevButton  then PrevButton.MouseButton1Click:Connect(prevSong)    end
    if CloseButton then CloseButton.MouseButton1Click:Connect(closeFrame) end
 
    -- Auto next saat lagu selesai
    for _, sound in ipairs(soundList) do
        if sound:IsA("Sound") then
            sound.Ended:Connect(function()
                if sound == currentSound then
                    nextSong()
                end
            end)
        end
    end
 
    setupAutoClose()
 
    -- Auto play saat masuk game
    if AUTO_PLAY then
        playMusic()
    end
end
 
-- ============================================
-- MAIN EXECUTION
-- ============================================
task.spawn(function()
    task.wait(1)
 
    local success, err = pcall(initializeSystem)
    if not success then
        warn("[MusicSystem ERROR]: " .. err)
    end
end)

