-- ServerStorage/JekyModules/VandraVipData
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))
local VandraVipData = {}
function VandraVipData:Load(userId)           return PS.Vip.Load(userId)           end
function VandraVipData:Save(userId, isVip)          PS.Vip.Save(userId, isVip)            end
function VandraVipData:SaveOnLeave(userId, isVip)   PS.Vip.SaveOnLeave(userId, isVip)     end
return VandraVipData

