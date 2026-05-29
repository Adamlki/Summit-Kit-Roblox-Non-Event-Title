-- ServerStorage/JekyModules/JekyConfig
 
local JekyGlobalData = require(script.Parent:WaitForChild("JekyGlobalData"))
local JekyConfig     = {}
 
JekyConfig.SPAWN_OFFSET_Y      = 5
JekyConfig.SPAWN_RANDOM_RANGE  = 4
JekyConfig.TOUCH_COOLDOWN      = 1
JekyConfig.SPAWN_IMMUNITY_TIME = 2
JekyConfig.SPEEDRUN_MIN_TIME   = 120
JekyConfig.SKIP_CHECKPOINT     = false
 
JekyConfig.SUMMIT_REWARDS = {
	Summit     = 1,
	ApexSummit = 2
}
 
-- Jauh lebih ringkas! Hanya tulis perintah yang diizinkan (true).
-- Jika role atau perintah tidak tertulis, sistem otomatis menganggapnya "false" (tidak punya akses).
JekyConfig.COMMAND_ACCESS = {
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
 
function JekyConfig:LoadValues()
    self.SUMMIT_REWARDS.Summit     = JekyGlobalData:GetSummitValue()
    self.SUMMIT_REWARDS.ApexSummit = JekyGlobalData:GetApexValue()
end
 
function JekyConfig:SetSummitValue(value)
    if type(value) == "number" and value >= 0 then
        self.SUMMIT_REWARDS.Summit = value
        return JekyGlobalData:SetSummitValue(value)
    end
    return false
end
 
function JekyConfig:SetApexValue(value)
    if type(value) == "number" and value >= 0 then
        self.SUMMIT_REWARDS.ApexSummit = value
        return JekyGlobalData:SetApexValue(value)
    end
    return false
end
 
function JekyConfig:GetSummitValue()
    return self.SUMMIT_REWARDS.Summit
end
 
function JekyConfig:GetApexValue()
    return self.SUMMIT_REWARDS.ApexSummit
end
 
function JekyConfig:SetSkipCheckpointMode(skipMode)
    if type(skipMode) == "boolean" then
        self.SKIP_CHECKPOINT = skipMode
        return true
    end
    return false
end
 
function JekyConfig:GetSkipCheckpointMode()
    return self.SKIP_CHECKPOINT
end
 
function JekyConfig:HasCommandAccess(roleTitle, commandName)
    if not roleTitle or roleTitle == "" then return false end
    local roleAccess = self.COMMAND_ACCESS[roleTitle]
	
	-- Tambahan validasi: Pastikan role tersebut memang terdaftar di table
    if type(roleAccess) == "table" then
        return roleAccess[commandName] == true
    end
	
    return false
end
 
return JekyConfig