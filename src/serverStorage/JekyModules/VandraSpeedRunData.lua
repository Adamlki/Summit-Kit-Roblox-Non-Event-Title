-- ServerStorage/JekyModules/VandraSpeedRunData
 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
 
local PS = require(
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky")
)
 
local VandraSpeedRunData = {}
 
function VandraSpeedRunData:LoadBestTime(userId)
    return PS.SpeedRun.Load(userId)
end
 
function VandraSpeedRunData:SaveBestTime(userId, username, timeInSeconds, forceUpdate)
    return PS.SpeedRun.Save(userId, username, timeInSeconds, forceUpdate)
end
 
function VandraSpeedRunData:ResetBestTime(userId)
    return PS.SpeedRun.Reset(userId)
end
 
function VandraSpeedRunData:GetBestTime(userId)
    local d = PS.SpeedRun.Load(userId)
    return d and d.BestTime or 0
end
 
function VandraSpeedRunData:GetCachedBestTime(userId)
    return PS.SpeedRun.GetCached(userId)
end
 
function VandraSpeedRunData:GetGlobalLeaderboard(maxEntries)
    return PS.SpeedRun.GetLeaderboard(maxEntries or 100)
end
 
return VandraSpeedRunData

