-- ServerScriptService / SpeedRunLeaderboardManager 
local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local JekySpeedRunData       = require(ServerStorage.JekyModules:WaitForChild("JekySpeedRunData"))
local JekyConfig             = require(ServerStorage.JekyModules:WaitForChild("JekyConfig"))
local JekyTitle              = require(ServerStorage.JekyModules:WaitForChild("JekyTitle"))
local JekyBoardConfiguration = require(ServerStorage.JekyModules:WaitForChild("JekyBoardConfiguration"))
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))

local CONFIG = {
GLOBAL_UPDATE_INTERVAL  = 60,
SERVER_UPDATE_INTERVAL  = 30,
MAX_DISPLAY_ENTRIES     = 10,
LEADERBOARD_FOLDER_PATH = "AllPartSummitkitJeky/LeaderBoard",
SPEEDRUN_FOLDER_PATH    = "AllPartSummitkitJeky/SpeedRun",
WAIT_FOR_EVENTS_TIMEOUT = 30,
INITIAL_FETCH_DELAY     = 3,
RESET_FLUSH_DELAY       = 2,
}

local JekyEvents=ReplicatedStorage:WaitForChild("JekyEvents",CONFIG.WAIT_FOR_EVENTS_TIMEOUT)
if not JekyEvents then return end

local function getOrCreateRE(n)
    local e=JekyEvents:FindFirstChild(n)
    if not e then e=Instance.new("RemoteEvent"); e.Name=n; e.Parent=JekyEvents end; return e
    end
        local function getOrCreateBE(n)
            local e=JekyEvents:FindFirstChild(n)
            if not e then e=Instance.new("BindableEvent"); e.Name=n; e.Parent=JekyEvents end; return e
            end
                local function getOrCreateBF(n)
                    local e=JekyEvents:FindFirstChild(n)
                    if not e then e=Instance.new("BindableFunction"); e.Name=n; e.Parent=JekyEvents end; return e
                    end
                        
                        local SR_Start        = getOrCreateRE("SR_Start")
                        local SR_Finish       = getOrCreateRE("SR_Finish")
                        local SR_UpdateTimer  = getOrCreateRE("SR_UpdateTimer")
                        local SR_UpdateMemory = getOrCreateRE("SR_UpdateMemory")
                        local SR_Cheat        = getOrCreateRE("SR_Cheat")
                        
                        local SR_Internal_ServerLBUpdate = getOrCreateBE("SR_Internal_ServerLBUpdate")
                        local SR_Internal_GlobalLBUpdate = getOrCreateBE("SR_Internal_GlobalLBUpdate")
                        local SR_Internal_GetServerLB    = getOrCreateBF("SR_Internal_GetServerLB")
                        local SR_Internal_GetGlobalLB    = getOrCreateBF("SR_Internal_GetGlobalLB")
                        local SR_SyncBoard               = getOrCreateRE("SR_SyncBoard")
                        
                        local PlayerSpeedRunState={}
                        local GlobalLeaderboard={}
                        local ServerLeaderboard={}
                        
                        -- ============================================================
                        -- FORMAT TIME
                        -- ============================================================
                        local function formatTime(s)
                            if not s or s==0 then return "00:00.000" end
                            local m=math.floor(s/60); local sec=math.floor(s%60); local ms=math.floor((s%1)*1000)
                            return m>0 and ("%02d:%02d.%03d"):format(m,sec,ms) or ("00:%02d.%03d"):format(sec,ms)
                        end
                        local function formatTimeShort(s)
                            if not s or s==0 then return "N/A" end
                            local m=math.floor(s/60); local sec=math.floor(s%60); local ms=math.floor((s%1)*1000)
                            return m>0 and ("%d:%02d.%03d"):format(m,sec,ms) or ("%d.%03d"):format(sec,ms)
                        end
                        
                        -- ============================================================
                        -- ROLE CACHE
                        -- ============================================================
                        local RoleCache={}
                        Players.PlayerRemoving:Connect(function(p) RoleCache[p.UserId]=nil end)
                            
                            local function canShowOnSpeedRunLB(userId)
                                if RoleCache[userId]==nil then
                                    local p=Players:GetPlayerByUserId(userId)
                                    if p then
                                        RoleCache[userId]=JekyBoardConfiguration:CanShowOnSpeedRunLeaderboard(JekyTitle.GetRoleTitle(p))
                                    else
                                        RoleCache[userId]=true
                                    end
                                end
                                return RoleCache[userId]
                            end
                            
                            -- ============================================================
                            -- _getUsername — PERSIS GlobalBoard._getUsername
                            -- ============================================================
                            local function getUsername(userId)
                                local p=Players:GetPlayerByUserId(userId)
                                if p then PS.CacheUsername(userId,p.Name); return p.Name end
                                local cached=PS.GetUsernameFromUserId(userId)
                                if cached and cached~="" then return cached end
                                PS.ResolveUsernameBackfill(userId)
                                return "Player_"..userId
                            end
                            
                            -- ============================================================
                            -- UPDATE LB DATA
                            -- ============================================================
                            local function updateGlobalLeaderboard()
                                local ok,data=pcall(function() return JekySpeedRunData:GetGlobalLeaderboard(100) end)
                                    if not ok or not data then return end
                                    table.sort(data,function(a,b)
                                        local ta=tonumber(a.BestTime) or math.huge
                                        local tb=tonumber(b.BestTime) or math.huge
                                        if ta==0 then ta=math.huge end; if tb==0 then tb=math.huge end
                                        return ta<tb
                                    end)
                                    local filtered={}
                                    for _,e in ipairs(data) do
                                        if not (e and e.UserId) then continue end
                                        local t=tonumber(e.BestTime) or 0
                                        if t<=0 then continue end
                                        if not canShowOnSpeedRunLB(e.UserId) then continue end
                                        table.insert(filtered,{
                                        Rank=#filtered+1,
                                        UserId=e.UserId,
                                        Username=getUsername(e.UserId),
                                        BestTime=t,
                                        FormattedTime=formatTime(t),
                                        })
                                    end
                                    GlobalLeaderboard=filtered
                                    SR_Internal_GlobalLBUpdate:Fire(filtered)
                                    pcall(function() SR_SyncBoard:FireAllClients("UpdateBoard", filtered) end)
                                end
                                
                                local function updateServerLeaderboard()
                                    local data={}
                                    for _,p in ipairs(Players:GetPlayers()) do
                                        local uid=p.UserId; local state=PlayerSpeedRunState[uid]
                                        if state and (state.BestTime or 0)>0 and canShowOnSpeedRunLB(uid) then
                                            table.insert(data,{UserId=uid,Username=p.Name,BestTime=state.BestTime,FormattedTime=formatTime(state.BestTime),IsOnline=true})
                                        end
                                    end
                                    table.sort(data,function(a,b)
                                        local ta=tonumber(a.BestTime) or math.huge
                                        local tb=tonumber(b.BestTime) or math.huge
                                        return ta<tb
                                    end)
                                    for i,e in ipairs(data) do e.Rank=i end
                                    ServerLeaderboard=data; SR_Internal_ServerLBUpdate:Fire(data)
                                end
                                
                                SR_Internal_GetServerLB.OnInvoke=function() return ServerLeaderboard end
                                SR_Internal_GetGlobalLB.OnInvoke=function() return GlobalLeaderboard end
                                
                                -- ============================================================
                                -- FIND LB UI
                                -- ============================================================
                              -- UI Rendering dipindahkan ke SpeedrunBoardClient.client.lua

                                        
                                        -- ============================================================
                                        -- SPEEDRUN PARTS
                                        -- ============================================================
                                        local function setupSpeedRunParts()
                                            local path=string.split(CONFIG.SPEEDRUN_FOLDER_PATH,"/"); local cur=workspace
                                            for _,f in ipairs(path) do cur=cur:FindFirstChild(f); if not cur then return end end
                                            local sp=cur:FindFirstChild("Start"); local fp=cur:FindFirstChild("Finish")
                                            if not sp or not fp then return end
                                            sp.CanTouch=true; fp.CanTouch=true
                                            
                                            sp.Touched:Connect(function(hit)
                                                local char=hit.Parent; if not char or not char:IsA("Model") then return end
                                                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                                                local player=Players:GetPlayerFromCharacter(char); if not player then return end
                                                local uid=player.UserId
                                                if not PlayerSpeedRunState[uid] then
                                                    PlayerSpeedRunState[uid]={Username=player.Name,BestTime=0,IsRunning=false,StartTime=0,HasTouchedStart=false}
                                                end
                                                PlayerSpeedRunState[uid].StartTime=os.clock()
                                                PlayerSpeedRunState[uid].IsRunning=true
                                                PlayerSpeedRunState[uid].HasTouchedStart=true
                                                SR_Start:FireClient(player)
                                            end)
                                            
                                            fp.Touched:Connect(function(hit)
                                                local char=hit.Parent; if not char or not char:IsA("Model") then return end
                                                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                                                local player=Players:GetPlayerFromCharacter(char); if not player then return end
                                                local uid=player.UserId
                                                if not PlayerSpeedRunState[uid] or not PlayerSpeedRunState[uid].IsRunning then return end
                                                if not PlayerSpeedRunState[uid].HasTouchedStart then
                                                    SR_Cheat:FireClient(player); PlayerSpeedRunState[uid].IsRunning=false; return
                                                end
                                                local elapsed=os.clock()-PlayerSpeedRunState[uid].StartTime
                                                if elapsed<(JekyConfig.SPEEDRUN_MIN_TIME or 5) then
                                                    SR_Cheat:FireClient(player); PlayerSpeedRunState[uid].IsRunning=false; return
                                                end
                                                PlayerSpeedRunState[uid].IsRunning=false; PlayerSpeedRunState[uid].HasTouchedStart=false
                                                local old=PlayerSpeedRunState[uid].BestTime or 0
                                                local isNew=(old==0) or (elapsed<old)
                                                if isNew then
                                                    local saved=JekySpeedRunData:SaveBestTime(uid,player.Name,elapsed,false)
                                                    if saved then
                                                        PlayerSpeedRunState[uid].BestTime=elapsed
                                                        local ls=player:FindFirstChild("leaderstats")
                                                        if ls then local btv=ls:FindFirstChild("BestTime"); if btv and btv:IsA("StringValue") then btv.Value=formatTime(elapsed) end end
                                                        SR_Finish:FireClient(player,elapsed,true)
                                                        SR_UpdateMemory:FireClient(player,elapsed)
                                                        updateGlobalLeaderboard(); updateServerLeaderboard()
                                                    else SR_Finish:FireClient(player,elapsed,false) end
                                                    else SR_Finish:FireClient(player,elapsed,false) end
                                                    end)
                                                    end
                                                        
                                                        -- ============================================================
                                                        -- PLAYER MANAGEMENT
                                                        -- ============================================================
                                                        Players.PlayerAdded:Connect(function(player)
                                                            local uid=player.UserId
                                                            PS.CacheUsername(uid,player.Name)
                                                            local ls=player:FindFirstChild("leaderstats")
                                                            if not ls then ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player end
                                                            local btv=ls:FindFirstChild("BestTime"); if btv then btv:Destroy() end
                                                            btv=Instance.new("StringValue"); btv.Name="BestTime"; btv.Value="N/A"; btv.Parent=ls
                                                            task.spawn(function()
                                                                local d=JekySpeedRunData:LoadBestTime(uid); local t=d.BestTime or 0
                                                                PlayerSpeedRunState[uid]={Username=player.Name,BestTime=t,IsRunning=false,StartTime=0,HasTouchedStart=false}
                                                                btv.Value=t>0 and formatTime(t) or "N/A"
                                                                SR_UpdateMemory:FireClient(player,t>0 and t or 0)
                                                            end)
                                                            player.Chatted:Connect(function(msg)
                                                                local roleTitle=JekyTitle.GetRoleTitle(player); if not roleTitle then return end
                                                                local parts=string.split(msg," "); local cmd=parts[1]
                                                                if cmd=="_RSpeed" and #parts>=2 then
                                                                    if not JekyConfig:HasCommandAccess(roleTitle,"_RSpeed") then return end
                                                                    local tname=tostring(parts[2]); local tp=nil
                                                                    for _,p in ipairs(Players:GetPlayers()) do
                                                                        if string.lower(p.Name)==string.lower(tname) or string.lower(p.DisplayName)==string.lower(tname) then tp=p; break end
                                                                    end
                                                                    if tp then
                                                                        local tuid=tp.UserId
                                                                        JekySpeedRunData:ResetBestTime(tuid)
                                                                        if PlayerSpeedRunState[tuid] then PlayerSpeedRunState[tuid].BestTime=0 end
                                                                        local tls=tp:FindFirstChild("leaderstats")
                                                                        if tls then local tbtv=tls:FindFirstChild("BestTime"); if tbtv and tbtv:IsA("StringValue") then tbtv.Value="N/A" end end
                                                                        SR_UpdateMemory:FireClient(tp,0)
                                                                        task.spawn(function()
                                                                            task.wait(CONFIG.RESET_FLUSH_DELAY); updateGlobalLeaderboard(); updateServerLeaderboard()
                                                                        end)
                                                                    else
                                                                        local ok,uid2=pcall(function() return Players:GetUserIdFromNameAsync(tname) end)
                                                                            if ok and uid2 then
                                                                                task.spawn(function()
                                                                                    JekySpeedRunData:ResetBestTime(uid2); task.wait(CONFIG.RESET_FLUSH_DELAY); updateGlobalLeaderboard()
                                                                                end)
                                                                            end
                                                                        end
                                                                    end
                                                                end)
                                                            end)
                                                            
                                                            Players.PlayerRemoving:Connect(function(p) PlayerSpeedRunState[p.UserId]=nil end)
                                                                
                                                                task.spawn(function() while true do task.wait(CONFIG.GLOBAL_UPDATE_INTERVAL); updateGlobalLeaderboard() end end)
                                                                    task.spawn(function() while true do task.wait(CONFIG.SERVER_UPDATE_INTERVAL); updateServerLeaderboard() end end)
                                                                        
local function initialize()
    setupSpeedRunParts()
    task.wait(CONFIG.INITIAL_FETCH_DELAY)
    updateGlobalLeaderboard(); updateServerLeaderboard()
end
                                                                        
                                                                        if RunService:IsServer() then
                                                                            task.wait(5); task.spawn(initialize)
                                                                        end
