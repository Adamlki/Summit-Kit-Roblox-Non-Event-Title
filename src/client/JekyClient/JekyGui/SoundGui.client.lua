local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Setup Suara (Ganti ID dengan ID Audio Roblox yang kamu inginkan)
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://117649901456711" 
hoverSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://103282937573040"
clickSound.Parent = SoundService

-- Fungsi untuk memberikan efek suara pada sebuah tombol
local function applySound(element)
	if element:IsA("TextButton") or element:IsA("ImageButton") then
		element.MouseEnter:Connect(function()
			hoverSound:Play()
		end)
		
		element.MouseButton1Click:Connect(function()
			clickSound:Play()
		end)
	end
end

-- 1. Scan semua tombol yang sudah ada saat player baru masuk
for _, descendant in ipairs(playerGui:GetDescendants()) do
	applySound(descendant)
end

-- 2. Pasang pendeteksi otomatis jika nanti ada UI / Menu baru yang di-load
playerGui.DescendantAdded:Connect(applySound)
