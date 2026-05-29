-- ServerStorage/JekyModules/JekyDataStore
local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
local PS = require(
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky")
)
 
local JekyDataStore = {}
 
function JekyDataStore:Initialize()
    PS.Config.Load()
    task.spawn(function()
        while true do task.wait(30); PS.GlobalLB.Get(100) end
    end)
    return true
end
 
-- ============================================================
-- PROFILE
-- ============================================================
local function wrap(d)
    if not d then return nil end
    return {
    CheckpointData = { CurrentCheckpoint=d.CurrentCheckpoint, VisitedCheckpoints=d.VisitedCheckpoints, TotalDeaths=d.TotalDeaths },
    SummitData     = { TotalSummit=d.TotalSummit },
    }
end
 
function JekyDataStore:LoadProfile(userId, forceLoad)
    local p = PS.Profile.Load(userId, forceLoad)
    return p and wrap(p.data) or nil
end
 
function JekyDataStore:GetProfile(userId)
    return wrap(PS.Profile.Get(userId))
end
 
function JekyDataStore:SaveProfile(userId, release)
    if release then return PS.Profile.Release(userId) end
    return PS.Profile.Save(userId, false)
end
 
function JekyDataStore:UpdateCheckpoint(userId, cpId)
    local d = PS.Profile.Get(userId); if not d then return false end
    d.CurrentCheckpoint = cpId; d.VisitedCheckpoints[cpId] = true; return true
end
 
function JekyDataStore:UpdateVisitedCheckpoints(userId, visited)
    local d = PS.Profile.Get(userId); if not d then return false end
    d.VisitedCheckpoints = visited; return true
end
 
function JekyDataStore:UpdateSummit(userId, amount)
    local d = PS.Profile.Get(userId); if not d then return false end
    d.TotalSummit = d.TotalSummit + amount; return true
end
 
function JekyDataStore:IncrementDeaths(userId)
    local d = PS.Profile.Get(userId); if not d then return false end
    d.TotalDeaths = (d.TotalDeaths or 0) + 1; return true
end
 
function JekyDataStore:ForceUpdateSummit(userId, newTotal)
    local d = PS.Profile.Get(userId)
    if d then
        d.TotalSummit = newTotal
        PS.Profile.Save(userId, false)
    else
        -- Player offline: update langsung ke DataStore
        task.spawn(function()
            local store = DataStoreService:GetDataStore("JekyProfile_v1")
            pcall(function()
                store:UpdateAsync("Player_" .. userId, function(old)
                    if not old then return nil end
                    old.TotalSummit  = newTotal
                    old._lastUpdate  = os.time()
                    return old
                end)
            end)
        end)
    end
    -- Update Global LB
    local name = "Player_" .. userId
    local p    = Players:GetPlayerByUserId(userId)
    if p then name = p.Name end
    PS.GlobalLB.Update(userId, name, newTotal)
    return true
end
 
-- ============================================================
-- GLOBAL LB
-- ============================================================
function JekyDataStore:UpdateGlobalLeaderboardEntry(userId, username, total)
    return PS.GlobalLB.Update(userId, username, total)
end
function JekyDataStore:GetGlobalLeaderboard(max)
    return PS.GlobalLB.Get(max or 100)
end
function JekyDataStore:ForceRefreshGlobalLeaderboard()
    return PS.GlobalLB.Get(100)
end
function JekyDataStore:GetPlayerGlobalRank(userId)
    local _, data = PS.GlobalLB.Get(100)
    for rank, e in ipairs(data) do
        if e.UserId == userId then return rank end
    end
    return nil
end
function JekyDataStore:GetRequestBudget()
    local ok, v = pcall(function()
        return DataStoreService:GetRequestBudgetForRequestType(
        Enum.DataStoreRequestType.UpdateAsync)
    end)
    return ok and v or 0
end
 
return JekyDataStore

