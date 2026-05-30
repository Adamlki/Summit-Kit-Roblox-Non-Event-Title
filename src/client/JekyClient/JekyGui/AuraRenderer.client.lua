-- StarterPlayerScripts > JekyClient > AuraRenderer.client.lua
-- Script ini bertugas merender partikel Aura secara lokal tanpa membebani server
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraPack = ReplicatedStorage:WaitForChild("AuraPack")

local function clearAura(character)
    for _, child in ipairs(character:GetDescendants()) do
        if child:GetAttribute("IsClientAura") then
            child:Destroy()
        end
    end
end

local function applyAura(character, auraName)
    clearAura(character)
    if not auraName or auraName == "" then return end
    
    local auraModel = AuraPack:FindFirstChild(auraName)
    if not auraModel then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local bodyParts = {
        "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"
    }
    
    local processedParts = {}
    
    -- Clone parts spesifik ke masing-masing anggota tubuh
    for _, partName in ipairs(bodyParts) do
        local auraPart = auraModel:FindFirstChild(partName)
        local characterPart = character:FindFirstChild(partName)
        
        if auraPart and characterPart and auraPart:IsA("BasePart") then
            local clone = auraPart:Clone()
            clone:SetAttribute("IsClientAura", true)
            clone.Transparency = 1 -- Sembunyikan fisik balok (hanya butuh partikel)
            clone.CanCollide = false
            clone.CanTouch = false
            clone.Massless = true
            clone.Anchored = false
            clone.CFrame = characterPart.CFrame
            clone.Parent = characterPart
            
            -- [OPTIMASI]: Batasi Rate Partikel Maksimal 30 agar ringan di HP / Client
            for _, fx in ipairs(clone:GetDescendants()) do
                if fx:IsA("ParticleEmitter") and fx.Rate > 30 then
                    fx.Rate = 30
                end
            end
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = clone
            weld.Part1 = characterPart
            weld.Parent = clone
            weld:SetAttribute("IsClientAura", true)
            
            processedParts[partName] = true
        end
    end
    
    -- Sisa parts yang tidak terikat ke nama anggota tubuh tertentu (gabungkan ke HumanoidRootPart)
    for _, child in ipairs(auraModel:GetChildren()) do
        if child:IsA("BasePart") and not processedParts[child.Name] then
            local clone = child:Clone()
            clone:SetAttribute("IsClientAura", true)
            
            -- Biarkan terlihat jika itu Mesh / Halo visual yang bukan HumanoidRootPart
            if clone.Name == "HumanoidRootPart" then
                clone.Transparency = 1
            end
            
            clone.CanCollide = false
            clone.CanTouch = false
            clone.Massless = true
            clone.Anchored = false
            clone.CFrame = humanoidRootPart.CFrame
            clone.Parent = humanoidRootPart
            
            for _, fx in ipairs(clone:GetDescendants()) do
                if fx:IsA("ParticleEmitter") and fx.Rate > 30 then
                    fx.Rate = 30
                end
            end
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = clone
            weld.Part1 = humanoidRootPart
            weld.Parent = clone
            weld:SetAttribute("IsClientAura", true)
        end
    end
end

local function setupCharacter(character)
    -- Pantau perubahan Attribute dari server
    character:GetAttributeChangedSignal("EquippedAura"):Connect(function()
        applyAura(character, character:GetAttribute("EquippedAura"))
    end)
    
    -- Render awal saat spawn
    task.wait(0.5)
    applyAura(character, character:GetAttribute("EquippedAura"))
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then
        setupCharacter(player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
