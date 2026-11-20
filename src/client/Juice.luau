-- Deep Sea Disco v2 — Juice (fresh rewrite, 2026-11-20)
-- Client-side feel: trauma shake, floating income labels, event banners,
-- pops, count-ups, hit-stop. Feedback only — never game rules.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")

local Juice = {}

-- Reduce-motion respect.
local function shakeScale()
	local ok, reduced = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	if ok and reduced then
		return 0
	end
	return 1
end

-- Trauma camera shake.
local trauma = 0
local shakeT = 0
local MAX_ANGLE = math.rad(2.5)
local DECAY = 1.3

RunService:BindToRenderStep("JuiceShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if trauma <= 0 then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	shakeT += dt * 20
	local s = trauma * trauma * shakeScale()
	if camera then
		camera.CFrame *= CFrame.Angles(
			MAX_ANGLE * s * math.noise(shakeT, 0),
			MAX_ANGLE * s * math.noise(0, shakeT),
			MAX_ANGLE * s * math.noise(shakeT, shakeT))
	end
	trauma = math.max(trauma - DECAY * dt, 0)
end)

function Juice.addShake(amount)
	trauma = math.min(trauma + amount, 1)
end

-- UI pop via UIScale (leaves Size/layout alone).
function Juice.pop(gui, scale, seconds)
	if not gui or not gui.Parent then
		return
	end
	local s = gui:FindFirstChildOfClass("UIScale")
	if not s then
		s = Instance.new("UIScale")
		s.Parent = gui
	end
	s.Scale = scale or 1.25
	TweenService:Create(s, TweenInfo.new(seconds or 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Floating income label rising off a world position.
function Juice.floatLabel(parent, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 32)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(120, 255, 140)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard
	TweenService:Create(billboard, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, 5, 0) }):Play()
	task.delay(0.7, function()
		TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	task.delay(1.2, function()
		billboard:Destroy()
	end)
end

-- Full-width event banner. Built once by the client, shown on demand.
local bannerGui = nil
function Juice.bindBanner(frame)
	bannerGui = frame
end

function Juice.eventBanner(title, subtitle, accent)
	if not bannerGui then
		return
	end
	local titleLabel = bannerGui:FindFirstChild("Title")
	local subLabel = bannerGui:FindFirstChild("Subtitle")
	if titleLabel then
		titleLabel.Text = title
	end
	if subLabel then
		subLabel.Text = subtitle
	end
	bannerGui.BackgroundColor3 = accent or Color3.fromRGB(255, 107, 107)
	bannerGui.Visible = true
	bannerGui.Position = UDim2.new(0.5, 0, -0.18, 0)
	TweenService:Create(bannerGui, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.07, 0) }):Play()
	Juice.pop(bannerGui, 1.06, 0.25)
	Juice.sting()
	task.delay(2.6, function()
		if not bannerGui.Parent then
			return
		end
		TweenService:Create(bannerGui, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, -0.18, 0) }):Play()
		task.delay(0.3, function()
			bannerGui.Visible = false
		end)
	end)
end

-- Short pitch-varied sting (uses a built-in Roblox sound id).
local stingId = "rbxassetid://13107247"
function Juice.sting()
	local sound = Instance.new("Sound")
	sound.SoundId = stingId
	sound.PlaybackSpeed = 0.92 + math.random() * 0.16
	sound.Volume = 0.4
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function Juice.click()
	local sound = Instance.new("Sound")
	sound.SoundId = stingId
	sound.PlaybackSpeed = 1.15 + math.random() * 0.1
	sound.Volume = 0.25
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- Count-up a label to a target number with commas.
function Juice.countUp(label, from, to, seconds)
	local v = Instance.new("NumberValue")
	v.Value = from
	v.Changed:Connect(function(val)
		local s = tostring(math.floor(val))
		local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		label.Text = formatted
	end)
	TweenService:Create(v, TweenInfo.new(seconds or 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = to }):Play()
	task.delay((seconds or 0.6) + 0.1, function()
		v:Destroy()
	end)
end

-- Hit-stop: freeze playing animation tracks briefly.
function Juice.hitStop(duration)
	local player = game:GetService("Players").LocalPlayer
	local char = player and player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local tracks = animator:GetPlayingAnimationTracks()
	for _, tr in ipairs(tracks) do
		tr:AdjustSpeed(0)
	end
	task.delay(duration or 0.06, function()
		for _, tr in ipairs(tracks) do
			tr:AdjustSpeed(1)
		end
	end)
end

return Juice
