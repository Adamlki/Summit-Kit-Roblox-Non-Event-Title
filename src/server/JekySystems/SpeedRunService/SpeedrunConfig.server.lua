-- ServerScriptService / SpeedRunLeaderboardManager 
local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local VandraSpeedRunData       = require(ServerStorage.JekyModules:WaitForChild("VandraSpeedRunData"))
local VandraConfig             = require(ServerStorage.JekyModules:WaitForChild("VandraConfig"))
local VandraTitle              = require(ServerStorage.JekyModules:WaitForChild("VandraTitle"))
local VandraBoardConfiguration = require(ServerStorage.JekyModules:WaitForChild("VandraBoardConfiguration"))
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))

local CONFIG = {
GLOBAL_UPDATE_INTERVAL  = 60,
SERVER_UPDATE_INTERVAL  = 30,
MAX_DISPLAY_ENTRIES     = 10,
LEADERBOARD_FOLDER_PATH = "AllPartSummitkitVandra/LeaderBoard",
SPEEDRUN_FOLDER_PATH    = "AllPartSummitkitVandra/SpeedRun",
WAIT_FOR_EVENTS_TIMEOUT = 30,
INITIAL_FETCH_DELAY     = 3,
RESET_FLUSH_DELAY       = 2,
}

local VandraEvents=ReplicatedStorage:WaitForChild("VandraEvents",CONFIG.WAIT_FOR_EVENTS_TIMEOUT)
if not VandraEvents then return end

local function getOrCreateRE(n)
    local e=VandraEvents:FindFirstChild(n)
    if not e then e=Instance.new("RemoteEvent"); e.Name=n; e.Parent=VandraEvents end; return e
    end
        local function getOrCreateBE(n)
            local e=VandraEvents:FindFirstChild(n)
            if not e then e=Instance.new("BindableEvent"); e.Name=n; e.Parent=VandraEvents end; return e
            end
                local function getOrCreateBF(n)
                    local e=VandraEvents:FindFirstChild(n)
                    if not e then e=Instance.new("BindableFunction"); e.Name=n; e.Parent=VandraEvents end; return e
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
                                        RoleCache[userId]=VandraBoardConfiguration:CanShowOnSpeedRunLeaderboard(VandraTitle.GetRoleTitle(p))
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
                                local ok,data=pcall(function() return VandraSpeedRunData:GetGlobalLeaderboard(100) end)
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
                                local function findLeaderboards()
                                    local lbs={}; local path=string.split(CONFIG.LEADERBOARD_FOLDER_PATH,"/"); local cur=workspace
                                    for _,f in ipairs(path) do cur=cur:FindFirstChild(f); if not cur then return {} end end
                                    for _,model in ipairs(cur:GetChildren()) do
                                        if not model:IsA("Model") then continue end
                                        if not string.find(string.lower(model.Name),"speedrun") then continue end
                                        local board=model:FindFirstChild("Board"); local detik=model:FindFirstChild("Detik")
                                        if not (board and detik) then continue end
                                        local bsg=board:FindFirstChild("SurfaceGui"); local dsg=detik:FindFirstChild("SurfaceGui")
                                        if not (bsg and dsg) then continue end
                                        table.insert(lbs,{BoardSurfaceGui=bsg,DetikSurfaceGui=dsg,IsGlobal=true,
                                        UpdateInterval=CONFIG.GLOBAL_UPDATE_INTERVAL,NextUpdateIn=CONFIG.GLOBAL_UPDATE_INTERVAL})
                                    end
                                    return lbs
                                end
                                
                                -- ============================================================
                                -- RENDER — pola GlobalBoard._displayLeaderboard (loop 2x)
                                -- ============================================================
                                local function updateLeaderboardUI(lb)
                                    local init=lb.BoardSurfaceGui:FindFirstChild("Init"); if not init then return end
                                    local dl=lb.DetikSurfaceGui:FindFirstChild("DetikLabel")
                                    
                                    -- Loop 1: preload username (sama GlobalBoard)
                                    for _,e in ipairs(GlobalLeaderboard) do
                                        PS.GetUsernameFromUserId(e.UserId)
                                    end
                                    
                                    -- Loop 2: render
                                    for i=1, CONFIG.MAX_DISPLAY_ENTRIES do
                                        local tf=init:FindFirstChild("Top"..i); if not tf then continue end
                                        local ul=tf:FindFirstChild("Username"); local tl=tf:FindFirstChild("Total"); local il=tf:FindFirstChild("ImageLabel")
                                        if not (ul and tl) then continue end
                                        local e=GlobalLeaderboard[i]
                                        if e then
                                            local name=PS.GetUsernameFromUserId(e.UserId)
                                            if not name or name=="" then name=e.Username end
                                            if not name or name=="" then name="Player_"..e.UserId end
                                            e.Username=name  -- update entry
                                            ul.Text=i..". "..name
                                            tl.Text="🏃 "..formatTimeShort(e.BestTime)
                                            if il and il:IsA("ImageLabel") and e.UserId then
                                                il.Image="rbxthumb://type=AvatarHeadShot&id="..e.UserId.."&w=150&h=150"
                                            end
                                            if name:find("^Player_") then PS.ResolveUsernameBackfill(e.UserId) end
                                        else
                                            ul.Text=i..". ---"; tl.Text="🏃 --:--.---"
                                            if il and il:IsA("ImageLabel") then il.Image="" end
                                        end
                                    end
                                    
                                    if dl then
                                        local t=math.max(0,math.floor(lb.NextUpdateIn))
                                        dl.Text=t>0 and ("Update in "..t.." second"..(t~=1 and "s" or "")) or "Updating..."
                                    end
                                end
                                
                                local function updateAllUI(lbs)
                                    for _,lb in ipairs(lbs) do updateLeaderboardUI(lb) end
                                end
                                
                                -- Re-render loop
                                local function startRerenderLoop(lbs)
                                    task.spawn(function()
                                        while true do
                                            task.wait(3)
                                            local need=false
                                            for _,e in ipairs(GlobalLeaderboard) do
                                                if e.Username:find("^Player_") then
                                                    local name=PS.GetUsernameFromUserId(e.UserId)
                                                    if name and name~="" and not name:find("^Player_") then
                                                        e.Username=name; need=true
                                                    end
                                                end
                                            end
                                            if need then updateAllUI(lbs) end
                                        end
                                    end)
                                end
                                
                                -- ============================================================
                                -- LISTENERS + LOOPS
                                -- ============================================================
                                local function setupRealtimeListeners(lbs)
                                    SR_Internal_GlobalLBUpdate.Event:Connect(function() updateAllUI(lbs) end)
                                    end
                                        
                                        local function startUpdateLoops(lbs)
                                            task.spawn(function()
                                                task.wait(CONFIG.INITIAL_FETCH_DELAY)
                                                PS.PreloadOnlineUsernames()
                                                task.wait(0.5)
                                                updateGlobalLeaderboard()
                                                updateAllUI(lbs)
                                            end)
                                            task.spawn(function()
                                                while true do
                                                    task.wait(1)
                                                    for _,lb in ipairs(lbs) do
                                                        lb.NextUpdateIn=lb.NextUpdateIn-1
                                                        if lb.NextUpdateIn<=0 then
                                                            lb.NextUpdateIn=lb.UpdateInterval
                                                            updateGlobalLeaderboard()
                                                            updateAllUI(lbs)
                                                        end
                                                        local dl=lb.DetikSurfaceGui and lb.DetikSurfaceGui:FindFirstChild("DetikLabel")
                                                        if dl then
                                                            local t=math.max(0,math.floor(lb.NextUpdateIn))
                                                            dl.Text=t>0 and ("Update in "..t.." second"..(t~=1 and "s" or "")) or "Updating..."
                                                        end
                                                    end
                                                end
                                            end)
                                            startRerenderLoop(lbs)
                                        end
                                        
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
                                                if elapsed<(VandraConfig.SPEEDRUN_MIN_TIME or 5) then
                                                    SR_Cheat:FireClient(player); PlayerSpeedRunState[uid].IsRunning=false; return
                                                end
                                                PlayerSpeedRunState[uid].IsRunning=false; PlayerSpeedRunState[uid].HasTouchedStart=false
                                                local old=PlayerSpeedRunState[uid].BestTime or 0
                                                local isNew=(old==0) or (elapsed<old)
                                                if isNew then
                                                    local saved=VandraSpeedRunData:SaveBestTime(uid,player.Name,elapsed,false)
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
                                                                local d=VandraSpeedRunData:LoadBestTime(uid); local t=d.BestTime or 0
                                                                PlayerSpeedRunState[uid]={Username=player.Name,BestTime=t,IsRunning=false,StartTime=0,HasTouchedStart=false}
                                                                btv.Value=t>0 and formatTime(t) or "N/A"
                                                                SR_UpdateMemory:FireClient(player,t>0 and t or 0)
                                                            end)
                                                            player.Chatted:Connect(function(msg)
                                                                local roleTitle=VandraTitle.GetRoleTitle(player); if not roleTitle then return end
                                                                local parts=string.split(msg," "); local cmd=parts[1]
                                                                if cmd=="_RSpeed" and #parts>=2 then
                                                                    if not VandraConfig:HasCommandAccess(roleTitle,"_RSpeed") then return end
                                                                    local tname=tostring(parts[2]); local tp=nil
                                                                    for _,p in ipairs(Players:GetPlayers()) do
                                                                        if string.lower(p.Name)==string.lower(tname) or string.lower(p.DisplayName)==string.lower(tname) then tp=p; break end
                                                                    end
                                                                    if tp then
                                                                        local tuid=tp.UserId
                                                                        VandraSpeedRunData:ResetBestTime(tuid)
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
                                                                                    VandraSpeedRunData:ResetBestTime(uid2); task.wait(CONFIG.RESET_FLUSH_DELAY); updateGlobalLeaderboard()
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
                                                                            local lbs=findLeaderboards()
                                                                            if #lbs>0 then setupRealtimeListeners(lbs); startUpdateLoops(lbs) end
                                                                            setupSpeedRunParts()
                                                                            task.wait(CONFIG.INITIAL_FETCH_DELAY)
                                                                            updateGlobalLeaderboard(); updateServerLeaderboard()
                                                                        end
                                                                        
                                                                        if RunService:IsServer() then
                                                                            task.wait(5); task.spawn(initialize)
                                                                        end

