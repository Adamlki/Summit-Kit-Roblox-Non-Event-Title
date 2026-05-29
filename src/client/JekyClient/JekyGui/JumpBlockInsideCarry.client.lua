-- LocalScript (Simple Jump Disable While Carried)
 
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
 
local player = Players.LocalPlayer
 
local function blockJump()
    return Enum.ContextActionResult.Sink
end
 
-- Hide / Show Mobile Jump Button
local function setMobileJumpVisible(state)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local touchGui = playerGui:FindFirstChild("TouchGui")
    if touchGui and touchGui:FindFirstChild("TouchControlFrame") then
        local jumpButton = touchGui.TouchControlFrame:FindFirstChild("JumpButton")
        if jumpButton then
            jumpButton.Visible = state
        end
    end
end
 
local function disableJump()
    -- Block Space (PC)
    CAS:BindAction("BlockJump", blockJump, false, Enum.KeyCode.Space)
    
    -- Hide Mobile Button
    setMobileJumpVisible(false)
end
 
local function enableJump()
    -- Unblock Space
    CAS:UnbindAction("BlockJump")
    
    -- Show Mobile Button
    setMobileJumpVisible(true)
end
 
local function setupCharacter(char)
    -- Jika sudah digendong saat spawn
    if char:GetAttribute("IsCarried") then
        disableJump()
    end
    
    char:GetAttributeChangedSignal("IsCarried"):Connect(function()
        if char:GetAttribute("IsCarried") then
            disableJump()
        else
            enableJump()
        end
    end)
end
 
if player.Character then
    setupCharacter(player.Character)
end
 
player.CharacterAdded:Connect(setupCharacter)

