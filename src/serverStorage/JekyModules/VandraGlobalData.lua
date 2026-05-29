-- ServerStorage/JekyModules/VandraGlobalData
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))
local VandraGlobalData = {}
function VandraGlobalData:Initialize()  PS.Config.Load(); return true end
function VandraGlobalData:LoadConfig()  PS.Config.Load() end
function VandraGlobalData:SetSummitValue(v) if type(v)=="number" and v>=0 then PS.Config.Set("SummitValue",v); return true end; return false end
function VandraGlobalData:SetApexValue(v)   if type(v)=="number" and v>=0 then PS.Config.Set("ApexValue",v);   return true end; return false end
function VandraGlobalData:GetSummitValue()  return PS.Config.Get("SummitValue") or 1    end
function VandraGlobalData:GetApexValue()    return PS.Config.Get("ApexValue")   or 2000 end
return VandraGlobalData

