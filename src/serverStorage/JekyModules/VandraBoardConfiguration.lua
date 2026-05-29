-- ServerStorage/JekyModules/VandraBoardConfiguration
local VandraBoardConfiguration = {}

-- FILTER UNTUK SUMMIT LEADERBOARD (Server & Global)
VandraBoardConfiguration.SummitRoleFilter = {
	Owner = true, Developer = true, HeadAdmin = true,
	Admin = true, Moderator = true, Streamer = true, Community = true,
}

-- FILTER UNTUK SPEEDRUN LEADERBOARD
VandraBoardConfiguration.SpeedRunRoleFilter = {
	Owner = true, Developer = true, HeadAdmin = true,
	Admin = true, Moderator = true, Streamer = true, Community = true,
}

-- FILTER UNTUK ADMIN BOARD (ROLE SHOWCASE)
VandraBoardConfiguration.AdminBoardRoleFilter = {
	Owner = true, Developer = true, HeadAdmin = true,
	Admin = true, Moderator = true, Streamer = false, Community = false,
}

function VandraBoardConfiguration:CanShowOnSummitLeaderboard(roleTitle)
	if not roleTitle or roleTitle == "" then return true end
	if self.SummitRoleFilter[roleTitle] ~= nil then
		return self.SummitRoleFilter[roleTitle]
	end
	return true
end

function VandraBoardConfiguration:CanShowOnSpeedRunLeaderboard(roleTitle)
	if not roleTitle or roleTitle == "" then return true end
	if self.SpeedRunRoleFilter[roleTitle] ~= nil then
		return self.SpeedRunRoleFilter[roleTitle]
	end
	return true
end

function VandraBoardConfiguration:CanShowOnAdminBoard(roleTitle)
	if not roleTitle or roleTitle == "" then return true end
	if self.AdminBoardRoleFilter[roleTitle] ~= nil then
		return self.AdminBoardRoleFilter[roleTitle]
	end
	return true
end

-- PERBAIKAN: Fungsi sekarang spesifik mau mengubah board yang mana
function VandraBoardConfiguration:SetRoleVisibility(boardType, roleTitle, visible)
	if type(visible) ~= "boolean" then return false end
	
	if boardType == "Summit" then
		self.SummitRoleFilter[roleTitle] = visible
	elseif boardType == "SpeedRun" then
		self.SpeedRunRoleFilter[roleTitle] = visible
	elseif boardType == "AdminBoard" then
		self.AdminBoardRoleFilter[roleTitle] = visible
	else
		return false
	end
	return true
end

-- PERBAIKAN: Mengembalikan semua settingan
function VandraBoardConfiguration:GetAllRoleSettings()
	return {
		Summit = self.SummitRoleFilter,
		SpeedRun = self.SpeedRunRoleFilter,
		AdminBoard = self.AdminBoardRoleFilter
	}
end

return VandraBoardConfiguration