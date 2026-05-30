-- StarterPlayerScripts/SpeedrunBoardClient.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CONFIG = {
	LEADERBOARD_FOLDER_PATH = "AllPartSummitkitJeky/SpeedRun",
	MAX_DISPLAY_ENTRIES = 10,
	GLOBAL_UPDATE_INTERVAL = 60
}

local JekyEvents = ReplicatedStorage:WaitForChild("JekyEvents")
local SR_SyncBoard = JekyEvents:WaitForChild("SR_SyncBoard")

local boards = {}
local GlobalLeaderboard = {}
local nextUpdateIn = CONFIG.GLOBAL_UPDATE_INTERVAL

local function findLeaderboards()
	local lbs = {}
	local path = string.split(CONFIG.LEADERBOARD_FOLDER_PATH, "/")
	local cur = workspace
	for _, f in ipairs(path) do 
		cur = cur:FindFirstChild(f)
		if not cur then return {} end
	end
	for _, model in ipairs(cur:GetChildren()) do
		if not model:IsA("Model") then continue end
		if not string.find(string.lower(model.Name), "speedrun") then continue end
		local board = model:FindFirstChild("Board")
		local detik = model:FindFirstChild("Detik")
		if not (board and detik) then continue end
		local bsg = board:FindFirstChild("SurfaceGui")
		local dsg = detik:FindFirstChild("SurfaceGui")
		if not (bsg and dsg) then continue end
		table.insert(lbs, {BoardSurfaceGui = bsg, DetikSurfaceGui = dsg})
	end
	return lbs
end

local function formatTimeShort(s)
	if not s or s == 0 then return "N/A" end
	local m = math.floor(s / 60)
	local sec = math.floor(s % 60)
	local ms = math.floor((s % 1) * 1000)
	return m > 0 and ("%d:%02d.%03d"):format(m, sec, ms) or ("%d.%03d"):format(sec, ms)
end

local function updateLeaderboardUI(lb)
	local init = lb.BoardSurfaceGui:FindFirstChild("Init")
	if not init then return end
	
	for i = 1, CONFIG.MAX_DISPLAY_ENTRIES do
		local tf = init:FindFirstChild("Top"..i)
		if not tf then continue end
		local ul = tf:FindFirstChild("Username")
		local tl = tf:FindFirstChild("Total")
		local il = tf:FindFirstChild("ImageLabel")
		if not (ul and tl) then continue end
		
		local e = GlobalLeaderboard[i]
		if e then
			local name = e.Username or "Player_"..e.UserId
			ul.Text = i..". "..name
			tl.Text = "🏃 "..formatTimeShort(e.BestTime)
			if il and il:IsA("ImageLabel") and e.UserId then
				il.Image = "rbxthumb://type=AvatarHeadShot&id="..e.UserId.."&w=150&h=150"
			end
		else
			ul.Text = i..". ---"
			tl.Text = "🏃 --:--.---"
			if il and il:IsA("ImageLabel") then il.Image = "" end
		end
	end
end

local function updateAllUI()
	for _, lb in ipairs(boards) do
		updateLeaderboardUI(lb)
	end
end

local function updateTimerUI()
	local t = math.max(0, math.floor(nextUpdateIn))
	local text = t > 0 and ("Update in "..t.." second"..(t ~= 1 and "s" or "")) or "Updating..."
	
	for _, lb in ipairs(boards) do
		local dl = lb.DetikSurfaceGui and lb.DetikSurfaceGui:FindFirstChild("DetikLabel")
		if dl then
			dl.Text = text
		end
	end
end

SR_SyncBoard.OnClientEvent:Connect(function(action, data)
	if action == "UpdateBoard" then
		GlobalLeaderboard = data
		nextUpdateIn = CONFIG.GLOBAL_UPDATE_INTERVAL
		updateAllUI()
		updateTimerUI()
	end
end)

-- Main Initialization
task.spawn(function()
	-- Tunggu folder dan SurfaceGui selesai dimuat
	task.wait(5)
	boards = findLeaderboards()
	
	-- Countdown Timer lokal
	while true do
		task.wait(1)
		nextUpdateIn = nextUpdateIn - 1
		if nextUpdateIn < 0 then
			nextUpdateIn = 0
		end
		updateTimerUI()
	end
end)
