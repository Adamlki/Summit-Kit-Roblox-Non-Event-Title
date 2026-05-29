--// =========================================================
--// 1. AVATAR CONTEXT MENU SCRIPT (LocalScript)
--// Bertanggung jawab untuk menambahkan opsi ke menu konteks.
--// =========================================================
 
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
 
-- Tunggu karakter dimuat
repeat task.wait(1) until player.Character and player.CharacterAppearanceLoaded
 
-- Fungsi untuk menunggu CoreScript siap
local function waitForCoreScript()
    local success = false
    local attempts = 0
    local maxAttempts = 30 
    
    repeat
    attempts += 1
    success = pcall(function()
        StarterGui:SetCore("AvatarContextMenuEnabled", true)
    end)
    if not success then task.wait(1) end
    until success or attempts >= maxAttempts
    
    return success
end
 
-- Hanya lanjutkan jika CoreScript siap
if not waitForCoreScript() then
    warn("[ContextMenu] Avatar Context Menu CoreScript gagal dimuat.")
    return
end
 
--- === KONFIGURASI TEMA & PENGATURAN ===
StarterGui:SetCore("RemoveAvatarContextMenuOption", Enum.AvatarContextMenuOption.Emote)
StarterGui:SetCore("AvatarContextMenuTheme", {
BackgroundImage = "",
BackgroundTransparency = 0.3,
BackgroundColor = Color3.fromRGB(40, 37, 37),
NameTagColor = Color3.fromRGB(40, 37, 37),
NameUnderlineColor = Color3.fromRGB(40, 37, 37),
ButtonFrameColor = Color3.fromRGB(40, 37, 37),
ButtonFrameTransparency = 0.3,
ButtonUnderlineColor = Color3.fromRGB(40, 37, 37),
Font = Enum.Font.Jura
})
 
--- === BINDABLE EVENTS & REMOTES ===
-- Bindable Events dipicu oleh menu konteks
local syncBind = Instance.new("BindableEvent")
local unsyncBind = Instance.new("BindableEvent")
local carryBind = Instance.new("BindableEvent")
local stopCarryBind = Instance.new("BindableEvent")
 
-- RemoteEvents untuk komunikasi Server
local syncingFolder
local carryRemote
 
local success, result = pcall(function()
    syncingFolder = ReplicatedStorage:WaitForChild("Syncing", 5)
    carryRemote = ReplicatedStorage:WaitForChild("CarryRemote", 5)
end)
 
if not success or not carryRemote or not syncingFolder then
    warn("[ContextMenu] Gagal menemukan RemoteEvents (Syncing/CarryRemote). Fitur akan dinonaktifkan.")
    return
end
 
--- === FUNGSI LOGIKA ===
 
local function sync(targetPlayer)
    if not targetPlayer or not targetPlayer:IsA("Player") then return end
    local danceName = "Current Dance" -- Ganti sesuai logika mendapatkan nama tarian
    syncingFolder:FindFirstChild("Sync"):FireServer(targetPlayer, danceName)
    StarterGui:SetCore("SendNotification", {
    Title = "Dance Sync Request",
    Text = "Mencoba Sync Dance dengan " .. targetPlayer.DisplayName,
    Duration = 3
    })
end
 
local function unsync()
    syncingFolder:FindFirstChild("UnSync"):FireServer()
    StarterGui:SetCore("SendNotification", {
    Title = "Dance Unsynced",
    Text = "Sinkronisasi Dance telah dihentikan.",
    Duration = 2
    })
end
 
local function carry(targetPlayer)
    -- TargetPlayer otomatis disediakan oleh CoreScript saat opsi diklik pada pemain lain
    if not targetPlayer or not targetPlayer:IsA("Player") then
        warn("[ContextMenu] Carry: TargetPlayer tidak valid.")
        return
    end
    
    -- Mengirim permintaan carry. Server akan menerima ("Request", {targetId = ...})
    carryRemote:FireServer("Request", { targetId = targetPlayer.UserId })
    
    StarterGui:SetCore("SendNotification", {
    Title = "Permintaan Carry Terkirim",
    Text = "Anda mengirim permintaan carry ke **" .. targetPlayer.DisplayName .. "**",
    Duration = 3
    })
end
 
local function stopCarry()
    -- Menghentikan carry. Server akan memproses aksi "Stop" tanpa target ID
    carryRemote:FireServer("Stop")
    
    StarterGui:SetCore("SendNotification", {
    Title = "Carry Dihentikan",
    Text = "Anda telah menghentikan aksi carrying.",
    Duration = 2
    })
end
 
--- === KONEKSI EVENT ===
syncBind.Event:Connect(sync)
unsyncBind.Event:Connect(unsync)
carryBind.Event:Connect(carry)
stopCarryBind.Event:Connect(stopCarry)
 
--- === TAMBAHKAN PILIHAN MENU KE AVATAR CONTEXT MENU ===
StarterGui:SetCore("AddAvatarContextMenuOption", {"Carry", carryBind})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Stop Carry", stopCarryBind})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Sync Dance", syncBind})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Unsync Dance", unsyncBind})
 

