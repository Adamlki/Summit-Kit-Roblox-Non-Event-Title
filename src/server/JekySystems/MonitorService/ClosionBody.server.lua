-- Letakkan di ServerScriptService

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

-- Buat collision group untuk players
local function setupCollisionGroups()
    pcall(function()
        PhysicsService:RegisterCollisionGroup("Players")
    end)
    PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
end

-- Fungsi untuk disable collision pada character
local function disableCollision(character)
    -- Tunggu character benar-benar loaded
    if not character then return end
    
    character:WaitForChild("HumanoidRootPart", 5)
    
    -- Set semua body parts ke collision group "Players"
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = "Players"
            -- Backup method: set CanCollide false untuk humanoid parts
            if descendant.Name ~= "HumanoidRootPart" and descendant.Parent == character then
                descendant.CanCollide = false
            end
        end
    end
    
    -- Monitor part baru yang ditambahkan (seperti accessories)
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            descendant.CollisionGroup = "Players"
        end
    end)
end

-- Setup collision groups
setupCollisionGroups()

-- Handle player yang sudah ada di game
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        task.wait(0.1) -- Small delay untuk memastikan character loaded
        disableCollision(player.Character)
    end
    
    -- Handle ketika character respawn
    player.CharacterAdded:Connect(function(character)
        task.wait(0.1)
        disableCollision(character)
    end)
end

-- Handle player baru yang join
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.1)
        disableCollision(character)
    end)
end)

