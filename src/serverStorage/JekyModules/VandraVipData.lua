-- ServerStorage/JekyModules/JekyVipData
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))
local JekyVipData = {}
function JekyVipData:Load(userId)           return PS.Vip.Load(userId)           end
function JekyVipData:Save(userId, isVip)          PS.Vip.Save(userId, isVip)            end
function JekyVipData:SaveOnLeave(userId, isVip)   PS.Vip.SaveOnLeave(userId, isVip)     end
return JekyVipData

