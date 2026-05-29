-- ServerScriptService > VipChatTagAPI
 
local Players = game:GetService("Players")
 
local API = {}
 
function API.IsVip(player)
    if not player or not player.Parent then return false end
    return player:GetAttribute("HasVipTitle") == true
end
 
function API.HasAura(player)
    if not player or not player.Parent then return false end
    return player:GetAttribute("HasVipAura") == true
end
 
function API.GetVipStatus(player)
    if not player or not player.Parent then
        return { hasVip = false }
    end
    return {
    hasVip    = player:GetAttribute("HasVipTitle") == true,
    hasAura   = player:GetAttribute("HasVipAura")  == true,
    }
end
 
function API.ConnectToAttribute(player, attributeName, callback)
    if not player or not player.Parent then return end
    player:GetAttributeChangedSignal(attributeName):Connect(function()
        if player and player.Parent then
            callback(player:GetAttribute(attributeName))
        end
    end)
    local current = player:GetAttribute(attributeName)
    if current ~= nil then callback(current) end
end
 
_G.VipChatTagAPI = API
 
return API

