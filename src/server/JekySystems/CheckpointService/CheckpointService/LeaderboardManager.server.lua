 -- ServerScriptService / LeaderboardManager_Summit
-- v7 — fix stale GlobalLB data saat summit=0

local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local VandraTitle              = require(ServerStorage.JekyModules:WaitForChild("VandraTitle"))
local VandraBoardConfiguration = require(ServerStorage.JekyModules:WaitForChild("VandraBoardConfiguration"))
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))

local CONFIG = {
MAX_ENTRIES          = 10,
GLOBAL_INTERVAL      = 60,
SERVER_INTERVAL      = 30,
LB_PATH              = "AllPartSummitkitVandra/LeaderBoard",
TIMEOUT              = 30,
INIT_DELAY           = 5,
AUTO_SYNC_INTERVAL   = 300,
FORCE_INITIAL_SYNC   = true,
FORCE_SYNC_ON_SUMMIT = true,
}

local VandraEvents = ReplicatedStorage:WaitForChild("VandraEvents", CONFIG.TIMEOUT)
if not VandraEvents then return end

local GetServerLB = VandraEvents:WaitForChild("CP_Internal_GetServerLB", CONFIG.TIMEOUT)
local GetGlobalLB = VandraEvents:WaitForChild("CP_Internal_GetGlobalLB", CONFIG.TIMEOUT)
local ServerLBEvt = VandraEvents:WaitForChild("CP_Internal_ServerLBUpdate", CONFIG.TIMEOUT)
local GlobalLBEvt = VandraEvents:WaitForChild("CP_Internal_GlobalLBUpdate", CONFIG.TIMEOUT)
if not (GetServerLB and GetGlobalLB and ServerLBEvt and GlobalLBEvt) then return end

-- ============================================================
-- ROLE CACHE
-- ============================================================
local RoleCache = {}
Players.PlayerRemoving:Connect(function(p) RoleCache[p.UserId] = nil end)
    
    local function canShowOnLB(userId)
        if RoleCache[userId] == nil then
            local p = Players:GetPlayerByUserId(userId)
            if p then
                RoleCache[userId] = VandraBoardConfiguration:CanShowOnSummitLeaderboard(VandraTitle.GetRoleTitle(p))
            else
                RoleCache[userId] = true
            end
        end
        return RoleCache[userId]
    end
    
    -- ============================================================
    -- FORMAT
    -- ============================================================
    local function fmtNum(n)
        n = tonumber(n) or 0
        if n >= 1e6 then return ("%.1fM"):format(n / 1e6)
        elseif n >= 1e3 then return ("%.1fK"):format(n / 1e3)
        else return tostring(math.floor(n)) end
        end
            
            -- ============================================================
            -- DATA
            -- ============================================================
            local SrvData = {}
            local GlbData = {}
            
            -- ============================================================
            -- FIND LB
            -- ============================================================
            local function findLBs()
                local list = {}
                local cur  = workspace
                for _, part in ipairs(string.split(CONFIG.LB_PATH, "/")) do
                    cur = cur:FindFirstChild(part)
                    if not cur then return {} end
                end
                for _, model in ipairs(cur:GetChildren()) do
                    if not model:IsA("Model") then continue end
                    local nl = model.Name:lower()
                    local isG = nl:find("global") ~= nil
                    local isS = nl:find("server") ~= nil
                    if not (isG or isS) then continue end
                    local board = model:FindFirstChild("Board")
                    local detik = model:FindFirstChild("Detik")
                    if not (board and detik) then continue end
                    local bsg = board:FindFirstChild("SurfaceGui")
                    local dsg = detik:FindFirstChild("SurfaceGui")
                    if not (bsg and dsg) then continue end
                    table.insert(list, {
                    BSG      = bsg,
                    DSG      = dsg,
                    IsGlobal = isG,
                    Interval = isG and CONFIG.GLOBAL_INTERVAL or CONFIG.SERVER_INTERVAL,
                    Countdown= isG and CONFIG.GLOBAL_INTERVAL or CONFIG.SERVER_INTERVAL,
                    })
                end
                return list
            end
            
            -- ============================================================
            -- getUsername
            -- ============================================================
            local function getUsername(userId)
                local p = Players:GetPlayerByUserId(userId)
                if p then
                    PS.CacheUsername(userId, p.Name)
                    return p.Name
                end
                local cached = PS.GetUsernameFromUserId(userId)
                if cached and cached ~= "" then return cached end
                PS.ResolveUsernameBackfill(userId)
                return "Player_"..userId
            end
            
            -- ============================================================
            -- RENDER
            -- ============================================================
            local function render(lb)
                local init = lb.BSG:FindFirstChild("Init")
                local dtlb = lb.DSG:FindFirstChild("DetikLabel")
                if not init then return end
                local data = lb.IsGlobal and GlbData or SrvData
                
                for _, e in ipairs(data) do
                    PS.GetUsernameFromUserId(e.UserId)
                end
                
                for i = 1, CONFIG.MAX_ENTRIES do
                    local tf = init:FindFirstChild("Top"..i)
                    if not tf then continue end
                    local ul = tf:FindFirstChild("Username")
                    local tl = tf:FindFirstChild("Total")
                    local il = tf:FindFirstChild("ImageLabel")
                    if not (ul and tl) then continue end
                    local e = data[i]
                    if e then
                        local name = PS.GetUsernameFromUserId(e.UserId)
                        if not name or name == "" then name = e.Username end
                        if not name or name == "" then name = "Player_"..e.UserId end
                        
                        ul.Text = i..". "..name
                        tl.Text = "⛰️ "..fmtNum(e.Summit)
                        if il and il:IsA("ImageLabel") then
                            il.Image = "rbxthumb://type=AvatarHeadShot&id="..e.UserId.."&w=150&h=150"
                        end
                        
                        e.Username = name
                        
                        if name:find("^Player_") then
                            PS.ResolveUsernameBackfill(e.UserId)
                        end
                    else
                        ul.Text = i..". ---"
                        tl.Text = "⛰️ 0"
                        if il and il:IsA("ImageLabel") then il.Image = "" end
                    end
                end
                
                if dtlb then
                    local t = math.max(0, math.floor(lb.Countdown))
                    dtlb.Text = t > 0 and ("Update in "..t.." second"..(t ~= 1 and "s" or "")) or "Updating..."
                end
            end
            
            local function renderAll(lbs)
                for _, lb in ipairs(lbs) do render(lb) end
            end
            
            -- ============================================================
            -- Re-render loop
            -- ============================================================
            local function startRerenderLoop(lbs)
                task.spawn(function()
                    while true do
                        task.wait(3)
                        local need = false
                        for _, data in ipairs({ GlbData, SrvData }) do
                            for _, e in ipairs(data) do
                                if e.Username:find("^Player_") then
                                    local name = PS.GetUsernameFromUserId(e.UserId)
                                    if name and name ~= "" and not name:find("^Player_") then
                                        e.Username = name; need = true
                                    end
                                end
                            end
                        end
                        if need then renderAll(lbs) end
                    end
                end)
            end
            
            -- ============================================================
            -- PROCESS DATA
            -- ============================================================
            local function processServer(raw, lbs)
                local out  = {}
                local seen = {}
                for _, e in ipairs(raw or {}) do
                    if not (e and e.UserId) then continue end
                    if seen[e.UserId] then continue end
                    local sum = tonumber(e.Summit) or 0
                    if sum <= 0 then continue end
                    if not canShowOnLB(e.UserId) then continue end
                    seen[e.UserId] = true
                    table.insert(out, { UserId = e.UserId, Username = getUsername(e.UserId), Summit = sum })
                end
                table.sort(out, function(a, b)
                    if a.Summit ~= b.Summit then return a.Summit > b.Summit end
                    return (a.Username or "") < (b.Username or "")
                end)
                SrvData = out
                renderAll(lbs)
            end
            
            local function processGlobal(raw, lbs)
                local out  = {}
                local seen = {}
                
                -- Online players SELALU masuk seen (termasuk yg summit=0)
                -- Ini mencegah data lama DS muncul saat player sudah di-reset
                for _, p in ipairs(Players:GetPlayers()) do
                    -- Tandai seen dulu SEBELUM cek sum, supaya DS lama tidak bisa override
                    seen[p.UserId] = true
                    
                    local ls  = p:FindFirstChild("leaderstats")
                    local sv  = ls and ls:FindFirstChild("Summit")
                    local sum = sv and (tonumber(sv.Value) or 0) or 0
                    
                    -- Hanya masuk LB kalau summit > 0 dan boleh tampil
                    if sum > 0 and canShowOnLB(p.UserId) then
                        PS.CacheUsername(p.UserId, p.Name)
                        table.insert(out, { UserId = p.UserId, Username = p.Name, Summit = sum })
                    end
                end
                
                -- Offline dari DataStore — skip kalau sudah ada di seen (online player)
                for _, e in ipairs(raw or {}) do
                    if not (e and e.UserId) then continue end
                    if seen[e.UserId] then continue end  -- skip: online player sudah handle di atas
                        local sum = tonumber(e.Summit) or 0
                        if sum <= 0 then continue end
                        if not canShowOnLB(e.UserId) then continue end
                        seen[e.UserId] = true
                        table.insert(out, { UserId = e.UserId, Username = getUsername(e.UserId), Summit = sum })
                    end
                    
                    table.sort(out, function(a, b)
                        if a.Summit ~= b.Summit then return a.Summit > b.Summit end
                        return (a.Username or "") < (b.Username or "")
                    end)
                    for i, e in ipairs(out) do e.Rank = i end
                    GlbData = out
                    renderAll(lbs)
                end
                
                -- ============================================================
                -- FETCH
                -- ============================================================
                local function fetchServer(lbs)
                    local ok, d = pcall(function() return GetServerLB:Invoke() end)
                        if ok and d then processServer(d, lbs) end
                    end
                    
                    local function fetchGlobal(lbs)
                        local ok, d = pcall(function() return GetGlobalLB:Invoke() end)
                            if ok and d then processGlobal(d, lbs) end
                        end
                        
                        -- ============================================================
                        -- SETUP
                        -- ============================================================
                        local function setupListeners(lbs)
                            ServerLBEvt.Event:Connect(function(raw) processServer(raw, lbs) end)
                                GlobalLBEvt.Event:Connect(function(raw) processGlobal(raw, lbs) end)
                                end
                                    
                                    local function startLoop(lbs)
                                        task.spawn(function()
                                            task.wait(CONFIG.INIT_DELAY)
                                            if CONFIG.FORCE_INITIAL_SYNC then
                                                PS.GlobalLB.ForceSyncOnline()
                                                task.wait(2)
                                            end
                                            PS.PreloadOnlineUsernames()
                                            task.wait(0.5)
                                            fetchServer(lbs)
                                            fetchGlobal(lbs)
                                        end)
                                        
                                        task.spawn(function()
                                            while true do
                                                task.wait(1)
                                                for _, lb in ipairs(lbs) do
                                                    lb.Countdown = lb.Countdown - 1
                                                    local dtlb = lb.DSG:FindFirstChild("DetikLabel")
                                                    if dtlb then
                                                        local t = math.max(0, math.floor(lb.Countdown))
                                                        dtlb.Text = t > 0 and ("Update in "..t.." second"..(t ~= 1 and "s" or "")) or "Updating..."
                                                    end
                                                    if lb.Countdown <= 0 then
                                                        lb.Countdown = lb.Interval
                                                        if lb.IsGlobal then
                                                            task.spawn(function() fetchGlobal(lbs) end)
                                                            else
                                                                task.spawn(function() fetchServer(lbs) end)
                                                                end
                                                                end
                                                                end
                                                                end
                                                                end)
                                                                    
                                                                    task.spawn(function()
                                                                        while true do
                                                                            task.wait(CONFIG.AUTO_SYNC_INTERVAL)
                                                                            PS.PreloadOnlineUsernames()
                                                                            PS.GlobalLB.ForceSyncOnline()
                                                                        end
                                                                    end)
                                                                    
                                                                    startRerenderLoop(lbs)
                                                                end
                                                                
                                                                -- ============================================================
                                                                -- ENTRY
                                                                -- ============================================================
                                                                if RunService:IsServer() then
                                                                    task.wait(5)
                                                                    task.spawn(function()
                                                                        local lbs = findLBs()
                                                                        if #lbs == 0 then return end
                                                                        setupListeners(lbs)
                                                                        startLoop(lbs)
                                                                    end)
                                                                end

