-- ServerStorage/JekyModules/JekySpeedRunData
 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
 
local PS = require(
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky")
)
 
local JekySpeedRunData = {}
 
function JekySpeedRunData:LoadBestTime(userId)
    return PS.SpeedRun.Load(userId)
end
 
function JekySpeedRunData:SaveBestTime(userId, username, timeInSeconds, forceUpdate)
    return PS.SpeedRun.Save(userId, username, timeInSeconds, forceUpdate)
end
 
function JekySpeedRunData:ResetBestTime(userId)
    return PS.SpeedRun.Reset(userId)
end
 
function JekySpeedRunData:GetBestTime(userId)
    local d = PS.SpeedRun.Load(userId)
    return d and d.BestTime or 0
end
 
function JekySpeedRunData:GetCachedBestTime(userId)
    return PS.SpeedRun.GetCached(userId)
end
 
function JekySpeedRunData:GetGlobalLeaderboard(maxEntries)
    return PS.SpeedRun.GetLeaderboard(maxEntries or 100)
end
 
return JekySpeedRunData

