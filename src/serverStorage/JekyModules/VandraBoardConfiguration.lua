-- ServerStorage/VandraModules/VandraBoardConfiguration
local VandraBoardConfiguration = {}

-- FILTER UNTUK SUMMIT LEADERBOARD (Server & Global)
-- Set false untuk menyembunyikan role dari Summit Leaderboard
VandraBoardConfiguration.SummitRoleFilter = {
Owner = true,
Developer = true,
HeadAdmin = true,
Admin = true,
Moderator = true,
Streamer = true,
Community = true,
}

-- FILTER UNTUK SPEEDRUN LEADERBOARD
-- Set false untuk menyembunyikan role dari SpeedRun Leaderboard
VandraBoardConfiguration.SpeedRunRoleFilter = {
Owner = true,
Developer = true,
HeadAdmin = true,
Admin = true,
Moderator = true,
Streamer = true,
Community = true,
}

-- FILTER UNTUK ADMIN BOARD (ROLE SHOWCASE)
-- Set false untuk menyembunyikan role dari Admin Board
VandraBoardConfiguration.AdminBoardRoleFilter = {
Owner = true,
Developer = true,
HeadAdmin = true,
Admin = true,
Moderator = true,
Streamer = false,
Community = false,
}

function VandraBoardConfiguration:CanShowOnSummitLeaderboard(roleTitle)
    if not roleTitle or roleTitle == "" then
        return true
    end
    
    if self.SummitRoleFilter[roleTitle] ~= nil then
        return self.SummitRoleFilter[roleTitle]
    end
    
    return true
end

function VandraBoardConfiguration:CanShowOnSpeedRunLeaderboard(roleTitle)
    if not roleTitle or roleTitle == "" then
        return true
    end
    
    if self.SpeedRunRoleFilter[roleTitle] ~= nil then
        return self.SpeedRunRoleFilter[roleTitle]
    end
    
    return true
end

function VandraBoardConfiguration:CanShowOnAdminBoard(roleTitle)
    if not roleTitle or roleTitle == "" then
        return true
    end
    
    if self.AdminBoardRoleFilter[roleTitle] ~= nil then
        return self.AdminBoardRoleFilter[roleTitle]
    end
    
    return true
end

function VandraBoardConfiguration:SetRoleVisibility(roleTitle, visible)
    if type(visible) ~= "boolean" then
        return false
    end
    
    self.RoleFilter[roleTitle] = visible
    return true
end

function VandraBoardConfiguration:GetAllRoleSettings()
    return self.RoleFilter
end

return VandraBoardConfiguration

