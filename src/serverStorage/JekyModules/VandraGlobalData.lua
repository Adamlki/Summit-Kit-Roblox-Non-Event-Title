-- ServerStorage/JekyModules/JekyGlobalData
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))
local JekyGlobalData = {}
function JekyGlobalData:Initialize()  PS.Config.Load(); return true end
function JekyGlobalData:LoadConfig()  PS.Config.Load() end
function JekyGlobalData:SetSummitValue(v) if type(v)=="number" and v>=0 then PS.Config.Set("SummitValue",v); return true end; return false end
function JekyGlobalData:SetApexValue(v)   if type(v)=="number" and v>=0 then PS.Config.Set("ApexValue",v);   return true end; return false end
function JekyGlobalData:GetSummitValue()  return PS.Config.Get("SummitValue") or 1    end
function JekyGlobalData:GetApexValue()    return PS.Config.Get("ApexValue")   or 2000 end
return JekyGlobalData

