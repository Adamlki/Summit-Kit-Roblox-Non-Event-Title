-- ServerScriptService/VandraSystems/OverheadTitleManager
local Players          = game:GetService("Players")
local ServerStorage    = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local VandraTitle = require(ServerStorage.VandraModules:WaitForChild("VandraTitle"))
 
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
 
local OT_TitleUpdate      = getOrCreateRE("OT_TitleUpdate")
local RoleAPI_GetAllRoles = getOrCreateRE("RoleAPI_GetAllRoles")
local RoleAPI_AddRole     = getOrCreateRE("RoleAPI_AddRole")
local RoleAPI_RemoveRole  = getOrCreateRE("RoleAPI_RemoveRole")
 
local PlayerTitleCache = {}
local updateThrottle   = {}
 
local ADMIN_USER_IDS  = {}
local ADMIN_USERNAMES = { "BukanYgDiaPilih", "kenn_justforu" }
 
local function isAdmin(player)
    if not player then return false end
    for _, id in ipairs(ADMIN_USER_IDS) do
        if player.UserId == id then return true end
    end
    for _, name in ipairs(ADMIN_USERNAMES) do
        if player.Name == name then return true end
    end
    return false
end
 
local function getBestSummit(player)
    if not player or not player.Parent then return 0 end
    local best = 0
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local s = ls:FindFirstChild("Summit")
        if s and typeof(s.Value) == "number" then best = s.Value end
    end
    return best
end
 
local function updatePlayerTitle(player, total)
    if not player or not player.Parent then return end
    total = tonumber(total) or 0
    local userId = player.UserId
    local now = tick()
    if updateThrottle[userId] and (now - updateThrottle[userId]) < 2 then return end
    updateThrottle[userId] = now
    
    local roleTitle, summitTitle, totalText = VandraTitle.BuildTitles(player, total)
    local roleColor        = VandraTitle.GetRoleColor(roleTitle)
    local roleUsesGradient = VandraTitle.GetRoleUsesGradient(roleTitle)
    local useSpecialSummitGradient = VandraTitle.ShouldUseSpecialSummitGradient(total)
    local specialGradientConfig    = VandraTitle.GetSpecialSummitGradient(total)
    
    pcall(function()
        player:SetAttribute("RoleTitle",                roleTitle or "")
        player:SetAttribute("RoleDisplayText",          VandraTitle.GetRoleDisplayText(roleTitle))
        player:SetAttribute("RoleUsesGradient",         roleUsesGradient)
        player:SetAttribute("SummitTitle",              summitTitle or "NEWBIE EXPLORER")
        player:SetAttribute("TotalSummitText",          totalText or "SUMMIT: 0")
        player:SetAttribute("OverheadNameText",         player.DisplayName or player.Name)
        player:SetAttribute("UseSpecialSummitGradient", useSpecialSummitGradient or false)
        if roleColor then
            player:SetAttribute("RoleColor", roleColor)
        end
    end)
    
    local summitColor = VandraTitle.GetSummitColor(summitTitle)
    if summitColor then
        pcall(function() player:SetAttribute("SummitColor", summitColor) end)
        end
            
            pcall(function()
                OT_TitleUpdate:FireClient(player, {
                RoleTitle              = roleTitle or "",
                RoleDisplayText        = VandraTitle.GetRoleDisplayText(roleTitle),
                RoleColor              = roleColor,
                RoleUsesGradient       = roleUsesGradient,
                SummitTitle            = summitTitle or "NEWBIE EXPLORER",
                TotalSummitText        = totalText or "SUMMIT: 0",
                SummitColor            = summitColor,
                UseSpecialSummitGradient = useSpecialSummitGradient or false,
                SpecialGradientConfig  = specialGradientConfig,
                OverheadName           = player.DisplayName or player.Name,
                })
            end)
            
            PlayerTitleCache[userId] = {
            RoleTitle   = roleTitle,
            SummitTitle = summitTitle,
            TotalSummit = total,
            LastUpdate  = os.clock()
            }
        end
        
        local function hideDefaultNameplate(character)
            if not character or not character.Parent then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then humanoid = character:WaitForChild("Humanoid", 10) end
            if not humanoid then return end
            pcall(function() humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
                pcall(function() humanoid.HealthDisplayType   = Enum.HumanoidHealthDisplayType.AlwaysOff end)
                    pcall(function() humanoid.NameDisplayDistance = 0 end)
                    end
                        
                        -- Command: _AddRole <username> <roleName>
                        local function handleAddRoleCommand(player, args)
                            if not isAdmin(player) then return end
                            if not args or #args < 2 then return end
                            local username = args[1]
                            local roleName = args[2]
                            local success  = VandraTitle:AddDynamicRole(username, roleName)
                            if success then
                                task.wait(0.3)
                                local targetPlayer = Players:FindFirstChild(username)
                                if targetPlayer and targetPlayer.Parent then
                                    updateThrottle[targetPlayer.UserId] = nil
                                    updatePlayerTitle(targetPlayer, getBestSummit(targetPlayer))
                                end
                            end
                        end
                        
                        -- Command: _RemoveRole <username>
                        local function handleRemoveRoleCommand(player, args)
                            if not isAdmin(player) then return end
                            if not args or #args < 1 then return end
                            local username = args[1]
                            local success  = VandraTitle:RemoveDynamicRole(username)
                            if success then
                                task.wait(0.3)
                                local targetPlayer = Players:FindFirstChild(username)
                                if targetPlayer and targetPlayer.Parent then
                                    updateThrottle[targetPlayer.UserId] = nil
                                    updatePlayerTitle(targetPlayer, getBestSummit(targetPlayer))
                                end
                            end
                        end
                        
                        local function setupPlayer(player)
                            if not player or not player.Parent then return end
                            pcall(function()
                                player:SetAttribute("RoleTitle",                "")
                                player:SetAttribute("RoleDisplayText",          "")
                                player:SetAttribute("RoleUsesGradient",         false)
                                player:SetAttribute("SummitTitle",              "NEWBIE EXPLORER")
                                player:SetAttribute("TotalSummitText",          "SUMMIT: 0")
                                player:SetAttribute("SummitColor",              Color3.fromRGB(135, 206, 250))
                                player:SetAttribute("OverheadNameText",         player.DisplayName or player.Name)
                                player:SetAttribute("UseSpecialSummitGradient", false)
                            end)
                            
                            pcall(function()
                                player:GetPropertyChangedSignal("DisplayName"):Connect(function()
                                    if player and player.Parent then
                                        player:SetAttribute("OverheadNameText", player.DisplayName or player.Name)
                                        updatePlayerTitle(player, getBestSummit(player))
                                    end
                                end)
                            end)
                            
                            local function ensureLeaderstatsListener()
                                local leaderstats = player:FindFirstChild("leaderstats")
                                if leaderstats then
                                    local summit = leaderstats:FindFirstChild("Summit")
                                    if summit then
                                        summit.Changed:Connect(function()
                                            if player and player.Parent then
                                                updatePlayerTitle(player, tonumber(summit.Value) or 0)
                                            end
                                        end)
                                        return true
                                    end
                                end
                                return false
                            end
                            
                            task.spawn(function()
                                local listenerSetup = false
                                for attempt = 1, 15 do
                                    if not player or not player.Parent then break end
                                    if ensureLeaderstatsListener() then
                                        listenerSetup = true
                                        break
                                    end
                                    task.wait(0.2)
                                end
                                
                                if not listenerSetup then return end
                                
                                player:GetAttributeChangedSignal("_SummitLoaded"):Connect(function()
                                    if player and player.Parent then
                                        updateThrottle[player.UserId] = nil
                                        task.wait(0.1)
                                        updatePlayerTitle(player, getBestSummit(player))
                                    end
                                end)
                                
                                task.wait(1.5)
                                updateThrottle[player.UserId] = nil
                                
                                for retry = 1, 10 do
                                    if not player or not player.Parent then break end
                                    local summitLoaded = player:GetAttribute("_SummitLoaded")
                                    if summitLoaded then
                                        updateThrottle[player.UserId] = nil
                                        updatePlayerTitle(player, getBestSummit(player))
                                        break
                                    end
                                    local currentSummit = getBestSummit(player)
                                    if retry == 1 or currentSummit > 0 then
                                        updateThrottle[player.UserId] = nil
                                        updatePlayerTitle(player, currentSummit)
                                    end
                                    if currentSummit > 0 then break end
                                    task.wait(2.5)
                                end
                            end)
                            
                            player.CharacterAdded:Connect(function(char)
                                if not char or not char.Parent then return end
                                hideDefaultNameplate(char)
                                task.wait(0.5)
                                if player and player.Parent then
                                    updatePlayerTitle(player, getBestSummit(player))
                                end
                            end)
                            
                            if player.Character then hideDefaultNameplate(player.Character) end
                            
                            pcall(function()
                                player:GetAttributeChangedSignal("DynamicRole"):Connect(function()
                                    if player and player.Parent then
                                        task.wait(0.1)
                                        updateThrottle[player.UserId] = nil
                                        updatePlayerTitle(player, getBestSummit(player))
                                    end
                                end)
                                player:GetAttributeChangedSignal("RoleUsesGradient"):Connect(function()
                                    if player and player.Parent then
                                        task.wait(0.1)
                                        updateThrottle[player.UserId] = nil
                                        updatePlayerTitle(player, getBestSummit(player))
                                    end
                                end)
                            end)
                        end
                        
                        local function cleanupPlayer(player)
                            if not player then return end
                            PlayerTitleCache[player.UserId] = nil
                            updateThrottle[player.UserId]   = nil
                        end
                        
                        Players.PlayerAdded:Connect(function(player)
                            if not player then return end
                            player.Chatted:Connect(function(message)
                                if not message or type(message) ~= "string" then return end
                                local args = string.split(message, " ")
                                if not args or #args == 0 then return end
                                local command = args[1]
                                if command == "_AddRole" then
                                    table.remove(args, 1)
                                    handleAddRoleCommand(player, args)
                                elseif command == "_RemoveRole" then
                                    table.remove(args, 1)
                                    handleRemoveRoleCommand(player, args)
                                end
                            end)
                        end)
                        
                        RoleAPI_GetAllRoles.OnServerEvent:Connect(function(player)
                            if not player or not isAdmin(player) then return end
                            local playerList = VandraTitle.API.GetAllPlayers()
                            if playerList then
                                pcall(function() RoleAPI_GetAllRoles:FireClient(player, playerList) end)
                                end
                                end)
                                    
                                    RoleAPI_AddRole.OnServerEvent:Connect(function(player, username, roleName)
                                        if not player or not isAdmin(player) then return end
                                        if not username or not roleName then return end
                                        local success, message = VandraTitle.API.AddRole(username, roleName)
                                        if success then
                                            task.wait(0.3)
                                            local targetPlayer = Players:FindFirstChild(username)
                                            if targetPlayer and targetPlayer.Parent then
                                                updateThrottle[targetPlayer.UserId] = nil
                                                updatePlayerTitle(targetPlayer, getBestSummit(targetPlayer))
                                            end
                                        end
                                        pcall(function() RoleAPI_AddRole:FireClient(player, success, message) end)
                                        end)
                                            
                                            RoleAPI_RemoveRole.OnServerEvent:Connect(function(player, username)
                                                if not player or not isAdmin(player) then return end
                                                if not username then return end
                                                local success = VandraTitle.API.RemoveRole(username)
                                                if success then
                                                    task.wait(0.3)
                                                    local targetPlayer = Players:FindFirstChild(username)
                                                    if targetPlayer and targetPlayer.Parent then
                                                        updateThrottle[targetPlayer.UserId] = nil
                                                        updatePlayerTitle(targetPlayer, getBestSummit(targetPlayer))
                                                    end
                                                end
                                                pcall(function() RoleAPI_RemoveRole:FireClient(player, success) end)
                                                end)
                                                    
                                                    for _, player in ipairs(Players:GetPlayers()) do
                                                        if player and player.Parent then task.spawn(setupPlayer, player) end
                                                    end
                                                    
                                                    Players.PlayerAdded:Connect(function(player)
                                                        if player and player.Parent then setupPlayer(player) end
                                                    end)
                                                    
                                                    Players.PlayerRemoving:Connect(function(player)
                                                        if player then cleanupPlayer(player) end
                                                    end)

