-- StarterPlayer > StarterPlayerScripts > DonationClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- CONFIGURATION
-- ============================================
local GAME_NAME        = "MOUNT ARVENIX"
local NOTIFY_SOUND_ID  = "rbxassetid://126960584587035" -- Ganti dengan Sound ID milikmu
local NOTIFY_DURATION  = 3   -- detik frame tampil
local NOTIFY_INTERVAL  = 0.5 -- jeda antar notifikasi dalam antrian

-- ============================================
-- VARIABLES
-- ============================================
local IsiGui, FrameDonation
local DonationButton
local CloseButton
local ScrollingFrame

local isFrameOpen      = false
local originalPosition
local hiddenPosition
local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local donationPackages = {}

local GetDonationPackagesRF
local PurchaseDonationRE
local DonationNotifyRE

-- Notification queue (anti-spam / anti-overlap)
local notifyQueue   = {}
local notifyRunning = false

-- ============================================
-- FIND DONATION TOGGLE BUTTON
-- ============================================
local function findDonationButton()
    local listGui = playerGui:FindFirstChild("ListGui")
    if listGui then
        local listTopBar = listGui:FindFirstChild("ListTopBarKanan")
        if listTopBar then
            local btn = listTopBar:FindFirstChild("DonationButton")
            if btn and btn:IsA("TextButton") then
                return btn
            end
        end
    end
    
    local fallback = playerGui:FindFirstChild("DonationButton", true)
    if fallback and fallback:IsA("TextButton") then
        return fallback
    end
    
    return nil
end

-- ============================================
-- SETUP REMOTES
-- ============================================
local function setupRemotes()
    GetDonationPackagesRF = ReplicatedStorage:FindFirstChild("Donation_GetPackages")
    if not GetDonationPackagesRF then
        pcall(function()
            GetDonationPackagesRF = ReplicatedStorage:WaitForChild("Donation_GetPackages", 5)
        end)
    end
    
    PurchaseDonationRE = ReplicatedStorage:FindFirstChild("Donation_Purchase")
    if not PurchaseDonationRE then
        pcall(function()
            PurchaseDonationRE = ReplicatedStorage:WaitForChild("Donation_Purchase", 5)
        end)
    end
    
    DonationNotifyRE = ReplicatedStorage:FindFirstChild("Donation_Notify")
    
    return GetDonationPackagesRF ~= nil and PurchaseDonationRE ~= nil
end

-- ============================================
-- WAIT FOR GUI ELEMENTS
-- ============================================
local function waitForElements()
    for _ = 1, 50 do
        IsiGui = playerGui:FindFirstChild("IsiGui")
        
        if IsiGui then
            FrameDonation = IsiGui:FindFirstChild("FrameDonation")
            
            if FrameDonation then
                ScrollingFrame = FrameDonation:FindFirstChild("ScrollingFrame")
                CloseButton    = FrameDonation:FindFirstChild("CloseButton")
                
                if ScrollingFrame then
                    return true
                end
            end
        end
        
        task.wait(0.1)
    end
    
    return false
end

-- ============================================
-- LOAD DONATION PACKAGES
-- ============================================
local function loadDonationPackages()
    if not GetDonationPackagesRF then
        setupRemotes()
        if not GetDonationPackagesRF then return false end
    end
    
    if not ScrollingFrame or not ScrollingFrame.Parent then return false end
    
    local templateFrame = ScrollingFrame:FindFirstChild("Frame")
    if not templateFrame then return false end
    
    templateFrame.Visible = false
    
    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("Frame") and child ~= templateFrame then
            child:Destroy()
        end
    end
    
    local success, result = pcall(function()
        return GetDonationPackagesRF:InvokeServer()
    end)
    
    if not success or not result or type(result) ~= "table" then return false end
    
    donationPackages = result
    
    for index, package in ipairs(donationPackages) do
        local frame = templateFrame:Clone()
        frame.Name    = "DonationFrame_" .. index
        frame.Visible = true
        
        local hargaLabel = frame:FindFirstChild("HargaLabel")
        local buyButton  = frame:FindFirstChild("BuyButton")
        
        if hargaLabel and hargaLabel:IsA("TextLabel") then
            hargaLabel.Text = "$" .. (package.price or 0) .. " Robux"
        end
        
        if buyButton and buyButton:IsA("TextButton") then
            buyButton.MouseButton1Click:Connect(function()
                if PurchaseDonationRE then
                    PurchaseDonationRE:FireServer(package.id or index)
                end
            end)
        end
        
        frame.Parent = ScrollingFrame
    end
    
    return true
end

-- ============================================
-- OPEN / CLOSE FRAME  (slide dari kanan)
-- ============================================
local function openFrame()
    if isFrameOpen then return end
    isFrameOpen = true
    FrameDonation.Visible  = true
    FrameDonation.Position = hiddenPosition
    
    TweenService:Create(FrameDonation, tweenInfo, {Position = originalPosition}):Play()
    
    task.spawn(loadDonationPackages)
end

local function closeFrame()
    if not isFrameOpen then return end
    isFrameOpen = false
    
    TweenService:Create(FrameDonation, tweenInfo, {Position = hiddenPosition}):Play()
    
    task.delay(0.4, function()
        if FrameDonation then
            FrameDonation.Visible = false
        end
    end)
end

-- ============================================
-- AUTO CLOSE — semua TextButton di ListGui
-- ============================================
local function setupAutoClose()
    local listGui = playerGui:FindFirstChild("ListGui")
    if not listGui then return end
    
    local function connect(btn)
        if btn:IsA("TextButton") and btn ~= DonationButton and btn ~= CloseButton then
            btn.MouseButton1Click:Connect(function()
                if isFrameOpen then closeFrame() end
            end)
        end
    end
    
    for _, desc in ipairs(listGui:GetDescendants()) do
        connect(desc)
    end
    
    listGui.DescendantAdded:Connect(function(desc)
        task.wait(0.1)
        connect(desc)
    end)
end

-- ============================================
-- DONATION GLOBAL NOTIFICATION (anti-spam queue)
-- ============================================
local function playNotifySound()
    local sound = Instance.new("Sound")
    sound.SoundId = NOTIFY_SOUND_ID
    sound.Volume  = 1
    sound.Parent  = SoundService
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 5)
end

local function showDonationGlobal(donorName, amount)
    local summitGui = playerGui:FindFirstChild("SummitGUI")
    if not summitGui then return end
    
    local frame = summitGui:FindFirstChild("DonationGlobal")
    if not frame then return end
    
    local label = frame:FindFirstChild("TextLabel")
    if not label then return end
    
    label.Text      = donorName .. " : Donation to " .. GAME_NAME .. "  $" .. tostring(amount) .. " Robux"
    frame.Visible   = true
    
    playNotifySound()
    
    task.wait(NOTIFY_DURATION)
    
    frame.Visible = false
end

local function processNotifyQueue()
    if notifyRunning then return end
    notifyRunning = true
    
    while #notifyQueue > 0 do
        local entry = table.remove(notifyQueue, 1)
        showDonationGlobal(entry.name, entry.amount)
        task.wait(NOTIFY_INTERVAL)
    end
    
    notifyRunning = false
end

local function queueNotification(donorName, amount)
    table.insert(notifyQueue, {name = donorName, amount = amount})
    task.spawn(processNotifyQueue)
end

-- ============================================
-- SETUP NOTIFICATION LISTENER
-- ============================================
local function setupNotificationListener()
    if not DonationNotifyRE then
        DonationNotifyRE = ReplicatedStorage:FindFirstChild("Donation_Notify")
    end
    
    if DonationNotifyRE then
        DonationNotifyRE.OnClientEvent:Connect(function(donorName, amount)
            if donorName and amount then
                queueNotification(donorName, amount)
            end
        end)
    end
end

-- ============================================
-- INITIALIZE SYSTEM
-- ============================================
local function initializeSystem()
    local guiReady = waitForElements()
    if not guiReady then
        task.wait(5)
        guiReady = waitForElements()
        if not guiReady then return end
    end
    
    setupRemotes()
    
    -- Posisi asli (dari kanan layar)
    originalPosition = FrameDonation.Position
    hiddenPosition   = UDim2.new(1.2, 0, originalPosition.Y.Scale, originalPosition.Y.Offset)
    
    FrameDonation.Visible  = false
    FrameDonation.Position = hiddenPosition
    
    -- Setup toggle button
    DonationButton = findDonationButton()
    
    if DonationButton then
        local connection
        connection = DonationButton.MouseButton1Click:Connect(function()
            if connection then connection:Disconnect() end
            
            if isFrameOpen then closeFrame() else openFrame() end
            
            task.wait(0.5)
            if DonationButton and DonationButton.Parent then
                connection = DonationButton.MouseButton1Click:Connect(function()
                    if isFrameOpen then closeFrame() else openFrame() end
                end)
            end
        end)
    else
        -- Fallback keyboard
        game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == Enum.KeyCode.P then
                if isFrameOpen then closeFrame() else openFrame() end
            end
        end)
    end
    
    -- Close button
    if CloseButton then
        CloseButton.MouseButton1Click:Connect(closeFrame)
    end
    
    -- Auto-close dari ListGui
    setupAutoClose()
    
    -- Listener notifikasi donasi
    setupNotificationListener()
    
    -- Preload packages
    task.spawn(function()
        task.wait(2)
        loadDonationPackages()
    end)
end

-- ============================================
-- MAIN
-- ============================================
local function main()
    task.wait(2)
    
    local success = pcall(initializeSystem)
    if not success then
        task.wait(5)
        pcall(initializeSystem)
    end
    
    -- Retry cari button jika belum ketemu
    if not DonationButton then
        for _ = 1, 3 do
            task.wait(5)
            DonationButton = findDonationButton()
            if DonationButton then
                DonationButton.MouseButton1Click:Connect(function()
                    if isFrameOpen then closeFrame() else openFrame() end
                end)
                break
            end
        end
    end
end

task.spawn(main)

