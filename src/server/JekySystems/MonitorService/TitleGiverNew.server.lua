local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local titleStore = DSS:GetDataStore("TitleStore_V3_Final")
local ApplyEvent = RS:FindFirstChild("ApplyCustomTitle") or Instance.new("RemoteEvent")
ApplyEvent.Name = "ApplyCustomTitle"
ApplyEvent.Parent = RS

local TitleGiver = RS:WaitForChild("TitleGiver")

-- Memanggil module JekyConfig untuk cek akses Admin
local JekyConfig = require(ServerStorage:WaitForChild("JekyModules"):WaitForChild("JekyConfig"))
local PRESETS = {
	{Colors = {Color3.fromRGB(0, 255, 255), Color3.fromRGB(180, 0, 255), Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 105, 180)}},
	{Colors = {Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0)}},
	{Colors = {Color3.fromRGB(135, 206, 250), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 192, 203)}},
	{Colors = {Color3.fromRGB(138, 43, 226), Color3.fromRGB(255, 20, 147), Color3.fromRGB(0, 255, 255)}},
	{Colors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 69, 0)}}
}

local SOLIDS = {
	Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 215, 0), Color3.fromRGB(0, 100, 255), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 105, 180)
}

local ANIMS = {"Gradient360", "LeftRight", "Diagonal", "Wave", "Pulse"}

local titleCache = {}

local function clearAnim(lbl)
	if not lbl then return end
	lbl:SetAttribute("TitleAnimType", nil)
	CollectionService:RemoveTag(lbl, "AnimatedTitleLabel")
	
	if lbl.Parent then
		for _, g in pairs(lbl:GetChildren()) do
			if g:IsA("UIGradient") then
				pcall(function() g:Destroy() end)
			end
		end
	end
end

local function buildSeq(colors)
	local kp = {}
	local n = #colors
	for i, c in ipairs(colors) do
		table.insert(kp, ColorSequenceKeypoint.new((i - 1) / math.max(1, n - 1), c))
	end
	return ColorSequence.new(kp)
end

local function applyAnim(lbl, animType, colors)
	if not lbl or not lbl.Parent then return end
	clearAnim(lbl)

	local grad = Instance.new("UIGradient")
	grad.Color = buildSeq(colors)
	grad.Parent = lbl

	lbl:SetAttribute("TitleAnimType", animType)
	CollectionService:AddTag(lbl, "AnimatedTitleLabel")
end

local function applySolid(lbl, color)
	if not lbl or not lbl.Parent then return end
	clearAnim(lbl)
	pcall(function()
		lbl.TextColor3 = color
	end)
end

local function safeSave(id, data)
	pcall(function()
		titleStore:SetAsync(id, data)
	end)
	titleCache[id] = data
end

local function loadTitle(id)
	if titleCache[id] then return titleCache[id] end
	local ok, res = pcall(function()
		return titleStore:GetAsync(id)
	end)
	if ok and res then
		titleCache[id] = res
		return res
	end
	return {}
end

local function applyTitleToLabel(lbl, data, lineIdx)
	if not lbl then return end

	pcall(function()
		local txt = data["T" .. lineIdx] or ""
		lbl.Text = txt
		clearAnim(lbl)

		local mode = data["M" .. lineIdx] or "PRESET"
		if mode == "PRESET" then
			local presetIdx = data["P" .. lineIdx] or 1
			local animIdx = data["A" .. lineIdx] or 1
			local preset = PRESETS[presetIdx]
			if preset then
				lbl.TextColor3 = Color3.new(1, 1, 1)
				task.wait(0.05)
				applyAnim(lbl, ANIMS[animIdx], preset.Colors)
			end
		else
			local solidIdx = data["S" .. lineIdx] or 1
			applySolid(lbl, SOLIDS[solidIdx])
		end
	end)
end

local function applyTitle(player, data)
	if not player or not data then return end
	local char = player.Character or player.CharacterAdded:Wait()
	local head = char:WaitForChild("Head", 5)
	if not head then return end

	for _, old in pairs(head:GetChildren()) do
		if old and (old.Name == "BillboardGui1" or old.Name == "BillboardGui2") then
			pcall(function() old:Destroy() end)
		end
	end

	local bb1 = TitleGiver:FindFirstChild("BillboardGui1")
	local bb2 = TitleGiver:FindFirstChild("BillboardGui2")

	if bb1 then
		local clone1 = bb1:Clone()
		clone1.Parent = head
		clone1.Adornee = head

		for i = 1, 5 do
			local holder = clone1:FindFirstChild("NameHolder")
			if holder then
				local frame = holder:FindFirstChild("Frame" .. i)
				if frame then
					local lbl = frame:FindFirstChild("TextLabel")
					if lbl then
						applyTitleToLabel(lbl, data, i)
					end
				end
			end
		end
	end

	if bb2 then
		local clone2 = bb2:Clone()
		clone2.Parent = head
		clone2.Adornee = head

		for i = 1, 5 do
			local lineIdx = i + 5
			local holder = clone2:FindFirstChild("NameHolder")
			if holder then
				local frame = holder:FindFirstChild("Frame" .. i)
				if frame then
					local lbl = frame:FindFirstChild("TextLabel")
					if lbl then
						applyTitleToLabel(lbl, data, lineIdx)
					end
				end
			end
		end
	end
end

ApplyEvent.OnServerEvent:Connect(function(sender, data)
	if type(data) ~= "table" then return end

	if data.RequestData then
		local target = Players:FindFirstChild(data.TargetName) or sender
		local d = loadTitle(target.UserId)
		ApplyEvent:FireClient(sender, {LoadedData = d, Target = target.Name})
		return
	end

	local target = Players:FindFirstChild(data.Target) or sender

	-- PERBAIKAN: Validasi keamanan supaya exploiter tidak bisa ubah Title orang lain
	if target ~= sender then
		local senderRole = sender:GetAttribute("RoleTitle")
		if not JekyConfig:HasCommandAccess(senderRole, "_AddRole") then
			warn("Exploit terdeteksi: " .. sender.Name .. " mencoba memodifikasi title milik " .. target.Name)
			return
		end
	end

	if data.ClearLine then
		local idx = data.ClearLine
		local d = loadTitle(target.UserId)
		d["T" .. idx] = ""
		d["M" .. idx] = "PRESET"
		d["P" .. idx] = 1
		d["A" .. idx] = 1
		d["S" .. idx] = 1
		safeSave(target.UserId, d)
		applyTitle(target, d)
		return
	end

	local existing = loadTitle(target.UserId)
	for i = 1, 10 do
		if data["T" .. i] ~= nil then existing["T" .. i] = data["T" .. i] end
		if data["M" .. i] ~= nil then existing["M" .. i] = data["M" .. i] end
		if data["P" .. i] ~= nil then existing["P" .. i] = data["P" .. i] end
		if data["A" .. i] ~= nil then existing["A" .. i] = data["A" .. i] end
		if data["S" .. i] ~= nil then existing["S" .. i] = data["S" .. i] end
	end
	safeSave(target.UserId, existing)
	applyTitle(target, existing)
end)

local function autoLoad(p)
	local d = loadTitle(p.UserId)
	if d and next(d) then
		applyTitle(p, d)
	end
end

-- PERBAIKAN: Menghapus forceAttachTitle yang bikin CPU lag parah
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		autoLoad(p)
	end)

	if p.Character then
		task.wait(0.5)
		autoLoad(p)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		autoLoad(p)
	end

	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		autoLoad(p)
	end)
end

game:BindToClose(function()
	for id, d in pairs(titleCache) do
		safeSave(id, d)
	end
end)