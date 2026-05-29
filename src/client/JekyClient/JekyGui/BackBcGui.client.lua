-- StarterGui > ListGui > LocalScript  (bisa digabung 1 LocalScript dengan VipShopClient)
 
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
 
-- GUI
local ListGui     = playerGui:WaitForChild("ListGui")
local ListGuiKiri = ListGui:WaitForChild("ListGuiKiri")
local BcButton    = ListGuiKiri:WaitForChild("BcButton")
 
local IsiGui      = playerGui:WaitForChild("IsiGui")
local BackBcFrame = IsiGui:WaitForChild("BackBc")
local YesButton   = BackBcFrame:WaitForChild("YesButton")
local NoButton    = BackBcFrame:WaitForChild("NoButton")
 
-- Remote
local VandraEvents        = ReplicatedStorage:WaitForChild("VandraEvents")
local CP_RequestResetToBC = VandraEvents:WaitForChild("CP_RequestResetToBC")
 
-- Setup awal
BackBcFrame.Visible = false
 
local function closeFrame()
    BackBcFrame.Visible = false
end
 
-- Tombol
BcButton.MouseButton1Click:Connect(function()
    BackBcFrame.Visible = not BackBcFrame.Visible
end)
 
YesButton.MouseButton1Click:Connect(function()
    closeFrame()
    CP_RequestResetToBC:FireServer()
end)
 
NoButton.MouseButton1Click:Connect(closeFrame)
 
-- Auto close jika TextButton lain di ListGui ditekan
local function connectAutoClose(obj)
    if obj:IsA("TextButton") and obj ~= BcButton then
        obj.MouseButton1Click:Connect(closeFrame)
    end
end
 
for _, desc in ipairs(ListGui:GetDescendants()) do
    connectAutoClose(desc)
end
ListGui.DescendantAdded:Connect(connectAutoClose)

