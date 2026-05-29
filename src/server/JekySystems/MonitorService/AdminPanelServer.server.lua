-- ============================================================
-- ADMIN PANEL SERVER HANDLER
-- Lokasi: ServerScriptService > AdminPanelServer (Script)
-- Semua validasi role & akses dilakukan di sini (anti-exploit)
-- ============================================================
 
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local MessagingService  = game:GetService("MessagingService")
 
-- ============================================================
-- LOAD MODULES
-- ============================================================
local VandraModules = ServerStorage:WaitForChild("VandraModules")
 
local VandraTitle    = require(VandraModules:WaitForChild("VandraTitle"))
local VandraConfig   = require(VandraModules:WaitForChild("VandraConfig"))
local VandraVerified = require(VandraModules:WaitForChild("VandraVerified"))
local VandraVipData  = require(VandraModules:WaitForChild("VandraVipData"))
local VandraDataStore= require(VandraModules:WaitForChild("VandraDataStore"))
 
-- ============================================================
-- REMOTES SETUP
-- ============================================================
local VandraEvents = ReplicatedStorage:FindFirstChild("VandraEvents")
if not VandraEvents then
    VandraEvents        = Instance.new("Folder")
    VandraEvents.Name   = "VandraEvents"
    VandraEvents.Parent = ReplicatedStorage
end
 
local function getOrCreate(className, name, parent)
    local existing = parent:FindFirstChild(name)
    if existing then return existing end
    local obj      = Instance.new(className)
    obj.Name       = name
    obj.Parent     = parent
    return obj
end
 
local AdminPanel_Command = getOrCreate("RemoteEvent", "AdminPanel_Command", VandraEvents)
local AdminPanel_Result  = getOrCreate("RemoteEvent", "AdminPanel_Result",  VandraEvents)
 
local SummitChatEvent = ReplicatedStorage:FindFirstChild("SummitChatEvent")
if not SummitChatEvent then
    SummitChatEvent        = Instance.new("RemoteEvent")
    SummitChatEvent.Name   = "SummitChatEvent"
    SummitChatEvent.Parent = ReplicatedStorage
end
 
-- ============================================================
-- ROLES THAT CAN USE PANEL (server authority)
-- Streamer & Community cannot access panel at all
-- ============================================================
local PANEL_ALLOWED = { Owner=true, Developer=true, HeadAdmin=true, Admin=true, Moderator=true }
 
local function canUsePanel(player)
    if not player or not player.Parent then return false end
    local role = VandraTitle.GetRoleTitle(player)
    if not role then return false end
    return PANEL_ALLOWED[role] == true
end
 
local function hasAccess(player, cmd)
    local role = VandraTitle.GetRoleTitle(player)
    if not role then return false end
    return VandraConfig:HasCommandAccess(role, cmd)
end
 
-- ============================================================
-- HELPER: find online player by name (case-insensitive)
-- ============================================================
local function findPlayer(name)
    if not name or name == "" then return nil end
    local lower = string.lower(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name) == lower or string.lower(p.DisplayName) == lower then
            return p
        end
    end
    return nil
end
 
-- ============================================================
-- HELPER: resolve checkpoint location and teleport character
-- ============================================================
local INTERNAL_TO_MODEL = { Summit = "SUMMIT", ApexSummit = "BIGSUMMIT" }
 
local function getCheckpointSpawn(checkpointId)
    local vandra = workspace:FindFirstChild("AllPartSummitkitVandra")
    if not vandra then return nil end
    local cpFolder = vandra:FindFirstChild("Checkpoint")
    if not cpFolder then return nil end
    
    local modelName = INTERNAL_TO_MODEL[checkpointId] or checkpointId
    local model     = cpFolder:FindFirstChild(modelName)
    if model then
        local sp = model:FindFirstChildOfClass("SpawnLocation")
        if sp then return sp end
        local dest = model:FindFirstChild("Destinasi")
        if dest then return dest end
    end
    -- fallback: BC
    if checkpointId ~= "BC" then
        return getCheckpointSpawn("BC")
    end
    return nil
end
 
local function teleportCharacterTo(character, checkpointId)
    if not character or not character.Parent then return false end
    local target = getCheckpointSpawn(checkpointId)
    if not target then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local range  = VandraConfig.SPAWN_RANDOM_RANGE or 4
    local yOff   = VandraConfig.SPAWN_OFFSET_Y     or 5
    local spawnPos = target.Position + Vector3.new(
    math.random(-range, range), yOff, math.random(-range, range))
    
    local ok = pcall(function()
        hrp.CFrame                  = CFrame.new(spawnPos)
        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end)
    return ok
end
 
-- ============================================================
-- COMMAND HANDLER
-- ============================================================
local CHAT_TOPIC = "SummitGlobalChat"
 
AdminPanel_Command.OnServerEvent:Connect(function(sender, cmdName, args)
    if not sender or not sender.Parent then return end
    if not canUsePanel(sender) then return end
    
    args = args or {}
    
    -- helper to reply
    local function reply(success, message)
        AdminPanel_Result:FireClient(sender, success, tostring(message or ""))
    end
    
    -- ============================================================
    -- _Add: add summit to target
    -- ============================================================
    if cmdName == "_Add" then
        if not hasAccess(sender, "_Add") then reply(false, "No access: _Add"); return end
        local targetName = tostring(args[1] or "")
        local amount     = tonumber(args[2])
        if targetName == "" then reply(false, "No target specified."); return end
        if not amount        then reply(false, "Invalid amount."); return end
        
        local tp = findPlayer(targetName)
        if tp then
            local ls     = tp:FindFirstChild("leaderstats")
            local sVal   = ls and ls:FindFirstChild("Summit")
            if sVal then
                sVal.Value = sVal.Value + amount
                task.spawn(function()
                    VandraDataStore:ForceUpdateSummit(tp.UserId, sVal.Value)
                end)
                reply(true, "Added " .. amount .. " Summit to " .. tp.Name)
            else
                reply(false, "Could not find leaderstats for " .. tp.Name)
            end
        else
            task.spawn(function()
                local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                    if ok and uid then
                        local lok, profile = pcall(function() return VandraDataStore:LoadProfile(uid, true) end)
                            if lok and profile then
                                local newTotal = (profile.SummitData and profile.SummitData.TotalSummit or 0) + amount
                                pcall(function() VandraDataStore:ForceUpdateSummit(uid, newTotal) end)
                                    reply(true, "Added " .. amount .. " to offline player " .. targetName)
                                else
                                    reply(false, "Could not load profile for " .. targetName)
                                end
                            else
                                reply(false, "Player not found: " .. targetName)
                            end
                        end)
                    end
                    return
                end
                
                -- ============================================================
                -- _R: reset summit for target
                -- ============================================================
                if cmdName == "_R" then
                    if not hasAccess(sender, "_R") then reply(false, "No access: _R"); return end
                    local targetName = tostring(args[1] or "")
                    if targetName == "" then reply(false, "No target specified."); return end
                    
                    local tp = findPlayer(targetName)
                    if tp then
                        local ls   = tp:FindFirstChild("leaderstats")
                        local sVal = ls and ls:FindFirstChild("Summit")
                        if sVal then
                            sVal.Value = 0
                            task.spawn(function()
                                VandraDataStore:ForceUpdateSummit(tp.UserId, 0)
                            end)
                            reply(true, "Reset Summit for " .. tp.Name)
                        else
                            reply(false, "Could not find leaderstats for " .. tp.Name)
                        end
                    else
                        task.spawn(function()
                            local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                                if ok and uid then
                                    pcall(function() VandraDataStore:ForceUpdateSummit(uid, 0) end)
                                        reply(true, "Reset offline player " .. targetName)
                                    else
                                        reply(false, "Player not found: " .. targetName)
                                    end
                                end)
                            end
                            return
                        end
                        
                        -- ============================================================
                        -- _Gift: give VIP
                        -- ============================================================
                        if cmdName == "_Gift" then
                            if not hasAccess(sender, "_Gift") then reply(false, "No access: _Gift"); return end
                            local targetName = tostring(args[1] or "")
                            if targetName == "" then reply(false, "No target specified."); return end
                            
                            local tp = findPlayer(targetName)
                            if tp then
                                if _G.VipSystem then
                                    _G.VipSystem.GiftVip(tp)
                                    reply(true, "VIP granted to " .. tp.Name)
                                else
                                    reply(false, "VipSystem not loaded.")
                                end
                            else
                                reply(false, "Player must be online to receive VIP.")
                            end
                            return
                        end
                        
                        -- ============================================================
                        -- _DVip: remove VIP
                        -- ============================================================
                        if cmdName == "_DVip" then
                            if not hasAccess(sender, "_DVip") then reply(false, "No access: _DVip"); return end
                            local targetName = tostring(args[1] or "")
                            if targetName == "" then reply(false, "No target specified."); return end
                            
                            local tp = findPlayer(targetName)
                            if tp then
                                if _G.VipSystem then
                                    _G.VipSystem.RemoveVip(tp)
                                    reply(true, "VIP removed from " .. tp.Name)
                                else
                                    reply(false, "VipSystem not loaded.")
                                end
                            else
                                reply(false, "Player must be online to remove VIP.")
                            end
                            return
                        end
                        
                        -- ============================================================
                        -- _AddVerified
                        -- ============================================================
                        if cmdName == "_AddVerified" then
                            if not hasAccess(sender, "_AddVerified") then reply(false, "No access: _AddVerified"); return end
                            local targetName = tostring(args[1] or "")
                            if targetName == "" then reply(false, "No target specified."); return end
                            
                            local success = VandraVerified:AddDynamicVerified(targetName, sender.Name, "Added via Admin Panel")
                            if success then
                                local tp = findPlayer(targetName)
                                if tp then tp:SetAttribute("IsVerified", true) end
                                reply(true, "Verified added: " .. targetName)
                            else
                                reply(false, "Already verified or failed: " .. targetName)
                            end
                            return
                        end
                        
                        -- ============================================================
                        -- _DVerified
                        -- ============================================================
                        if cmdName == "_DVerified" then
                            if not hasAccess(sender, "_DVerified") then reply(false, "No access: _DVerified"); return end
                            local targetName = tostring(args[1] or "")
                            if targetName == "" then reply(false, "No target specified."); return end
                            
                            local success = VandraVerified:RemoveDynamicVerified(targetName)
                            if success then
                                local tp = findPlayer(targetName)
                                if tp then tp:SetAttribute("IsVerified", false) end
                                reply(true, "Verified removed: " .. targetName)
                            else
                                reply(false, "Not found or failed: " .. targetName)
                            end
                            return
                        end
                        
                        -- ============================================================
                        -- _AddRole
                        -- ============================================================
                        if cmdName == "_AddRole" then
                            if not hasAccess(sender, "_AddRole") then reply(false, "No access: _AddRole"); return end
                            local targetName = tostring(args[1] or "")
                            local roleName   = tostring(args[2] or "")
                            if targetName == "" or roleName == "" then reply(false, "Target and role required."); return end
                            
                            local ok, msg = VandraTitle:AddDynamicRole(targetName, roleName)
                            reply(ok, msg)
                            return
                        end
                        
                        -- ============================================================
                        -- _RemoveRole
                        -- ============================================================
                        if cmdName == "_RemoveRole" then
                            if not hasAccess(sender, "_RemoveRole") then reply(false, "No access: _RemoveRole"); return end
                            local targetName = tostring(args[1] or "")
                            if targetName == "" then reply(false, "No target specified."); return end
                            
                            local ok, msg = VandraTitle:RemoveDynamicRole(targetName)
                            reply(ok, msg)
                            return
                        end
                        
                        -- ============================================================
                        -- _RSpeed: reset speedrun
                        -- ============================================================
                        if cmdName == "_RSpeed" then
                            if not hasAccess(sender, "_RSpeed") then reply(false, "No access: _RSpeed"); return end
                            local targetName = tostring(args[1] or "")
                            if targetName == "" then reply(false, "No target specified."); return end
                            
                            local VandraSpeedRunData = require(VandraModules:WaitForChild("VandraSpeedRunData"))
                            
                            local tp = findPlayer(targetName)
                            if tp then
                                VandraSpeedRunData:ResetBestTime(tp.UserId)
                                local ls = tp:FindFirstChild("leaderstats")
                                if ls then
                                    local btv = ls:FindFirstChild("BestTime")
                                    if btv and btv:IsA("StringValue") then btv.Value = "N/A" end
                                end
                                -- fire SR_UpdateMemory if available
                                local VE = ReplicatedStorage:FindFirstChild("VandraEvents")
                                if VE then
                                    local srMem = VE:FindFirstChild("SR_UpdateMemory")
                                    if srMem then srMem:FireClient(tp, 0) end
                                end
                                reply(true, "SpeedRun reset for " .. tp.Name)
                            else
                                task.spawn(function()
                                    local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
                                        if ok and uid then
                                            VandraSpeedRunData:ResetBestTime(uid)
                                            reply(true, "SpeedRun reset (offline) for " .. targetName)
                                        else
                                            reply(false, "Player not found: " .. targetName)
                                        end
                                    end)
                                end
                                return
                            end
                            
                            -- ============================================================
                            -- _ValueSummit: set summit reward value
                            -- ============================================================
                            if cmdName == "_ValueSummit" then
                                if not hasAccess(sender, "_Value") then reply(false, "No access: _Value"); return end
                                local v = tonumber(args[1])
                                if not v or v < 0 then reply(false, "Invalid value."); return end
                                VandraConfig:SetSummitValue(v)
                                task.wait(0.5)
                                VandraConfig:LoadValues()
                                reply(true, "Summit reward set to " .. v)
                                return
                            end
                            
                            -- ============================================================
                            -- _ValueApex: set apex reward value
                            -- ============================================================
                            if cmdName == "_ValueApex" then
                                if not hasAccess(sender, "_Value") then reply(false, "No access: _Value"); return end
                                local v = tonumber(args[1])
                                if not v or v < 0 then reply(false, "Invalid value."); return end
                                VandraConfig:SetApexValue(v)
                                task.wait(0.5)
                                VandraConfig:LoadValues()
                                reply(true, "Apex reward set to " .. v)
                                return
                            end
                            
                            -- ============================================================
                            -- _SkipMode: set skip checkpoint mode
                            -- ============================================================
                            if cmdName == "_SkipMode" then
                                if not hasAccess(sender, "_Value") then reply(false, "No access: _Value"); return end
                                local mode = args[1]
                                if type(mode) ~= "boolean" then
                                    -- args come as table, might be passed as string from client
                                    if mode == "true" or mode == true then mode = true
                                    elseif mode == "false" or mode == false then mode = false
                                    else reply(false, "Invalid skip mode value."); return end
                                    end
                                        VandraConfig:SetSkipCheckpointMode(mode)
                                        reply(true, "Skip Checkpoint = " .. tostring(mode))
                                        return
                                    end
                                    
                                    -- ============================================================
                                    -- _TeleportSelf: teleport sender to checkpoint
                                    -- ============================================================
                                    if cmdName == "_TeleportSelf" then
                                        -- any panel user can teleport themselves
                                        local locName = tostring(args[1] or "BC")
                                        if locName == "" then locName = "BC" end
                                        
                                        local char = sender.Character
                                        if not char then reply(false, "Character not found."); return end
                                        
                                        local ok = teleportCharacterTo(char, locName)
                                        if ok then
                                            reply(true, "Teleported to " .. locName)
                                        else
                                            reply(false, "Location not found: " .. locName)
                                        end
                                        return
                                    end
                                    
                                    -- ============================================================
                                    -- _TeleportPlayer: teleport another player to checkpoint
                                    -- Requires _Add access (general admin privilege)
                                    -- ============================================================
                                    if cmdName == "_TeleportPlayer" then
                                        if not hasAccess(sender, "_Add") then reply(false, "No access: Teleport Player"); return end
                                        local targetName = tostring(args[1] or "")
                                        local locName    = tostring(args[2] or "BC")
                                        if targetName == "" then reply(false, "No target specified."); return end
                                        if locName    == "" then locName = "BC" end
                                        
                                        local tp = findPlayer(targetName)
                                        if not tp then reply(false, "Player not online: " .. targetName); return end
                                        
                                        local char = tp.Character
                                        if not char then reply(false, tp.Name .. " has no character."); return end
                                        
                                        local ok = teleportCharacterTo(char, locName)
                                        if ok then
                                            reply(true, "Teleported " .. tp.Name .. " to " .. locName)
                                        else
                                            reply(false, "Location not found: " .. locName)
                                        end
                                        return
                                    end
                                    
                                    -- ============================================================
                                    -- _BroadcastG: global broadcast via MessagingService
                                    -- ============================================================
                                    if cmdName == "_BroadcastG" then
                                        -- any panel user can broadcast
                                        local msg = tostring(args[1] or "")
                                        if msg == "" then reply(false, "Empty message."); return end
                                        
                                        local role        = VandraTitle.GetRoleTitle(sender)
                                        local roleDisplay = VandraTitle.GetRoleDisplayText(role) or role or ""
                                        local formatted   = string.format("[%s] %s : %s", roleDisplay, sender.DisplayName, msg)
                                        
                                        pcall(function()
                                            MessagingService:PublishAsync(CHAT_TOPIC, formatted)
                                        end)
                                        SummitChatEvent:FireAllClients(formatted)
                                        reply(true, "Global broadcast sent.")
                                        return
                                    end
                                    
                                    -- ============================================================
                                    -- _BroadcastS: server-only broadcast
                                    -- ============================================================
                                    if cmdName == "_BroadcastS" then
                                        local msg = tostring(args[1] or "")
                                        if msg == "" then reply(false, "Empty message."); return end
                                        
                                        local role        = VandraTitle.GetRoleTitle(sender)
                                        local roleDisplay = VandraTitle.GetRoleDisplayText(role) or role or ""
                                        local formatted   = string.format("[%s] %s : %s", roleDisplay, sender.DisplayName, msg)
                                        
                                        SummitChatEvent:FireAllClients(formatted)
                                        reply(true, "Server broadcast sent.")
                                        return
                                    end
                                    
                                    -- unknown command
                                    reply(false, "Unknown command: " .. tostring(cmdName))
                                end)

