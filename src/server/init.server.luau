-- Deep Sea Disco v2 — init.server (fresh rewrite, 2026-11-20)
-- Bootstrap: builds the world, wires remotes, handles player actions.
-- The server owns every transfer; the client can only request.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Bases = require(script.Parent:WaitForChild("Bases"))
local Spawner = require(script.Parent:WaitForChild("Spawner"))
local Events = require(script.Parent:WaitForChild("Events"))

-- Remotes (folder created by default.project.json)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local juiceRemote = Instance.new("RemoteEvent")
juiceRemote.Name = "Juice"
juiceRemote.Parent = remotes
local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = "State"
stateRemote.Parent = remotes
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes

-- World
local world = Instance.new("Model")
world.Name = "World"
world.Parent = workspace

local function part(name, size, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = world
	return p
end

-- Lighting: deep water at night, lit by the disco.
local lighting = game:GetService("Lighting")
lighting.Ambient = Color3.fromRGB(10, 40, 60)
lighting.Brightness = 1.6
lighting.OutdoorAmbient = Color3.fromRGB(8, 30, 50)
lighting.FogColor = Color3.fromRGB(7, 34, 58)
lighting.FogStart = 60
lighting.FogEnd = 220
lighting.Technology = Enum.Technology.Future

-- Ocean floor
local floor = part("OceanFloor", Vector3.new(240, 2, 240), Config.PALETTE.DeepWater, Enum.Material.SmoothPlastic)
floor.Position = Vector3.new(0, -1, 0)

-- Dance floor: 8x8 neon tiles in the center.
local tileColors = {
	Config.PALETTE.Coral, Config.PALETTE.Aqua, Config.PALETTE.Lime,
	Config.PALETTE.Pink, Config.PALETTE.Gold, Config.PALETTE.Purple,
}
for row = 1, 8 do
	for col = 1, 8 do
		local tile = part("DanceTile", Vector3.new(5, 0.5, 5), tileColors[(row + col - 1) % #tileColors + 1], Enum.Material.Neon)
		tile.Position = Vector3.new((col - 4.5) * 5.2, 0.25, (row - 4.5) * 5.2)
	end
end

-- Disco ball: faceted metal sphere + point light, slowly rotating.
local ball = part("DiscoBall", Vector3.new(8, 8, 8), Color3.fromRGB(220, 230, 255), Enum.Material.Metal, Enum.PartType.Ball)
ball.Reflectance = 0.7
ball.Position = Vector3.new(0, 26, 0)
local ballLight = Instance.new("PointLight")
ballLight.Color = Color3.fromRGB(180, 220, 255)
ballLight.Range = 90
ballLight.Brightness = 2
ballLight.Parent = ball
local rod = part("BallRod", Vector3.new(0.4, 10, 0.4), Color3.fromRGB(60, 60, 80), Enum.Material.Metal)
rod.Position = Vector3.new(0, 33, 0)
RunService.Heartbeat:Connect(function(dt)
	ball.CFrame = ball.CFrame * CFrame.Angles(0, dt * 0.4, 0)
end)

-- Coral + kelp decorations around the edges.
local coralColors = { Config.PALETTE.Coral, Config.PALETTE.Pink, Config.PALETTE.Purple, Config.PALETTE.Gold }
for i = 1, 12 do
	local a = (i - 1) / 12 * math.pi * 2 + 0.3
	local r = 100 + (i % 3) * 8
	local coral = part("Coral", Vector3.new(3, 6 + (i % 4) * 2, 3), coralColors[(i - 1) % #coralColors + 1], Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	coral.Position = Vector3.new(math.cos(a) * r, 2, math.sin(a) * r)
end
for i = 1, 16 do
	local a = (i - 1) / 16 * math.pi * 2 + 0.15
	local r = 88 + (i % 4) * 6
	local kelp = part("Kelp", Vector3.new(0.6, 10 + (i % 5) * 3, 0.6), Color3.fromRGB(60, 180, 110), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	kelp.Position = Vector3.new(math.cos(a) * r, 5 + (i % 5) * 1.5, math.sin(a) * r)
end

-- Escape portal for the Net Nabber (north edge).
local portal = part("Portal", Vector3.new(10, 12, 1), Config.PALETTE.Purple, Enum.Material.Neon)
portal.Position = Vector3.new(0, 6, -95)

-- Plots + conveyor
Bases.buildPlots(world)
Spawner.buildConveyor(world)
Events.init(world, juiceRemote)

-- Player lifecycle
local function onCharacterAdded(player, char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed = Economy.walkSpeed(player)
	humanoid.Died:Connect(function()
		Bases.dropCarried(player)
	end)
end

local function onPlayerAdded(player)
	Economy.load(player)
	local plotIndex = Bases.assign(player)
	if not plotIndex then
		player:Kick("All disco plots are full — try again soon!")
		return
	end
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	stateRemote:FireClient(player, Economy.snapshot(player))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerRemoving:Connect(function(player)
	Economy.clearOnLeave(player)
	Bases.freePlot(player)
end)

-- Actions from the client. Every action is validated server-side.
actionRemote.OnServerEvent:Connect(function(player, action, arg1)
	if typeof(action) ~= "string" then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local s = Economy.getState(player)

	if action == "deposit" then
		local plot = Bases.getPlot(player)
		if not plot or not root then
			return
		end
		if (root.Position - plot.position).Magnitude > 30 then
			return
		end
		local owned = Bases.deposit(player)
		if owned then
			juiceRemote:FireClient(player, "deposit", owned.income)
			stateRemote:FireClient(player, Economy.snapshot(player))
		end
	elseif action == "sell" then
		local plot = Bases.getPlot(player)
		if not plot or not root then
			return
		end
		if (root.Position - plot.sellPad.Position).Magnitude > 12 then
			return
		end
		local payout = Bases.sell(player)
		if payout then
			juiceRemote:FireClient(player, "deposit", payout)
			stateRemote:FireClient(player, Economy.snapshot(player))
		end
	elseif action == "buyUpgrade" then
		if typeof(arg1) ~= "string" then
			return
		end
		local upgrade = nil
		for _, u in ipairs(Config.UPGRADES) do
			if u.id == arg1 then
				upgrade = u
				break
			end
		end
		if not upgrade then
			return
		end
		local level = s.Upgrades[upgrade.id] or 0
		if level >= upgrade.maxLevel then
			return
		end
		local cost = Config.upgradeCost(upgrade, level + 1)
		if s.Bubbles < cost then
			return
		end
		s.Bubbles -= cost
		s.Upgrades[upgrade.id] = level + 1
		if upgrade.id == "fins" and char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Economy.walkSpeed(player)
			end
		end
		stateRemote:FireClient(player, Economy.snapshot(player))
	elseif action == "lock" then
		if os.clock() < s.LockCooldownUntil then
			return
		end
		s.LockUntil = os.clock() + Config.LOCK_DURATION
		s.LockCooldownUntil = os.clock() + Config.LOCK_COOLDOWN
		stateRemote:FireClient(player, Economy.snapshot(player))
	elseif action == "rebirth" then
		if s.EarnedSinceRebirth < Config.REBIRTH_REQUIRE_EARNED or s.Rebirths >= Config.REBIRTH_MAX then
			return
		end
		Bases.clearBase(player)
		s.Bubbles = 0
		s.EarnedSinceRebirth = 0
		s.Rebirths += 1
		juiceRemote:FireClient(player, "event", "REBIRTH!", "+" .. tostring(Config.REBIRTH_MULTIPLIER * 100) .. "% income forever", Config.PALETTE.Gold)
		stateRemote:FireClient(player, Economy.snapshot(player))
	elseif action == "claimQuest" then
		if typeof(arg1) ~= "string" then
			return
		end
		local quest = nil
		for _, q in ipairs(Config.QUESTS) do
			if q.id == arg1 then
				quest = q
				break
			end
		end
		if not quest then
			return
		end
		local qstate = s.Quests[quest.id] or {}
		if qstate.claimed then
			return
		end
		if Economy.questProgress(player, quest) < quest.target then
			return
		end
		qstate.claimed = true
		s.Quests[quest.id] = qstate
		Economy.addBubbles(player, quest.reward)
		stateRemote:FireClient(player, Economy.snapshot(player))
	end
end)

-- Start the loops.
Economy.start(stateRemote)
Spawner.start()
Events.start()
