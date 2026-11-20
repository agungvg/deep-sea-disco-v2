-- Deep Sea Disco v2 — Spawner (fresh rewrite, 2026-11-20)
-- The conveyor: critters spawn at the west end, dance-walk east along
-- the belt, and despawn at the end if nobody picks them up.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CritterFactory = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CritterFactory"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Bases = require(script.Parent:WaitForChild("Bases"))

local Spawner = {}
local walkers = {} -- {model, progress, speed, baseY}
local conveyor = nil

local BELT_START = Vector3.new(-45, 1.6, 0)
local BELT_END = Vector3.new(45, 1.6, 0)
local BELT_LENGTH = 90
local WALK_TIME = 42 -- seconds end to end
local SPAWN_INTERVAL = 4

function Spawner.buildConveyor(parent)
	local belt = Instance.new("Part")
	belt.Name = "Conveyor"
	belt.Size = Vector3.new(BELT_LENGTH + 4, 1, 8)
	belt.Position = Vector3.new(0, 1, 0)
	belt.Color = Color3.fromRGB(20, 60, 90)
	belt.Material = Enum.Material.SmoothPlastic
	belt.Anchored = true
	belt.CanCollide = true
	belt.TopSurface = Enum.SurfaceType.Smooth
	belt.BottomSurface = Enum.SurfaceType.Smooth
	belt.Parent = parent
	conveyor = belt
	-- Belt chevrons
	for x = -40, 40, 10 do
		local stripe = Instance.new("Part")
		stripe.Name = "Stripe"
		stripe.Size = Vector3.new(1, 0.15, 7.6)
		stripe.Position = Vector3.new(x, 1.55, 0)
		stripe.Color = Color3.fromRGB(28, 170, 190)
		stripe.Material = Enum.Material.Neon
		stripe.Anchored = true
		stripe.CanCollide = false
		stripe.Parent = parent
	end
	-- Spawn + despawn gates
	for _, x in ipairs({ -46, 46 }) do
		local gate = Instance.new("Part")
		gate.Name = "Gate"
		gate.Size = Vector3.new(1, 8, 10)
		gate.Position = Vector3.new(x, 5, 0)
		gate.Color = Color3.fromRGB(255, 205, 60)
		gate.Material = Enum.Material.Neon
		gate.Anchored = true
		gate.CanCollide = false
		gate.Transparency = 0.5
		gate.Parent = parent
	end
end

local function rollIndex(luck)
	-- Weighted: early critters common, late critters rare.
	local total = 0
	local weights = {}
	for i = 1, #Config.CRITTERS do
		local w = 1 / (1 + (i - 1) * 0.35)
		weights[i] = w
		total += w
	end
	local roll = math.random() * total
	for i, w in ipairs(weights) do
		roll -= w
		if roll <= 0 then
			return i
		end
	end
	return 1
end

local function rollMutation(luck)
	local roll = math.random()
	local cumulative = 0
	for _, mut in ipairs(Config.MUTATIONS) do
		cumulative += mut.chance * luck
		if roll <= cumulative then
			return mut.name
		end
	end
	return ""
end

local function spawnOne()
	-- Luck uses the average online player's lure level (simple, fair).
	local luck = 1
	local players = game:GetService("Players"):GetPlayers()
	if #players > 0 then
		local sum = 0
		for _, p in ipairs(players) do
			sum += Economy.mutationLuck(p)
		end
		luck = sum / #players
	end
	local index = rollIndex(luck)
	local mutation = rollMutation(luck)
	local model = CritterFactory.build(index, mutation)
	if not model then
		return
	end
	model:SetAttribute("OnConveyor", true)
	model:PivotTo(CFrame.new(BELT_START))
	model.Parent = workspace:WaitForChild("World")
	table.insert(walkers, {
		model = model,
		progress = 0,
		speed = 1 / WALK_TIME,
		phase = math.random() * math.pi * 2,
	})
	Bases.armTouch(model)
end

function Spawner.start()
	task.spawn(function()
		while true do
			task.wait(SPAWN_INTERVAL)
			spawnOne()
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for i = #walkers, 1, -1 do
			local w = walkers[i]
			if not w.model.Parent then
				table.remove(walkers, i)
			else
				w.progress += w.speed * dt
				if w.progress >= 1 then
					Bases.disarmTouch(w.model)
					w.model:Destroy()
					table.remove(walkers, i)
				else
					-- Dance-walk: bob + sway while moving east.
					local x = BELT_START.X + (BELT_END.X - BELT_START.X) * w.progress
					local bob = math.sin(os.clock() * 6 + w.phase) * 0.25
					local sway = math.sin(os.clock() * 3 + w.phase) * 0.15
					w.model:PivotTo(CFrame.new(x, BELT_START.Y + bob, sway) * CFrame.Angles(0, math.rad(90), 0))
				end
			end
		end
	end)
end

return Spawner
