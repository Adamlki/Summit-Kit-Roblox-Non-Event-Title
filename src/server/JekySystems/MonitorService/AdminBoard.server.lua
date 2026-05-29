-- ServerScriptService / VandraAdminBoard
-- Requires: VandraTitle, VandraBoardConfiguration in ServerStorage/VandraModules

local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local HttpService       = game:GetService("HttpService")

local Modules           = ServerStorage:WaitForChild("VandraModules")
local VandraTitle       = require(Modules:WaitForChild("VandraTitle"))
local BoardConfig       = require(Modules:WaitForChild("VandraBoardConfiguration"))

-- ============================================================
-- PATH
-- ============================================================
local Board = workspace
:WaitForChild("AllPartSummitkitVandra")
:WaitForChild("LeaderBoard")
:WaitForChild("AdminBoard")
:WaitForChild("Board")

local SurfaceGui      = Board:WaitForChild("SurfaceGui")
local ScrollingFrame  = SurfaceGui:WaitForChild("ScrollingFrame")
local Template        = ScrollingFrame:WaitForChild("Frame")

Template.Visible = false

-- ============================================================
-- HELPERS
-- ============================================================
local function safeGetUserId(username)
    if not username or username == "" then return nil end
    local ok, uid = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    return ok and uid or nil
end

local function safeGetUsername(userId)
    local ok, name = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)
    return ok and name or tostring(userId)
end

local function fetchDisplayName(userId)
    local ok, result = pcall(function()
        local json = HttpService:GetAsync(
        "https://users.roblox.com/v1/users/" .. tostring(userId),
        true
        )
        local data = HttpService:JSONDecode(json)
        return data.displayName ~= "" and data.displayName or data.name
    end)
    if ok and result then return result end
    return safeGetUsername(userId)
end

local function fetchThumbnail(userId)
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(
        userId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size100x100
        )
    end)
    return ok and url or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function getOnlinePlayer(userId)
    return Players:GetPlayerByUserId(userId)
end

-- ============================================================
-- BUILD ENTRY LIST (deduped by userId, filtered by AdminBoard)
-- ============================================================
local entries = {}      -- { roleName, userId, cachedDisplay, cachedThumb }
local userIdToEntry = {} -- userId -> entry (for quick lookup)

for _, roleName in ipairs(VandraTitle.RoleOrder) do
    if BoardConfig:CanShowOnAdminBoard(roleName) then
        local rule = VandraTitle.RoleRules[roleName]
        if rule then
            local seen = {}
            
            -- Resolve from Usernames list
            for _, username in ipairs(rule.Usernames or {}) do
                if username and username ~= "" then
                    local uid = safeGetUserId(username)
                    if uid and not seen[uid] then
                        seen[uid] = true
                        local dn    = fetchDisplayName(uid)
                        local thumb = fetchThumbnail(uid)
                        local entry = {
                        roleName     = roleName,
                        userId       = uid,
                        cachedDisplay = dn,
                        cachedThumb  = thumb,
                        }
                        table.insert(entries, entry)
                        userIdToEntry[uid] = entry
                    end
                end
            end
            
            -- Resolve from UserIds list
            for _, uid in ipairs(rule.UserIds or {}) do
                if uid and uid ~= 0 and not seen[uid] then
                    seen[uid] = true
                    local dn    = fetchDisplayName(uid)
                    local thumb = fetchThumbnail(uid)
                    local entry = {
                    roleName     = roleName,
                    userId       = uid,
                    cachedDisplay = dn,
                    cachedThumb  = thumb,
                    }
                    table.insert(entries, entry)
                    userIdToEntry[uid] = entry
                end
            end
        end
    end
end

-- ============================================================
-- FRAME MANAGEMENT
-- ============================================================
local userIdToFrame = {}   -- userId -> cloned Frame

local COLOR_ONLINE  = Color3.fromRGB(0,  200, 0)
local COLOR_OFFLINE = Color3.fromRGB(200, 0,  0)

local function setOnlineIndicator(frame, online)
    local idx = frame:FindFirstChild("Index")
    if idx then
        idx.BackgroundColor3 = online and COLOR_ONLINE or COLOR_OFFLINE
    end
end

local function buildFrame(entry, order)
    local frame = Template:Clone()
    frame.Name    = "AdminEntry_" .. entry.userId
    frame.Visible = true
    frame.LayoutOrder = order
    
    -- Role label
    local roleLabel = frame:FindFirstChild("Role")
    if roleLabel then
        roleLabel.Text = VandraTitle.GetRoleDisplayText(entry.roleName)
        local col = VandraTitle.GetRoleColor(entry.roleName)
        if col then roleLabel.TextColor3 = col end
    end
    
    -- UserName label — prefer live DisplayName if online
    local userLabel = frame:FindFirstChild("UserName")
    if userLabel then
        local live = getOnlinePlayer(entry.userId)
        userLabel.Text = live and live.DisplayName or entry.cachedDisplay
    end
    
    -- Headshot
    local imgLabel = frame:FindFirstChild("ImageLabel")
    if imgLabel then
        imgLabel.Image = entry.cachedThumb
    end
    
    -- Online indicator
    setOnlineIndicator(frame, getOnlinePlayer(entry.userId) ~= nil)
    
    frame.Parent = ScrollingFrame
    return frame
end

-- ============================================================
-- POPULATE BOARD
-- ============================================================

-- Destroy any stale clones (anything visible that isn't the hidden template)
for _, child in ipairs(ScrollingFrame:GetChildren()) do
    if child:IsA("Frame") and child ~= Template then
        child:Destroy()
    end
end

for i, entry in ipairs(entries) do
    local frame = buildFrame(entry, i)
    userIdToFrame[entry.userId] = frame
end

-- ============================================================
-- CANVAS AUTO-RESIZE
-- ============================================================
local listLayout = ScrollingFrame:FindFirstChildOfClass("UIListLayout")
if listLayout then
    local function refreshCanvas()
        ScrollingFrame.CanvasSize = UDim2.new(
        0, 0,
        0, listLayout.AbsoluteContentSize.Y
        )
    end
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)
    refreshCanvas()
end

-- ============================================================
-- REAL-TIME ONLINE / OFFLINE UPDATES
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    local frame = userIdToFrame[player.UserId]
    if not frame then return end
    
    -- Update indicator
    setOnlineIndicator(frame, true)
    
    -- Refresh DisplayName with live value
    local userLabel = frame:FindFirstChild("UserName")
    if userLabel then
        userLabel.Text = player.DisplayName
    end
    
    -- Refresh headshot in case it changed
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
            )
        end)
        local imgLabel = frame:FindFirstChild("ImageLabel")
        if imgLabel and ok then
            imgLabel.Image = url
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    local frame = userIdToFrame[player.UserId]
    if not frame then return end
    -- Small defer so Players service fully processes the removal
    task.defer(function()
        setOnlineIndicator(frame, false)
    end)
end)

