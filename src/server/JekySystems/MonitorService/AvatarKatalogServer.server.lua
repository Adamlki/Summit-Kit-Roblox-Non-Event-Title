-- ServerScriptService/AvatarChangerServer.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- ============================================
-- CREATE REMOTEEVENTS
-- ============================================
local ChangeAvatarEvent = Instance.new("RemoteEvent")
ChangeAvatarEvent.Name = "ChangeAvatarEvent"
ChangeAvatarEvent.Parent = ReplicatedStorage
 
local ResetAvatarEvent = Instance.new("RemoteEvent")
ResetAvatarEvent.Name = "ResetAvatarEvent"
ResetAvatarEvent.Parent = ReplicatedStorage
 
-- ============================================
-- PLAYER DATA STORAGE
-- ============================================
local playerData = {}
 
-- ============================================
-- TOOL HANDLER
-- Hanya unequip tool dari karakter ke Backpack sebelum ApplyDescription,
-- lalu equip kembali setelahnya. TIDAK clone/destroy agar script tidak restart.
-- ============================================
local function unequipTools(player)
    local equippedTool = nil
    
    if player.Character then
        for _, item in ipairs(player.Character:GetChildren()) do
            if item:IsA("Tool") then
                equippedTool = item
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    item.Parent = backpack -- pindah ke backpack, tidak dihapus
                end
                break -- karakter hanya bisa equip 1 tool sekaligus
            end
        end
    end
    
    return equippedTool -- kembalikan referensi tool aslinya (bukan clone)
end
 
local function reequipTool(player, tool)
    if not tool then return end
    
    task.wait(1.2)
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Pastikan tool masih ada di Backpack (belum dihapus sistem lain)
    local backpack = player:FindFirstChild("Backpack")
    if backpack and tool.Parent == backpack then
        humanoid:EquipTool(tool)
    end
end
 
-- ============================================
-- SAVE ORIGINAL AVATAR
-- ============================================
local function saveOriginalAvatar(player)
    if not playerData[player.UserId] then
        playerData[player.UserId] = {currentAvatarId = nil}
    end
end
 
-- ============================================
-- CHANGE AVATAR
-- ============================================
local function changeAvatar(player, targetUserId)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    saveOriginalAvatar(player)
    playerData[player.UserId].currentAvatarId = targetUserId
    
    -- Unequip tool yang sedang dipakai (tanpa destroy/clone)
    local equippedTool = unequipTools(player)
    
    -- Hapus aksesori/pakaian lama saja (bukan tools, bukan billboard)
    for _, item in ipairs(player.Character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat")
            or item:IsA("Shirt") or item:IsA("Pants")
            or item:IsA("ShirtGraphic") then
            item:Destroy()
        end
    end
    
    -- Apply deskripsi avatar baru
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetUserId)
    end)
    
    if success and description then
        humanoid:ApplyDescription(description)
        -- forceAttachTitle di TitleGiver otomatis restore billboard
        -- Equip kembali tool yang tadi di-unequip
        task.spawn(function()
            reequipTool(player, equippedTool)
        end)
    end
end
 
-- ============================================
-- RESET AVATAR
-- ============================================
local function resetAvatar(player)
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if not playerData[player.UserId] then
        saveOriginalAvatar(player)
    end
    
    playerData[player.UserId].currentAvatarId = nil
    
    -- Unequip tool yang sedang dipakai (tanpa destroy/clone)
    local equippedTool = unequipTools(player)
    
    local success, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(player.UserId)
    end)
    
    if success and description then
        humanoid:ApplyDescription(description)
        -- forceAttachTitle di TitleGiver otomatis restore billboard
        task.spawn(function()
            reequipTool(player, equippedTool)
        end)
    end
end
 
-- ============================================
-- PLAYER JOINED
-- ============================================
Players.PlayerAdded:Connect(function(player)
    saveOriginalAvatar(player)
    
    player.CharacterAdded:Connect(function(character)
        if playerData[player.UserId] and playerData[player.UserId].currentAvatarId then
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                task.wait(1)
                changeAvatar(player, playerData[player.UserId].currentAvatarId)
            end
        end
    end)
end)
 
-- ============================================
-- EVENT HANDLERS
-- ============================================
ChangeAvatarEvent.OnServerEvent:Connect(function(player, targetUserId)
    if typeof(targetUserId) == "number" then
        changeAvatar(player, targetUserId)
    end
end)
 
ResetAvatarEvent.OnServerEvent:Connect(function(player)
    resetAvatar(player)
end)
 
-- ============================================
-- CLEANUP
-- ============================================
Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
end)

