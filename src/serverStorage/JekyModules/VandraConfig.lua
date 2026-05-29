-- ServerStorage/JekyModules/VandraConfig
 
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
 
-- Jauh lebih ringkas! Hanya tulis perintah yang diizinkan (true).
-- Jika role atau perintah tidak tertulis, sistem otomatis menganggapnya "false" (tidak punya akses).
VandraConfig.COMMAND_ACCESS = {
	Owner = {
		_Add = true, _R = true, _Value = true, _Gift = true, _DVip = true,
		_AddVerified = true, _DVerified = true, _AddRole = true, _RemoveRole = true, _RSpeed = true
	},
	Developer = {
		_Add = true, _R = true, _Value = true, _Gift = true, _DVip = true,
		_AddVerified = true, _DVerified = true, _AddRole = true, _RemoveRole = true, _RSpeed = true
	},
	HeadAdmin = {
		_Add = true, _R = true, _Gift = true, _DVip = true,
		_AddVerified = true, _DVerified = true, _RSpeed = true
	}
	-- Admin, Moderator, dan Streamer tidak perlu ditulis karena tidak punya akses sama sekali
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
	
	-- Tambahan validasi: Pastikan role tersebut memang terdaftar di table
    if type(roleAccess) == "table" then
        return roleAccess[commandName] == true
    end
	
    return false
end
 
return VandraConfig