local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

local VandraVerified = require(ServerStorage.VandraModules.VandraVerified)
local VandraTitle    = require(ServerStorage.VandraModules.VandraTitle)
local VandraConfig   = require(ServerStorage.VandraModules.VandraConfig)

local VandraEvents = ReplicatedStorage:FindFirstChild("VandraEvents")
if not VandraEvents then
    VandraEvents = Instance.new("Folder")
    VandraEvents.Name = "VandraEvents"
    VandraEvents.Parent = ReplicatedStorage
end

local function getOrCreateRE(eventName)
    local ev = VandraEvents:FindFirstChild(eventName)
    if not ev then
        ev = Instance.new("RemoteEvent")
        ev.Name = eventName
        ev.Parent = VandraEvents
    end
    return ev
end

local VS_UpdateVerifiedUI = getOrCreateRE("VS_UpdateVerifiedUI")

local function checkAndUpdatePlayer(player)
    if not player or not player.Parent then return false end
    local roleTitle  = VandraTitle.GetRoleTitle(player)
    local isVerified = VandraVerified:CheckPlayer(player, roleTitle)
    player:SetAttribute("IsVerified", isVerified)
    VS_UpdateVerifiedUI:FireClient(player, isVerified)
    return isVerified
end

local function processVerifiedCommand(player, command, args)
    if not player or not player.Parent then return false, "Invalid player" end
    local roleTitle = VandraTitle.GetRoleTitle(player)
    
    if command == "_AddVerified" then
        if not VandraConfig:HasCommandAccess(roleTitle, "_AddVerified") then
            return false, "No access"
        end
        if not args[1] or args[1] == "" then
            return false, "Usage: _AddVerified <username>"
        end
        local targetUsername = tostring(args[1])
        -- FIX: PS.Verified.Add returns boolean only; build message here
        local success = VandraVerified:AddDynamicVerified(targetUsername, tostring(player.Name), "Added via command")
        local msg = success and ("Added: " .. targetUsername) or ("Already exists: " .. targetUsername)
        if success then
            for _, p in ipairs(Players:GetPlayers()) do
                if string.lower(p.Name) == string.lower(targetUsername) then
                    checkAndUpdatePlayer(p)
                    break
                end
            end
        end
        return success, msg
        
    elseif command == "_DVerified" then
        if not VandraConfig:HasCommandAccess(roleTitle, "_DVerified") then
            return false, "No access"
        end
        if not args[1] or args[1] == "" then
            return false, "Usage: _DVerified <username>"
        end
        local targetUsername = tostring(args[1])
        local success = VandraVerified:RemoveDynamicVerified(targetUsername)
        local msg = success and ("Removed: " .. targetUsername) or ("Not found: " .. targetUsername)
        if success then
            for _, p in ipairs(Players:GetPlayers()) do
                if string.lower(p.Name) == string.lower(targetUsername) then
                    checkAndUpdatePlayer(p)
                    break
                end
            end
        end
        return success, msg
    end
    
    return false, "Unknown command"
end

local function onPlayerChatted(player, message)
    if type(message) ~= "string" or string.sub(message, 1, 1) ~= "_" then return end
    local parts = {}
    for part in string.gmatch(message, "%S+") do
        table.insert(parts, part)
    end
    if #parts < 1 then return end
    local command = parts[1]
    table.remove(parts, 1)
    
    if command == "_AddVerified" or command == "_DVerified" then
        local ok, msg = processVerifiedCommand(player, command, parts)
        -- FIX: tostring guard ensures no nil concatenation
        local attr = (ok and "✓ " or "✗ ") .. tostring(msg or "")
        player:SetAttribute("CmdSuccess", attr)
        task.delay(5, function()
            if player and player.Parent then
                player:SetAttribute("CmdSuccess", nil)
            end
        end)
    end
end

local function initialize()
    VandraVerified:Initialize()
    
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            task.wait(1)
            checkAndUpdatePlayer(player)
        end)
        player.Chatted:Connect(function(msg) onPlayerChatted(player, msg) end)
            player:GetAttributeChangedSignal("IsVerified"):Connect(function()
                local isVerified = player:GetAttribute("IsVerified") or false
                VS_UpdateVerifiedUI:FireClient(player, isVerified)
            end)
        end
        
        Players.PlayerAdded:Connect(function(player)
            task.spawn(function()
                task.wait(2)
                checkAndUpdatePlayer(player)
            end)
            player.Chatted:Connect(function(msg) onPlayerChatted(player, msg) end)
                player:GetAttributeChangedSignal("IsVerified"):Connect(function()
                    local isVerified = player:GetAttribute("IsVerified") or false
                    VS_UpdateVerifiedUI:FireClient(player, isVerified)
                end)
            end)
        end
        
        task.spawn(initialize)

