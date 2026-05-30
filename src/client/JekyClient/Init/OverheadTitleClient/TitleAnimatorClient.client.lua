-- StarterPlayerScripts/TitleAnimatorClient.client.lua
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local animatedLabels = {}

local function onLabelAdded(lbl)
	table.insert(animatedLabels, lbl)
end

local function onLabelRemoved(lbl)
	for i = #animatedLabels, 1, -1 do
		if animatedLabels[i] == lbl then
			table.remove(animatedLabels, i)
			break
		end
	end
end

CollectionService:GetInstanceAddedSignal("AnimatedTitleLabel"):Connect(onLabelAdded)
CollectionService:GetInstanceRemovedSignal("AnimatedTitleLabel"):Connect(onLabelRemoved)

for _, lbl in ipairs(CollectionService:GetTagged("AnimatedTitleLabel")) do
	onLabelAdded(lbl)
end

-- Variabel global untuk disinkronkan semua title
local offsetLR = 0
local dirLR = 1
local rotation = 0

RunService.RenderStepped:Connect(function(dt)
	-- Update time variables
	rotation = (rotation + dt * 60) % 360
	
	offsetLR = offsetLR + dt * 0.5 * dirLR
	if offsetLR >= 1 then 
		offsetLR, dirLR = 1, -1
	elseif offsetLR <= -1 then 
		offsetLR, dirLR = -1, 1 
	end

	local t = os.clock()
	local offsetDiagonal = (t * 0.4) % 3 - 1
	local offsetWave = math.sin((t * 0.6) * math.pi * 2)
	
	local pulseTime = (t * 0.8) % 2
	local offsetPulse = pulseTime > 1 and (2 - pulseTime) or pulseTime
	-- Normalize pulse to -1 to 1 to match original logic
	offsetPulse = (offsetPulse * 2) - 1

	for i = #animatedLabels, 1, -1 do
		local lbl = animatedLabels[i]
		
		if not lbl or not lbl.Parent then
			table.remove(animatedLabels, i)
			continue
		end
		
		local grad = lbl:FindFirstChildOfClass("UIGradient")
		local animType = lbl:GetAttribute("TitleAnimType")
		
		if grad and animType then
			if animType == "Gradient360" then
				grad.Rotation = rotation
			elseif animType == "LeftRight" then
				grad.Offset = Vector2.new(offsetLR, 0)
			elseif animType == "Diagonal" then
				grad.Offset = Vector2.new(offsetDiagonal, offsetDiagonal)
			elseif animType == "Wave" then
				grad.Offset = Vector2.new(offsetWave, 0)
			elseif animType == "Pulse" then
				grad.Offset = Vector2.new(offsetPulse, 0)
			end
		end
	end
end)
