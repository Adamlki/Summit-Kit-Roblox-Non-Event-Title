-- ============================================================
-- VANDRA ADMIN PANEL  |  LocalScript
-- Lokasi : StarterGui > ListGui (ScreenGui) > AdminPanel
-- Layout : 500×300 | Col1: Nav | Col2: Players | Col3: Content
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP        = Players.LocalPlayer
local screenGui = script.Parent

-- UIScale
local uiScale = screenGui:FindFirstChildOfClass("UIScale")
if not uiScale then
	uiScale = Instance.new("UIScale")
	uiScale.Parent = screenGui
end

local function updateScale()
	local cam = workspace.CurrentCamera; if not cam then return end
	local vp  = cam.ViewportSize
	local s   = math.min(vp.X / 280, vp.Y / 540)
	if vp.X < 600                          then s = s * 1.05 end
	if vp.X >= 600 and vp.X < 900          then s = s * 0.95 end
	if vp.X >= 900                          then s = s * 0.85 end
	if vp.X > vp.Y and vp.X < 900          then s = s * 1.02 end
	uiScale.Scale = math.clamp(s, 0.85, 1.6)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- Remotes
local VE        = ReplicatedStorage:WaitForChild("VandraEvents", 15)
local CMD_RE    = VE and VE:WaitForChild("AdminPanel_Command", 10)
local RESULT_RE = VE and VE:WaitForChild("AdminPanel_Result",  10)

local function send(name, args)
	if CMD_RE then CMD_RE:FireServer(name, args or {}) end
end

-- Client access table (UI-only, server revalidates everything)
local CA = {
	Owner     = {_Add=1,_R=1,_Value=1,_Gift=1,_DVip=1,_AddVerified=1,_DVerified=1,_AddRole=1,_RemoveRole=1,_RSpeed=1},
	Developer = {_Add=1,_R=1,_Value=1,_Gift=1,_DVip=1,_AddVerified=1,_DVerified=1,_AddRole=1,_RemoveRole=1,_RSpeed=1},
	HeadAdmin = {_Add=1,_R=1,_Value=0,_Gift=1,_DVip=1,_AddVerified=1,_DVerified=1,_AddRole=0,_RemoveRole=0,_RSpeed=1},
	Admin={}, Moderator={},
}
local ALLOWED = {Owner=1,Developer=1,HeadAdmin=1,Admin=1,Moderator=1}

local function getRole()  return LP:GetAttribute("RoleTitle") or "" end
local function canOpen()  return ALLOWED[getRole()] == 1 end
local function acc(cmd)   local t = CA[getRole()]; return t and t[cmd] == 1 end

-- ============================================================
-- PALETTE
-- ============================================================
local BG      = Color3.fromRGB(10,  10,  10)
local COL1    = Color3.fromRGB(14,  14,  14)
local COL2    = Color3.fromRGB(16,  16,  16)
local COL3    = Color3.fromRGB(18,  18,  18)
local RED     = Color3.fromRGB(185, 20,  20)
local RED_DIM = Color3.fromRGB(55,  12,  12)
local TITLE   = Color3.fromRGB(130, 10,  10)
local NAV_ON  = Color3.fromRGB(170, 18,  18)
local NAV_OFF = Color3.fromRGB(24,  24,  24)
local WHITE   = Color3.fromRGB(225, 225, 225)
local DIM     = Color3.fromRGB(110, 110, 110)
local HINT    = Color3.fromRGB(255, 160, 160)
local INP_BG  = Color3.fromRGB(10,  10,  10)
local ROW_ME  = Color3.fromRGB(36,  12,  12)
local ROW_A   = Color3.fromRGB(16,  16,  16)
local ROW_B   = Color3.fromRGB(20,  20,  20)
local SEL_C   = Color3.fromRGB(190, 22,  22)
local G_C     = Color3.fromRGB(16,  95,  38)
local R_C     = Color3.fromRGB(110, 16,  16)
local B_C     = Color3.fromRGB(16,  58,  130)
local A_C     = Color3.fromRGB(118, 68,  8)
local GR_C    = Color3.fromRGB(34,  34,  38)
local OK_C    = Color3.fromRGB(45,  195, 65)
local ERR_C   = Color3.fromRGB(210, 45,  45)

-- ============================================================
-- UI HELPERS
-- ============================================================
local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 5)
	c.Parent = p
end

local function stroke(p, t, c, tr)
	local s = Instance.new("UIStroke")
	s.Thickness = t or 2; s.Color = c or RED; s.Transparency = tr or 0
	s.Parent = p
end

local function pad(p, h, v)
	local u = Instance.new("UIPadding")
	u.PaddingLeft = UDim.new(0,h); u.PaddingRight  = UDim.new(0,h)
	u.PaddingTop  = UDim.new(0,v); u.PaddingBottom = UDim.new(0,v)
	u.Parent = p
end

local function vlist(p, sp)
	local l = Instance.new("UIListLayout")
	l.SortOrder     = Enum.SortOrder.LayoutOrder
	l.FillDirection = Enum.FillDirection.Vertical
	l.Padding       = UDim.new(0, sp or 2)
	l.Parent = p
end

local function hlist(p, sp)
	local l = Instance.new("UIListLayout")
	l.SortOrder     = Enum.SortOrder.LayoutOrder
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding       = UDim.new(0, sp or 2)
	l.Parent = p
end

local function frm(parent, sz, pos, bg, tr)
	local f = Instance.new("Frame")
	f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
	f.BackgroundColor3 = bg or COL3; f.BackgroundTransparency = tr or 0
	f.BorderSizePixel  = 0; f.Parent = parent
	return f
end

local function lbl(parent, txt, sz, pos, fs, col, font, xA)
	local l = Instance.new("TextLabel")
	l.Size = sz; l.Position = pos or UDim2.new(0,0,0,0)
	l.Text = txt or ""; l.TextSize = fs or 11; l.TextColor3 = col or WHITE
	l.Font = font or Enum.Font.Gotham
	l.BackgroundTransparency = 1; l.BorderSizePixel = 0
	l.TextXAlignment = xA or Enum.TextXAlignment.Left
	l.TextWrapped    = true; l.Parent = parent
	return l
end

local function btn(parent, txt, sz, pos, bg, tc, fs)
	local b = Instance.new("TextButton")
	b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
	b.Text = txt or ""; b.TextSize = fs or 10; b.TextColor3 = tc or WHITE
	b.Font = Enum.Font.GothamBold; b.BackgroundColor3 = bg or GR_C
	b.BorderSizePixel = 0; b.AutoButtonColor = false; b.Parent = parent
	corner(b, 4)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(.07), {BackgroundTransparency=.4}):Play() end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(.07), {BackgroundTransparency=0}):Play() end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(b, TweenInfo.new(.04), {BackgroundTransparency=.6}):Play() end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(b, TweenInfo.new(.07), {BackgroundTransparency=0}):Play() end)
	return b
end

local function inp(parent, ph, sz, pos)
	local b = Instance.new("TextBox")
	b.Size = sz; b.Position = pos or UDim2.new(0,0,0,0)
	b.PlaceholderText = ph or ""; b.PlaceholderColor3 = DIM
	b.Text = ""; b.TextSize = 10; b.TextColor3 = WHITE; b.Font = Enum.Font.Code
	b.BackgroundColor3 = INP_BG; b.BorderSizePixel = 0
	b.ClearTextOnFocus = false; b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = parent
	corner(b, 3)
	stroke(b, 1, Color3.fromRGB(50,50,50), 0)
	pad(b, 5, 3)
	return b
end

local function statL(parent, pos)
	return lbl(parent, "", UDim2.new(1,0,0,12), pos, 9, DIM, Enum.Font.Code)
end

local function flash(l, msg, isOk)
	if not l or not l.Parent then return end
	l.Text = msg; l.TextColor3 = isOk and OK_C or ERR_C; l.TextTransparency = 0
	task.delay(4, function()
		if not l or not l.Parent then return end
		TweenService:Create(l, TweenInfo.new(.4), {TextTransparency=1}):Play()
		task.wait(.45)
		if l and l.Parent then l.Text=""; l.TextTransparency=0; l.TextColor3=DIM end
	end)
end

-- ============================================================
-- PANEL STATE
-- ============================================================
local panelOpen = false
local panel     = nil

-- ============================================================
-- BUILD PANEL
-- ============================================================
local function build()
	if panel then panel:Destroy() end

	-- ROOT  500 × 300
	panel = frm(screenGui,
		UDim2.new(0,500,0,300), UDim2.new(.5,-250,.5,-150), BG, .08)
	panel.Name = "VandraAdminPanel"
	panel.ZIndex = 30; panel.Visible = false
	panel.ClipsDescendants = true
	corner(panel, 7); stroke(panel, 2, RED, 0)

	-- ── TITLE BAR  500 × 24 ───────────────────────────────────
	local tbar = frm(panel, UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), TITLE, .12)
	corner(tbar, 7); tbar.ZIndex = 31

	lbl(tbar, "FACILE ADMIN PANEL",
		UDim2.new(.42,0,1,0), UDim2.new(0,8,0,0), 11, HINT, Enum.Font.GothamBold)

	local roleTag = lbl(tbar, "["..getRole().."]",
		UDim2.new(.2,0,1,0), UDim2.new(.43,0,0,0), 9, DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	roleTag.ZIndex = 32

	local topStat = lbl(tbar, "",
		UDim2.new(.24,0,1,0), UDim2.new(.64,0,0,0), 9, DIM, Enum.Font.Code, Enum.TextXAlignment.Right)
	topStat.ZIndex = 32

	local xBtn = btn(tbar, "X",
		UDim2.new(0,22,0,18), UDim2.new(1,-24,0,3), R_C, WHITE, 11)
	xBtn.ZIndex = 32

	-- drag
	local dragging, ds, sp = false, nil, nil
	tbar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; ds = i.Position; sp = panel.Position end end)
	tbar.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false end end)
	RunService.Heartbeat:Connect(function()
		if not dragging then return end
		local m = UIS:GetMouseLocation()
		panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset+(m.X-ds.X),
			sp.Y.Scale, sp.Y.Offset+(m.Y-ds.Y))
	end)

	if RESULT_RE then
		RESULT_RE.OnClientEvent:Connect(function(ok, msg)
			flash(topStat, (ok and "[OK] " or "[ERR] ")..tostring(msg or ""), ok)
		end)
	end

	-- ── BODY  500 × 274 ───────────────────────────────────────
	local BODY_Y  = 26
	local BH      = 300 - BODY_Y   -- 274
	local C1W     = 88             -- Nav column
	local C2W     = 106            -- Player column
	local C3W     = 500 - C1W - C2W - 12  -- Content column = 294

	-- ════════════════════════════════════════════════════════
	-- COL 1  |  Nav command list  |  x=2, w=88
	-- ════════════════════════════════════════════════════════
	local col1 = frm(panel, UDim2.new(0,C1W,0,BH), UDim2.new(0,2,0,BODY_Y), COL1, .05)
	corner(col1, 5); stroke(col1, 1, RED, .6)

	lbl(col1, "COMMANDS",
		UDim2.new(1,0,0,15), UDim2.new(0,0,0,0), 8, HINT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

	local navScroll = Instance.new("ScrollingFrame")
	navScroll.Size = UDim2.new(1,-2, 1,-17)
	navScroll.Position = UDim2.new(0,1, 0,16)
	navScroll.BackgroundTransparency = 1; navScroll.BorderSizePixel = 0
	navScroll.ScrollBarThickness = 2; navScroll.ScrollBarImageColor3 = RED
	navScroll.CanvasSize = UDim2.new(0,0,0,0)
	navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	navScroll.Parent = col1
	vlist(navScroll, 2)
	pad(navScroll, 3, 2)

	-- ════════════════════════════════════════════════════════
	-- COL 2  |  Player ScrollingFrame  |  x=92, w=106
	-- ════════════════════════════════════════════════════════
	local col2 = frm(panel, UDim2.new(0,C2W,0,BH), UDim2.new(0,C1W+4,0,BODY_Y), COL2, .05)
	corner(col2, 5); stroke(col2, 1, RED, .6)

	lbl(col2, "PLAYERS",
		UDim2.new(1,0,0,15), UDim2.new(0,0,0,0), 8, HINT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)

	local cntL = lbl(col2, "0 online",
		UDim2.new(1,0,0,11), UDim2.new(0,0,0,13), 8, DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)

	local pScroll = Instance.new("ScrollingFrame")
	pScroll.Size = UDim2.new(1,-2, 1,-26)
	pScroll.Position = UDim2.new(0,1, 0,25)
	pScroll.BackgroundTransparency = 1; pScroll.BorderSizePixel = 0
	pScroll.ScrollBarThickness = 2; pScroll.ScrollBarImageColor3 = RED
	pScroll.CanvasSize = UDim2.new(0,0,0,0)
	pScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pScroll.Parent = col2
	vlist(pScroll, 0)
	pad(pScroll, 2, 2)

	local selName = {v = ""}

	local function refreshPlayers()
		for _, c in ipairs(pScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		local list = {}
		table.insert(list, LP)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then table.insert(list, p) end
		end
		cntL.Text = #list .. " online"

		for idx, p in ipairs(list) do
			local isSelf = (p == LP)
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1,0,0,28)
			row.BackgroundColor3 = isSelf and ROW_ME or (idx%2==0 and ROW_B or ROW_A)
			row.BackgroundTransparency = .05
			row.BorderSizePixel = 0; row.Text = ""
			row.AutoButtonColor = false; row.LayoutOrder = idx
			row.Parent = pScroll

			-- 3px selection accent bar
			local ac = frm(row, UDim2.new(0,3,1,0), UDim2.new(0,0,0,0), SEL_C, 1)
			ac.Name = "Acc"

			-- avatar thumbnail
			local av = Instance.new("ImageLabel")
			av.Size = UDim2.new(0,20,0,20); av.Position = UDim2.new(0,4,.5,-10)
			av.BackgroundTransparency = 1; av.BorderSizePixel = 0
			av.Image = "rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=48&h=48"
			av.Parent = row; corner(av, 10)

			-- name
			local nL = lbl(row, p.Name,
				UDim2.new(1,-28,0,14), UDim2.new(0,26,0,2),
				10, isSelf and HINT or WHITE, Enum.Font.GothamBold)
			nL.TextTruncate = Enum.TextTruncate.AtEnd

			-- role
			local rL = lbl(row, p:GetAttribute("RoleTitle") or "",
				UDim2.new(1,-28,0,11), UDim2.new(0,26,0,15),
				8, DIM, Enum.Font.Gotham)
			rL.TextTruncate = Enum.TextTruncate.AtEnd
			p:GetAttributeChangedSignal("RoleTitle"):Connect(function()
				if rL and rL.Parent then rL.Text = p:GetAttribute("RoleTitle") or "" end
			end)

			-- hover / select behaviour
			row.MouseEnter:Connect(function()
				if selName.v ~= p.Name then
					TweenService:Create(row,TweenInfo.new(.06),{BackgroundTransparency=.45}):Play() end end)
			row.MouseLeave:Connect(function()
				if selName.v ~= p.Name then
					TweenService:Create(row,TweenInfo.new(.06),{BackgroundTransparency=.05}):Play() end end)
			row.MouseButton1Click:Connect(function()
				-- clear previous
				for _, c in ipairs(pScroll:GetChildren()) do
					if c:IsA("TextButton") then
						TweenService:Create(c,TweenInfo.new(.06),{BackgroundTransparency=.05}):Play()
						local a = c:FindFirstChild("Acc"); if a then a.BackgroundTransparency = 1 end
					end
				end
				selName.v = p.Name
				TweenService:Create(row,TweenInfo.new(.06),{BackgroundTransparency=.55}):Play()
				ac.BackgroundTransparency = 0
			end)
		end
	end

	Players.PlayerAdded:Connect(refreshPlayers)
	Players.PlayerRemoving:Connect(function()
		task.wait(.05); refreshPlayers()
		if not Players:FindFirstChild(selName.v) and selName.v ~= LP.Name then
			selName.v = "" end end)
	refreshPlayers()

	local function getSel() return selName.v end

	-- ════════════════════════════════════════════════════════
	-- COL 3  |  Content  |  x=202, w=294
	-- ════════════════════════════════════════════════════════
	local col3 = frm(panel, UDim2.new(0,C3W,0,BH), UDim2.new(0,C1W+C2W+8,0,BODY_Y), COL3, .05)
	corner(col3, 5); stroke(col3, 1, RED, .6)

	-- target strip (top of col3)
	local tstrip = frm(col3, UDim2.new(1,-6,0,15), UDim2.new(0,3,0,2), RED_DIM, .15)
	corner(tstrip, 3)
	local targetL = lbl(tstrip, "Target: (click a player)",
		UDim2.new(1,-6,1,0), UDim2.new(0,4,0,0), 9, HINT, Enum.Font.Code)
	RunService.Heartbeat:Connect(function()
		if targetL and targetL.Parent then
			local s = getSel()
			targetL.Text = s ~= "" and ("Target:  "..s) or "Target: (click a player)"
		end
	end)

	-- page area (below target strip)
	local PAGE_TOP = 19
	local PAGE_H   = BH - PAGE_TOP - 4

	local function mkPage()
		local p = frm(col3, UDim2.new(1,-6,0,PAGE_H), UDim2.new(0,3,0,PAGE_TOP), COL3, 1)
		p.Visible = false; p.ClipsDescendants = true
		return p
	end

	-- ── nav + page system ──────────────────────────────────
	local navEntries = {}
	local activeEntry = nil

	local function activateNav(e)
		for _, n in ipairs(navEntries) do
			n.page.Visible = false
			TweenService:Create(n.navBtn, TweenInfo.new(.1), {BackgroundColor3=NAV_OFF}):Play()
		end
		e.page.Visible = true
		TweenService:Create(e.navBtn, TweenInfo.new(.1), {BackgroundColor3=NAV_ON}):Play()
		activeEntry = e
	end

	local navOrder = 0
	local function addNav(label, guard)
		if guard and not acc(guard) then return nil end
		navOrder = navOrder + 1

		local nb = Instance.new("TextButton")
		nb.Size = UDim2.new(1,0,0,22)
		nb.BackgroundColor3 = NAV_OFF; nb.BorderSizePixel = 0
		nb.Text = label; nb.TextSize = 9
		nb.Font = Enum.Font.GothamBold; nb.TextColor3 = WHITE
		nb.AutoButtonColor = false
		nb.LayoutOrder = navOrder; nb.Parent = navScroll
		corner(nb, 3)
		local e = {navBtn=nb, page=mkPage()}
		table.insert(navEntries, e)
		nb.MouseButton1Click:Connect(function() activateNav(e) end)
		nb.MouseEnter:Connect(function()
			if activeEntry ~= e then
				TweenService:Create(nb,TweenInfo.new(.07),{BackgroundTransparency=.4}):Play() end end)
		nb.MouseLeave:Connect(function()
			if activeEntry ~= e then
				TweenService:Create(nb,TweenInfo.new(.07),{BackgroundTransparency=0}):Play() end end)
		return e.page
	end

	-- ── page content helpers ──────────────────────────────
	local function secHdr(page, txt)
		local h = frm(page, UDim2.new(1,0,0,15), UDim2.new(0,0,0,0), TITLE, .45)
		corner(h, 3)
		lbl(h, txt, UDim2.new(1,-6,1,0), UDim2.new(0,4,0,0), 9, HINT, Enum.Font.GothamBold)
	end

	local function inpRow(page, yOff, labelTxt, ph)
		lbl(page, labelTxt,
			UDim2.new(0,56,0,18), UDim2.new(0,0,0,yOff), 9, DIM, Enum.Font.Gotham)
		return inp(page, ph, UDim2.new(1,-60,0,18), UDim2.new(0,58,0,yOff))
	end

	local function btnRow(page, yOff, defs)
		local n  = #defs
		local bw = math.floor(100/n)
		local f  = frm(page, UDim2.new(1,0,0,22), UDim2.new(0,0,0,yOff), COL3, 1)
		for i, d in ipairs(defs) do
			local xPct = (i-1) * (bw/100)
			local b = btn(f, d[1],
				UDim2.new(bw/100, i<n and -2 or 0, 1,0),
				UDim2.new(xPct,   i>1 and 2  or 0, 0,0),
				d[2])
			b.TextSize = 9
			if d[3] then b.MouseButton1Click:Connect(d[3]) end
		end
	end

	local ROLES = {"Owner","Developer","HeadAdmin","Admin","Moderator","Streamer","Community"}
	local RLBL  = {Owner="OWN",Developer="DEV",HeadAdmin="HEAD",Admin="ADM",
		Moderator="MOD",Streamer="STR",Community="COM"}

	local function rolePicker(page, yOff)
		lbl(page,"Role:",UDim2.new(0,32,0,16),UDim2.new(0,0,0,yOff),9,DIM,Enum.Font.Gotham)
		local row = frm(page, UDim2.new(1,-36,0,16), UDim2.new(0,34,0,yOff), COL3, 1)
		hlist(row, 2)
		local sel = {v="Admin"}
		local btns = {}
		for _, rn in ipairs(ROLES) do
			local rb = Instance.new("TextButton")
			rb.AutomaticSize = Enum.AutomaticSize.X; rb.Size = UDim2.new(0,0,1,0)
			rb.Text = RLBL[rn]; rb.TextSize = 8; rb.Font = Enum.Font.GothamBold
			rb.TextColor3 = WHITE; rb.BorderSizePixel = 0; rb.AutoButtonColor = false
			rb.BackgroundColor3 = (rn=="Admin") and RED or GR_C
			rb.Parent = row; corner(rb,3); pad(rb,5,0)
			table.insert(btns, {btn=rb, name=rn})
			rb.MouseButton1Click:Connect(function()
				sel.v = rn
				for _, rd in ipairs(btns) do
					rd.btn.BackgroundColor3 = (rd.name==rn) and RED or GR_C end
			end)
		end
		return sel
	end

	local LOCS = {"BC","CP1","CP2","CP3","CP4","Summit","ApexSummit"}

	local function locChips(page, yOff, targetBox)
		local row = frm(page, UDim2.new(1,0,0,16), UDim2.new(0,0,0,yOff), COL3, 1)
		hlist(row, 2)
		for _, loc in ipairs(LOCS) do
			local lb = loc:gsub("ApexSummit","Apex"):gsub("Summit","Sum")
			local rb = Instance.new("TextButton")
			rb.AutomaticSize = Enum.AutomaticSize.X; rb.Size = UDim2.new(0,0,1,0)
			rb.Text = lb; rb.TextSize = 8; rb.Font = Enum.Font.GothamBold
			rb.TextColor3 = WHITE; rb.BorderSizePixel = 0; rb.AutoButtonColor = false
			rb.BackgroundColor3 = GR_C; rb.Parent = row; corner(rb,3); pad(rb,5,0)
			rb.MouseButton1Click:Connect(function()
				if targetBox then targetBox.Text = loc
				else send("_TeleportSelf",{loc}) end
			end)
			rb.MouseEnter:Connect(function()
				TweenService:Create(rb,TweenInfo.new(.06),{BackgroundTransparency=.4}):Play() end)
			rb.MouseLeave:Connect(function()
				TweenService:Create(rb,TweenInfo.new(.06),{BackgroundTransparency=0}):Play() end)
		end
	end

	-- ============================================================
	-- NAV PAGES
	-- ============================================================

	-- SUMMIT
	do
		if acc("_Add") or acc("_R") then
			local page = addNav("SUMMIT")
			secHdr(page,"Summit Management")
			local amtBox = inpRow(page, 18, "Amount:", "e.g. 50")
			local st = statL(page, UDim2.new(0,0,0,40))
			local defs = {}
			if acc("_Add") then table.insert(defs, {"Add Summit", G_C, function()
					local t=getSel(); if t=="" then flash(st,"No target.",false); return end
					local v=tonumber(amtBox.Text); if not v then flash(st,"Invalid amount.",false); return end
					send("_Add",{t,tostring(v)}); flash(st,"+"..v.." -> "..t,true)
				end}) end
			if acc("_R") then table.insert(defs, {"Reset Summit", R_C, function()
					local t=getSel(); if t=="" then flash(st,"No target.",false); return end
					send("_R",{t}); flash(st,"Reset -> "..t,true)
				end}) end
			btnRow(page, 54, defs)
		end
	end

	-- VIP
	do
		if acc("_Gift") or acc("_DVip") then
			local page = addNav("VIP")
			secHdr(page,"VIP Management")
			local st = statL(page, UDim2.new(0,0,0,20))
			local defs = {}
			if acc("_Gift") then table.insert(defs, {"Grant VIP", B_C, function()
					local t=getSel(); if t=="" then flash(st,"No target.",false); return end
					send("_Gift",{t}); flash(st,"Grant VIP -> "..t,true)
				end}) end
			if acc("_DVip") then table.insert(defs, {"Revoke VIP", R_C, function()
					local t=getSel(); if t=="" then flash(st,"No target.",false); return end
					send("_DVip",{t}); flash(st,"Revoke VIP -> "..t,true)
				end}) end
			btnRow(page, 34, defs)
		end
	end

	-- VERIFIED
	do
		if acc("_AddVerified") or acc("_DVerified") then
			local page = addNav("VERIFIED")
			secHdr(page,"Verified Management")
			local manBox = inpRow(page, 18, "Username:", "offline player...")
			local st = statL(page, UDim2.new(0,0,0,40))
			local function getT() local s=getSel(); return s~="" and s or manBox.Text end
			local defs = {}
			if acc("_AddVerified") then table.insert(defs, {"Add", G_C, function()
					local t=getT(); if t=="" then flash(st,"No target.",false); return end
					send("_AddVerified",{t}); flash(st,"Add Verified -> "..t,true)
				end}) end
			if acc("_DVerified") then table.insert(defs, {"Remove", R_C, function()
					local t=getT(); if t=="" then flash(st,"No target.",false); return end
					send("_DVerified",{t}); flash(st,"Remove Verified -> "..t,true)
				end}) end
			btnRow(page, 54, defs)
		end
	end

	-- ROLE
	do
		if acc("_AddRole") or acc("_RemoveRole") then
			local page = addNav("ROLE")
			secHdr(page,"Role Management")
			local selR = rolePicker(page, 18)
			local st = statL(page, UDim2.new(0,0,0,38))
			local defs = {}
			if acc("_AddRole") then table.insert(defs, {"Set Role", G_C, function()
					local t=getSel(); if t=="" then flash(st,"No target.",false); return end
					send("_AddRole",{t,selR.v}); flash(st,t.." -> "..selR.v,true)
				end}) end
			if acc("_RemoveRole") then table.insert(defs, {"Remove Role", R_C, function()
					local t=getSel(); if t=="" then flash(st,"No target.",false); return end
					send("_RemoveRole",{t}); flash(st,"Removed role: "..t,true)
				end}) end
			btnRow(page, 52, defs)
		end
	end

	-- SPEEDRUN
	do
		if acc("_RSpeed") then
			local page = addNav("SPEEDRUN")
			secHdr(page,"SpeedRun Reset")
			lbl(page,"Erases best time permanently.",
				UDim2.new(1,0,0,16),UDim2.new(0,0,0,18),9,DIM,Enum.Font.Gotham)
			local st = statL(page, UDim2.new(0,0,0,37))
			btnRow(page, 50, {{"Reset SpeedRun Record", R_C, function()
				local t=getSel(); if t=="" then flash(st,"No target.",false); return end
				send("_RSpeed",{t}); flash(st,"Reset SpeedRun -> "..t,true)
			end}})
		end
	end

	-- CONFIG
	do
		if acc("_Value") then
			local page   = addNav("CONFIG")
			secHdr(page,"Config Values")
			local sumBox = inpRow(page, 18, "Summit:",  "reward...")
			local apxBox = inpRow(page, 40, "Apex:",    "reward...")
			local st     = statL(page, UDim2.new(0,0,0,62))

			lbl(page,"Skip CP:",UDim2.new(0,46,0,16),UDim2.new(0,0,0,76),9,DIM,Enum.Font.Gotham)
			local skOn  = btn(page,"ON", UDim2.new(0,38,0,16),UDim2.new(0,48,0,76),G_C)
			local skOff = btn(page,"OFF",UDim2.new(0,38,0,16),UDim2.new(0,90,0,76),GR_C)
			skOn.TextSize=9; skOff.TextSize=9

			local aSm = btn(page,"Apply Summit",UDim2.new(.5,-1,0,18),UDim2.new(0,0,0,96),B_C)
			local aAp = btn(page,"Apply Apex",  UDim2.new(.5,-1,0,18),UDim2.new(.5,1,0,96),B_C)
			aSm.TextSize=9; aAp.TextSize=9

			aSm.MouseButton1Click:Connect(function()
				local v=tonumber(sumBox.Text); if not v or v<0 then flash(st,"Invalid.",false); return end
				send("_ValueSummit",{tostring(v)}); flash(st,"Summit reward = "..v,true) end)
			aAp.MouseButton1Click:Connect(function()
				local v=tonumber(apxBox.Text); if not v or v<0 then flash(st,"Invalid.",false); return end
				send("_ValueApex",{tostring(v)}); flash(st,"Apex reward = "..v,true) end)
			skOn.MouseButton1Click:Connect(function()
				skOn.BackgroundColor3=G_C; skOff.BackgroundColor3=GR_C
				send("_SkipMode",{true}); flash(st,"Skip = ON",true) end)
			skOff.MouseButton1Click:Connect(function()
				skOff.BackgroundColor3=R_C; skOn.BackgroundColor3=GR_C
				send("_SkipMode",{false}); flash(st,"Skip = OFF",true) end)
		end
	end

	-- TELEPORT
	do
		local page = addNav("TELEPORT")
		secHdr(page,"Teleport")

		-- self: quick chips
		lbl(page,"Self:",UDim2.new(0,28,0,14),UDim2.new(0,0,0,17),9,DIM,Enum.Font.Gotham)
		locChips(page, 17, nil)

		local selfInp = inpRow(page, 36, "Custom:", "BC / CP5 / Summit...")
		local goBtn   = btn(page,"Go",UDim2.new(1,0,0,16),UDim2.new(0,0,0,57),B_C)
		goBtn.TextSize = 9
		goBtn.MouseButton1Click:Connect(function()
			local l=selfInp.Text; if l=="" then return end
			send("_TeleportSelf",{l})
		end)

		-- divider
		frm(page, UDim2.new(1,0,0,1), UDim2.new(0,0,0,77), RED, .7)

		-- teleport player
		if acc("_Add") then
			lbl(page,"Player:",UDim2.new(0,38,0,14),UDim2.new(0,0,0,81),9,DIM,Enum.Font.Gotham)
			local tpInp = inp(page,"location...",UDim2.new(1,-42,0,16),UDim2.new(0,40,0,80))
			locChips(page, 99, tpInp)
			local tpSt  = statL(page, UDim2.new(0,0,0,118))
			local tpBtn = btn(page,"Teleport Player",UDim2.new(1,0,0,18),UDim2.new(0,0,0,132),A_C)
			tpBtn.TextSize=9
			tpBtn.MouseButton1Click:Connect(function()
				local t=getSel(); local l=tpInp.Text
				if t=="" then flash(tpSt,"No target.",false); return end
				if l=="" then flash(tpSt,"No location.",false); return end
				send("_TeleportPlayer",{t,l}); flash(tpSt,"TP "..t.." -> "..l,true)
			end)
		end
	end

	-- BROADCAST
	do
		local page   = addNav("BROADCAST")
		secHdr(page,"Broadcast Message")
		lbl(page,"Global = all servers   |   Server = this server",
			UDim2.new(1,0,0,14),UDim2.new(0,0,0,17),8,DIM,Enum.Font.Gotham)
		local msgBox = inp(page,"Message...",UDim2.new(1,0,0,42),UDim2.new(0,0,0,33))
		msgBox.MultiLine=true; msgBox.TextSize=10
		local st = statL(page, UDim2.new(0,0,0,79))
		btnRow(page, 93, {
			{"Send Global (_G)", R_C, function()
				local m=msgBox.Text; if m=="" then flash(st,"Empty.",false); return end
				send("_BroadcastG",{m}); msgBox.Text=""; flash(st,"Global: "..m:sub(1,40),true)
			end},
			{"Send Server (_S)", B_C, function()
				local m=msgBox.Text; if m=="" then flash(st,"Empty.",false); return end
				send("_BroadcastS",{m}); msgBox.Text=""; flash(st,"Server: "..m:sub(1,40),true)
			end},
		})
	end

	-- activate first visible nav
	if #navEntries > 0 then activateNav(navEntries[1]) end

	-- close button
	xBtn.MouseButton1Click:Connect(function()
		panelOpen = false
		TweenService:Create(panel,TweenInfo.new(.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
			{Size=UDim2.new(0,500,0,0),Position=UDim2.new(.5,-250,.5,0)}):Play()
		task.wait(.14)
		if panel and panel.Parent then
			panel.Visible=false
			panel.Size=UDim2.new(0,500,0,300)
			panel.Position=UDim2.new(.5,-250,.5,-150)
		end
	end)

	return panel
end

-- ============================================================
-- ADMIN BUTTON SETUP
-- ============================================================
local function setup()
	local aBtn = screenGui:FindFirstChild("AdminButton")
	if not aBtn then
		aBtn = Instance.new("TextButton"); aBtn.Name = "AdminButton"
		aBtn.Size = UDim2.new(0,82,0,26); aBtn.Position = UDim2.new(0,8,0,8)
		aBtn.BackgroundColor3 = Color3.fromRGB(130,12,12)
		aBtn.TextColor3 = HINT; aBtn.Text = "ADMIN"
		aBtn.TextSize = 11; aBtn.Font = Enum.Font.GothamBold
		aBtn.BorderSizePixel = 0; aBtn.ZIndex = 10; aBtn.Visible = false
		aBtn.Parent = screenGui; corner(aBtn,5); stroke(aBtn,2,RED,0)
	end

	local function sync()
		aBtn.Visible = canOpen()
	end
	sync()
	LP:GetAttributeChangedSignal("RoleTitle"):Connect(sync)

	-- close panel when another ListGui button is clicked
	local function watch(c)
		if c:IsA("TextButton") and c ~= aBtn and c.Name ~= "VandraAdminPanel" then
			c.MouseButton1Click:Connect(function()
				if panelOpen and panel and panel.Parent then
					panel.Visible=false; panelOpen=false end end) end end
	for _, c in ipairs(screenGui:GetChildren()) do watch(c) end
	screenGui.ChildAdded:Connect(watch)

	aBtn.MouseButton1Click:Connect(function()
		if not canOpen() then return end
		if not panel or not panel.Parent then build() end
		panelOpen = not panelOpen
		if panelOpen then
			panel.Size=UDim2.new(0,500,0,0); panel.Position=UDim2.new(.5,-250,.5,0)
			panel.Visible=true
			TweenService:Create(panel,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
				{Size=UDim2.new(0,500,0,300),Position=UDim2.new(.5,-250,.5,-150)}):Play()
		else
			TweenService:Create(panel,TweenInfo.new(.13,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
				{Size=UDim2.new(0,500,0,0),Position=UDim2.new(.5,-250,.5,0)}):Play()
			task.wait(.14)
			if panel and panel.Parent then
				panel.Visible=false
				panel.Size=UDim2.new(0,500,0,300)
				panel.Position=UDim2.new(.5,-250,.5,-150)
			end
		end
	end)
end

task.spawn(function()
	local w = 0
	while getRole() == "" and w < 10 do task.wait(.5); w=w+.5 end
	setup(); build()
end)

