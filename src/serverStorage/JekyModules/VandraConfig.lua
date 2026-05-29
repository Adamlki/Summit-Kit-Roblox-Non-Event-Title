-- ServerStorage/VandraModules/VandraConfig
 
local VandraGlobalData = require(script.Parent:WaitForChild("VandraGlobalData"))
local VandraConfig     = {}
 
VandraConfig.SPAWN_OFFSET_Y      = 5
VandraConfig.SPAWN_RANDOM_RANGE  = 4
VandraConfig.TOUCH_COOLDOWN      = 1
VandraConfig.SPAWN_IMMUNITY_TIME = 2
VandraConfig.SPEEDRUN_MIN_TIME   = 5
VandraConfig.SKIP_CHECKPOINT     = false
 
VandraConfig.SUMMIT_REWARDS = {
Summit     = 5,
ApexSummit = 200
}
 
-- FIX: Tambah _RSpeed ke COMMAND_ACCESS
-- Sebelumnya tidak ada entry _RSpeed sehingga HasCommandAccess selalu return false
-- dan reset speedrun tidak pernah bisa jalan
VandraConfig.COMMAND_ACCESS = {
Owner = {
_Add         = true,
_R           = true,
_Value       = true,
_Gift        = true,
_DVip        = true,
_AddVerified = true,
_DVerified   = true,
_AddRole     = true,
_RemoveRole  = true,
_RSpeed      = true,   -- FIX: reset speedrun
},
Developer = {
_Add         = true,
_R           = true,
_Value       = true,
_Gift        = true,
_DVip        = true,
_AddVerified = true,
_DVerified   = true,
_AddRole     = true,
_RemoveRole  = true,
_RSpeed      = true,   -- FIX
},
HeadAdmin = {
_Add         = true,
_R           = true,
_Value       = false,
_Gift        = true,
_DVip        = true,
_AddVerified = true,
_DVerified   = true,
_AddRole     = false,
_RemoveRole  = false,
_RSpeed      = true,   -- FIX
},
Admin = {
_Add         = false,
_R           = false,
_Value       = false,
_Gift        = false,
_DVip        = false,
_AddVerified = false,
_DVerified   = false,
_AddRole     = false,
_RemoveRole  = false,
_RSpeed      = false,
},
Moderator = {
_Add         = false,
_R           = false,
_Value       = false,
_Gift        = false,
_DVip        = false,
_AddVerified = false,
_DVerified   = false,
_AddRole     = false,
_RemoveRole  = false,
_RSpeed      = false,
},
Streamer = {
_Add         = false,
_R           = false,
_Value       = false,
_Gift        = false,
_DVip        = false,
_AddVerified = false,
_DVerified   = false,
_AddRole     = false,
_RemoveRole  = false,
_RSpeed      = false,
},
}
 
game:GetService("Players").RespawnTime = 2
 
function VandraConfig:LoadValues()
    self.SUMMIT_REWARDS.Summit     = VandraGlobalData:GetSummitValue()
    self.SUMMIT_REWARDS.ApexSummit = VandraGlobalData:GetApexValue()
end
 
function VandraConfig:SetSummitValue(value)
    if type(value) == "number" and value >= 0 then
        self.SUMMIT_REWARDS.Summit = value
        return VandraGlobalData:SetSummitValue(value)
    end
    return false
end
 
function VandraConfig:SetApexValue(value)
    if type(value) == "number" and value >= 0 then
        self.SUMMIT_REWARDS.ApexSummit = value
        return VandraGlobalData:SetApexValue(value)
    end
    return false
end
 
function VandraConfig:GetSummitValue()
    return self.SUMMIT_REWARDS.Summit
end
 
function VandraConfig:GetApexValue()
    return self.SUMMIT_REWARDS.ApexSummit
end
 
function VandraConfig:SetSkipCheckpointMode(skipMode)
    if type(skipMode) == "boolean" then
        self.SKIP_CHECKPOINT = skipMode
        return true
    end
    return false
end
 
function VandraConfig:GetSkipCheckpointMode()
    return self.SKIP_CHECKPOINT
end
 
function VandraConfig:HasCommandAccess(roleTitle, commandName)
    if not roleTitle or roleTitle == "" then return false end
    local roleAccess = self.COMMAND_ACCESS[roleTitle]
    if not roleAccess then return false end
    return roleAccess[commandName] == true
end
 
return VandraConfig

