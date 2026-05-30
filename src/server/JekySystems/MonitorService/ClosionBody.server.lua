-- Letakkan di ServerScriptService

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local COLLISION_GROUP = "Players"

-- Setup Collision Group: Set agar "Players" tidak bisa bertabrakan dengan "Players"
local function setupCollisionGroups()
    local success, err = pcall(function()
        PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
    end)
    PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)
end

-- Fungsi untuk meng-assign part ke Collision Group
local function assignCollisionGroup(character)
    if not character then return end
    
    local function setGroup(part)
        if part:IsA("BasePart") then
            part.CollisionGroup = COLLISION_GROUP
        end
    end

    -- Assign ke semua part yang sudah ada
    for _, part in ipairs(character:GetDescendants()) do
        setGroup(part)
    end

    -- Monitor jika ada part baru yang ditambahkan (misal: aksesoris, senjata)
    character.DescendantAdded:Connect(function(descendant)
        -- task.wait() dihapus agar instan dan tidak membuang memori
        setGroup(descendant)
    end)
end

-- Inisialisasi
setupCollisionGroups()

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(assignCollisionGroup)
    -- Jika character sudah ada saat script berjalan
    if player.Character then
        assignCollisionGroup(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

