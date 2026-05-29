-- ServerStorage/JekyModules/JekyVerified
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("JekyProfile"):WaitForChild("ProfileServiceJeky"))
local JekyVerified = {}
JekyVerified.AutoVerifyRoles    = true
JekyVerified.AlwaysVerifiedUsers= { "BukanYgDiaPilih","","kenn_justforu","TemanBaik" }
JekyVerified.WishlistUsers      = { "PlayerMenunggu1","PlayerMenunggu2" }
function JekyVerified:Initialize()                PS.Verified.Load(); return true end
function JekyVerified:IsInAlwaysVerified(u)
    if not u then return false end; local l=string.lower(u)
        for _,v in ipairs(self.AlwaysVerifiedUsers) do if string.lower(v)==l then return true end end; return false end
        function JekyVerified:IsInWishlist(u)
            if not u then return false end; local l=string.lower(u)
                for _,v in ipairs(self.WishlistUsers) do if string.lower(v)==l then return true end end; return false end
                function JekyVerified:AddDynamicVerified(u,by,r) return PS.Verified.Add(u,by,r) end
                function JekyVerified:RemoveDynamicVerified(u)   return PS.Verified.Remove(u)   end
                function JekyVerified:IsInDynamicVerified(u)     return PS.Verified.Check(u)    end
                function JekyVerified:CheckPlayer(player, roleTitle)
                    if not player then return false end
                    local u = player.Name
                    if self:IsInAlwaysVerified(u) then return true end
                    if self:IsInDynamicVerified(u) then return true end
                    if self.AutoVerifyRoles and roleTitle and roleTitle ~= "" then return true end
                    if self:IsInWishlist(u) then self:AddDynamicVerified(u,"AutoSystem","Auto from wishlist"); return true end
                    return false
                end
                function JekyVerified:GetAllVerifiedUsers()
                    local list=PS.Verified.Load(); local dyn={}
                    for _,e in ipairs(list) do table.insert(dyn,{username=e.username,addedBy=e.addedBy,reason=e.reason}) end
                    return { module=self.AlwaysVerifiedUsers, dynamic=dyn, wishlist=self.WishlistUsers }
                end
                return JekyVerified

