-- LocalScript
-- Hide default Roblox name tag (client-side)

local Players = game:GetService("Players")

local function hideNameTag(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(hideNameTag)
    
    -- Jika character sudah ada
    if player.Character then
        hideNameTag(player.Character)
    end
end

-- Apply ke semua player
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

