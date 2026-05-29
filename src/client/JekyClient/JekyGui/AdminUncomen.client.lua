local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
 
local SummitGUI  = PlayerGui:WaitForChild("SummitGUI")
local GlobalChat = SummitGUI:WaitForChild("GlobalChat")
local ChatLabel  = GlobalChat:WaitForChild("ChatLabel")
 
local ChatRemote = ReplicatedStorage:WaitForChild("SummitChatEvent")
 
GlobalChat.Visible = false
 
-- SOUND CONFIG
local SOUND_ID = "rbxassetid://112486094040833" -- GANTI DENGAN ID KAMU
 
local sound = Instance.new("Sound")
sound.SoundId = SOUND_ID
sound.Volume = 5
sound.Parent = GlobalChat
 
local hideThread
 
ChatRemote.OnClientEvent:Connect(function(message)
    
    ChatLabel.Text = message
    GlobalChat.Visible = true
    
    sound:Play()
    
    if hideThread then
        task.cancel(hideThread)
    end
    
    hideThread = task.delay(5, function()
        GlobalChat.Visible = false
    end)
    
end)

