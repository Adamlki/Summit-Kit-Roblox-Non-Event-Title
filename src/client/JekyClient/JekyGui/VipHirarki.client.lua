-- StarterGui > ListGui > LocalScript  (taruh LocalScript di dalam ListGui)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- GUI
local ListGui     = playerGui:WaitForChild("ListGui")
local ListGuiKiri = ListGui:WaitForChild("ListGuiKiri")
local VipButton   = ListGuiKiri:WaitForChild("VipButton")

local IsiGui    = playerGui:WaitForChild("IsiGui")
local ShopPanel = IsiGui:WaitForChild("ShopPanel")
local HargaLabel  = ShopPanel:WaitForChild("HargaLabel")
local BuyButton   = ShopPanel:WaitForChild("BuyButton")
local CloseButton = ShopPanel:WaitForChild("CloseButton")

-- Remotes
local RE_RequestVipPurchase = ReplicatedStorage:WaitForChild("RequestVipPurchase")
local RE_UpdateVipStatus    = ReplicatedStorage:WaitForChild("UpdateVipStatus")
local RF_GetVipStatus       = ReplicatedStorage:WaitForChild("GetVipStatus")
local RF_GetVipPrice        = ReplicatedStorage:WaitForChild("GetVipPrice")

-- Panel setup
local isOpen      = false
local originalPos = ShopPanel.Position
local hiddenPos   = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, -0.6, 0)
local tweenInfo   = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

ShopPanel.Visible  = false
ShopPanel.Position = hiddenPos

local function openPanel()
    if isOpen then return end
    isOpen = true
    ShopPanel.Visible = true
    TweenService:Create(ShopPanel, tweenInfo, { Position = originalPos }):Play()
end

local function closePanel()
    if not isOpen then return end
    isOpen = false
    local tw = TweenService:Create(ShopPanel, tweenInfo, { Position = hiddenPos })
    tw:Play()
    tw.Completed:Once(function()
        if not isOpen then ShopPanel.Visible = false end
    end)
end

-- Fetch harga dari server
task.spawn(function()
    local ok, price = pcall(function() return RF_GetVipPrice:InvokeServer() end)
        if ok and price then HargaLabel.Text = price end
    end)
    
    -- Cek status VIP awal
    task.spawn(function()
        local ok, isVip = pcall(function() return RF_GetVipStatus:InvokeServer() end)
            if ok and isVip then
                
                BuyButton.Active = false
            end
        end)
        
        -- Tombol
        VipButton.MouseButton1Click:Connect(function()
            if isOpen then closePanel() else openPanel() end
        end)
        
        CloseButton.MouseButton1Click:Connect(closePanel)
        
        BuyButton.MouseButton1Click:Connect(function()
            closePanel()
            RE_RequestVipPurchase:FireServer()
        end)
        
        -- Update dari server setelah beli
        RE_UpdateVipStatus.OnClientEvent:Connect(function(data)
            if data and data.hasVip then
                
                BuyButton.Active = false
            end
        end)
        
        -- Auto close jika TextButton lain di ListGui ditekan
        local function connectAutoClose(obj)
            if obj:IsA("TextButton") and obj ~= VipButton then
                obj.MouseButton1Click:Connect(function()
                    if isOpen then closePanel() end
                end)
            end
        end
        
        for _, desc in ipairs(ListGui:GetDescendants()) do
            connectAutoClose(desc)
        end
        ListGui.DescendantAdded:Connect(connectAutoClose)

