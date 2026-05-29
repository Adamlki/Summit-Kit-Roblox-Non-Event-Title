-- StarterPlayerScripts/AvatarChangerClient.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
 
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
-- ============================================
-- AVATAR DATA (USER ID) - MIXED 50 TOTAL
-- ============================================
local AVATAR_LIST = {
-- ImageLabel1
8891157967,
 
-- Cowok (28)
9101259798, 8912185225, 8935877365, 8352609716,
8976748119, 8968308984, 4832303740, 9220382005,
9046030552, 9000844254, 8966687266, 9112933446,
9101259798, 8912185225, 8935877365, 8352609716,
8976748119, 8968308984, 4832303740, 9220382005,
9046030552, 9000844254, 8966687266, 9112933446,
9101259798, 8912185225, 8935877365, 8352609716,
7868126585,
 
-- Cewek (20)
9181935703, 7843828496, 3226668321, 7260068521,
8592887007, 9093398365, 8918025774, 8935328065,
8891975253, 8486540814, 9101275612, 9084296513,
9181935703, 7843828496, 3226668321, 7260068521,
8592887007, 9093398365, 8918025774, 8935328065
}
 
-- ============================================
-- VARIABLES
-- ============================================
local ListGui, AvatarButton
local IsiGui, AvatarPanel
local SearchTextBox, SearchButton, CloseButton
local ScrollingFrame, PreviewLabel, ApplyButton, RemoveButton
 
local selectedUserId = nil
local currentAppliedAvatar = nil
local isPanelOpen = false
 
local originalPosition
local hiddenPosition
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
 
-- RemoteEvents
local ChangeAvatarEvent, ResetAvatarEvent
 
-- ============================================
-- UPDATE BUTTON VISIBILITY & TEXT
-- ============================================
local function updateButtons()
    if not ApplyButton or not RemoveButton then return end
    
    if currentAppliedAvatar == selectedUserId then
        ApplyButton.Text = "Diterapkan"
    else
        ApplyButton.Text = "Terapkan"
    end
    
    ApplyButton.Visible = true
    RemoveButton.Visible = true
end
 
-- ============================================
-- UPDATE PREVIEW LABEL
-- ============================================
local function updatePreview(userId)
    if not PreviewLabel then return end
    
    task.spawn(function()
        local success, thumbnailUrl = pcall(function()
            return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.AvatarThumbnail,
            Enum.ThumbnailSize.Size420x420
            )
        end)
        
        if success and thumbnailUrl then
            PreviewLabel.Image = thumbnailUrl
            PreviewLabel.ImageRectOffset = Vector2.new(75, 0)
            PreviewLabel.ImageRectSize = Vector2.new(270, 420)
        end
    end)
end
 
-- ============================================
-- UPDATE BUTTON STATES
-- ============================================
local function updateButtonStates(clickedImageLabel)
    for i = 1, 50 do
        local imageLabel = ScrollingFrame:FindFirstChild("ImageLabel" .. i)
        if imageLabel then
            local textButton = imageLabel:FindFirstChild("TextButton")
            if textButton then
                if imageLabel == clickedImageLabel then
                    textButton.Text = "Dilihat"
                else
                    textButton.Text = "Melihat"
                end
            end
        end
    end
end
 
-- ============================================
-- SEARCH USERNAME
-- ============================================
local function searchUsername()
    local username = SearchTextBox.Text:gsub("%s+", "")
    if username == "" then return end
    
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    
    if success and userId then
        selectedUserId = userId
        updatePreview(userId)
        updateButtons()
    else
        SearchTextBox.PlaceholderText = "User not found"
        task.wait(2)
        SearchTextBox.PlaceholderText = "Enter username"
    end
    
    SearchTextBox.Text = ""
end
 
-- ============================================
-- OPEN/CLOSE PANEL
-- ============================================
function openPanel()
    isPanelOpen = true
    AvatarPanel.Visible = true
    TweenService:Create(AvatarPanel, tweenInfo, {Position = originalPosition}):Play()
    
    if AvatarButton then
        TweenService:Create(AvatarButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        }):Play()
    end
    
    if currentAppliedAvatar then
        selectedUserId = currentAppliedAvatar
        updatePreview(currentAppliedAvatar)
    else
        selectedUserId = AVATAR_LIST[1]
        updatePreview(AVATAR_LIST[1])
    end
    
    updateButtons()
end
 
function closePanel()
    isPanelOpen = false
    TweenService:Create(AvatarPanel, tweenInfo, {Position = hiddenPosition}):Play()
    
    if AvatarButton then
        TweenService:Create(AvatarButton, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        }):Play()
    end
    
    task.wait(0.35)
    AvatarPanel.Visible = false
end
 
-- ============================================
-- APPLY AVATAR
-- ============================================
local function applyAvatar()
    if not selectedUserId then return end
    
    if currentAppliedAvatar == selectedUserId then
        closePanel()
        return
    end
    
    -- Server handles tools backup/restore
    ChangeAvatarEvent:FireServer(selectedUserId)
    currentAppliedAvatar = selectedUserId
    updateButtons()
    
    task.wait(0.5)
    closePanel()
end
 
-- ============================================
-- REMOVE AVATAR (RESET TO ORIGINAL)
-- ============================================
local function removeAvatar()
    if currentAppliedAvatar == nil then
        closePanel()
        return
    end
    
    -- Server handles tools backup/restore
    ResetAvatarEvent:FireServer()
    currentAppliedAvatar = nil
    updateButtons()
    
    task.wait(0.5)
    closePanel()
end
 
-- ============================================
-- SETUP IMAGE LABELS
-- ============================================
local function setupImageLabels()
    for i = 1, 50 do
        local imageLabel = ScrollingFrame:FindFirstChild("ImageLabel" .. i)
        if imageLabel then
            local userId = AVATAR_LIST[i]
            
            if userId then
                imageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
                
                local textButton = imageLabel:FindFirstChild("TextButton")
                if textButton then
                    textButton.Text = "Melihat"
                    textButton.MouseButton1Click:Connect(function()
                        selectedUserId = userId
                        updatePreview(userId)
                        updateButtonStates(imageLabel)
                        updateButtons()
                    end)
                end
            else
                imageLabel.Visible = false
            end
        end
    end
end
 
-- ============================================
-- WAIT FOR GUI ELEMENTS
-- ============================================
local function waitForElements()
    local attempts = 0
    while attempts < 100 do
        ListGui = playerGui:FindFirstChild("ListGui")
        if ListGui then
            local listTopBar = ListGui:FindFirstChild("ListTopBar")
            if listTopBar then
                AvatarButton = listTopBar:FindFirstChild("AvatarButton")
            end
        end
        
        IsiGui = playerGui:FindFirstChild("IsiGui")
        if IsiGui then
            AvatarPanel = IsiGui:FindFirstChild("AvatarPanel")
            
            if AvatarPanel then
                SearchTextBox = AvatarPanel:FindFirstChild("TextBox")
                SearchButton = SearchTextBox and SearchTextBox:FindFirstChild("Button")
                CloseButton = AvatarPanel:FindFirstChild("CloseButton")
                ScrollingFrame = AvatarPanel:FindFirstChild("ScrollingFrame")
                PreviewLabel = AvatarPanel:FindFirstChild("PreviewLabel")
                
                if PreviewLabel then
                    ApplyButton = PreviewLabel:FindFirstChild("ApplyButton")
                    RemoveButton = PreviewLabel:FindFirstChild("RemoveButton")
                end
                
                if AvatarButton and SearchTextBox and CloseButton
                    and ScrollingFrame and PreviewLabel and ApplyButton and RemoveButton then
                    return true
                end
            end
        end
        
        attempts = attempts + 1
        task.wait(0.1)
    end
    
    return false
end
 
-- ============================================
-- INITIALIZE SYSTEM
-- ============================================
local function initializeSystem()
    if not waitForElements() then return end
    
    ChangeAvatarEvent = ReplicatedStorage:WaitForChild("ChangeAvatarEvent", 10)
    ResetAvatarEvent = ReplicatedStorage:WaitForChild("ResetAvatarEvent", 10)
    
    if not ChangeAvatarEvent or not ResetAvatarEvent then return end
    
    -- Setup PreviewLabel properties
    PreviewLabel.BackgroundTransparency = 1
    PreviewLabel.ScaleType = Enum.ScaleType.Fit
    PreviewLabel.SizeConstraint = Enum.SizeConstraint.RelativeXY
    PreviewLabel.ResampleMode = Enum.ResamplerMode.Default
    
    local aspect = PreviewLabel:FindFirstChildOfClass("UIAspectRatioConstraint")
    if not aspect then
        aspect = Instance.new("UIAspectRatioConstraint")
        aspect.Parent = PreviewLabel
    end
    aspect.AspectRatio = 110 / 200
    aspect.DominantAxis = Enum.DominantAxis.Height
    
    -- Setup positions
    originalPosition = AvatarPanel.Position
    hiddenPosition = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1.2, 0)
    
    -- Initial state
    AvatarPanel.Visible = false
    AvatarPanel.Position = hiddenPosition
    
    -- Setup ImageLabels
    setupImageLabels()
    
    -- Connect AvatarButton (toggle)
    AvatarButton.MouseButton1Click:Connect(function()
        if isPanelOpen then
            closePanel()
        else
            openPanel()
        end
    end)
    
    -- Connect SearchButton
    if SearchButton then
        SearchButton.MouseButton1Click:Connect(searchUsername)
    end
    
    -- Connect TextBox Enter
    SearchTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            searchUsername()
        end
    end)
    
    -- Connect CloseButton
    CloseButton.MouseButton1Click:Connect(closePanel)
    
    -- Connect ApplyButton
    ApplyButton.MouseButton1Click:Connect(applyAvatar)
    
    -- Connect RemoveButton
    RemoveButton.MouseButton1Click:Connect(removeAvatar)
    
    -- Auto close when other TextButtons in ListGui clicked
    if ListGui then
        for _, gui in ipairs(ListGui:GetDescendants()) do
            if gui:IsA("TextButton") and gui ~= AvatarButton then
                gui.MouseButton1Click:Connect(function()
                    if isPanelOpen then
                        closePanel()
                    end
                end)
            end
        end
    end
end
 
-- ============================================
-- MAIN EXECUTION
-- ============================================
task.spawn(function()
    task.wait(2)
    initializeSystem()
    
    player.CharacterAdded:Connect(function()
        task.wait(2)
        waitForElements()
    end)
end)

