-- Deep Sea Disco v2 — Events (fresh rewrite, 2026-11-20)
-- Timed world events: Disco Fever (2x money), Net Nabber (thief crab),
-- Shark Sweep (hazard), Go Dark (lights out + all bases locked).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CritterFactory = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CritterFactory"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Bases = require(script.Parent:WaitForChild("Bases"))

local Events = {}
local juice = nil
local world = nil

local FEVER_EVERY = 150
local FEVER_DURATION = 45
local NABBER_EVERY = 200
local SHARK_EVERY = 260
local DARK_EVERY = 320
local DARK_DURATION = 20

function Events.init(worldModel, juiceRemote)
	world = worldModel
	juice = juiceRemote
end

local function banner(title, subtitle, accent)
	if juice then
		juice:FireAllClients("event", title, subtitle, accent)
	end
end

local function discoFever()
	Economy.setFever(os.clock() + FEVER_DURATION)
	banner("DISCO FEVER!", "2x money for 45 seconds", Config.PALETTE.Coral)
end

local function buildCrab()
	local model = Instance.new("Model")
	model.Name = "NetNabber"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.4, 1.4, 2.6)
	body.Color = Color3.fromRGB(255, 90, 80)
	body.Material = Enum.Material.SmoothPlastic
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 1.2, 0)
	body.Parent = model
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.4, 0.4, 0.4)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Shape = Enum.PartType.Ball
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = Vector3.new(side * 0.6, 1.9, 1.2)
		eye.Parent = model
		local claw = Instance.new("Part")
		claw.Name = "Claw"
		claw.Size = Vector3.new(0.8, 0.8, 0.8)
		claw.Color = Color3.fromRGB(255, 205, 60)
		claw.Material = Enum.Material.SmoothPlastic
		claw.Shape = Enum.PartType.Ball
		claw.Anchored = true
		claw.CanCollide = false
		claw.Position = Vector3.new(side * 2.0, 1.0, 0.8)
		claw.Parent = model
	end
	model.PrimaryPart = body
	return model
end

local function netNabber()
	-- Pick a random unlocked base with at least one critter.
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if not Bases.isLocked(player) then
			local plot = Bases.getPlot(player)
			if plot then
				for _, ped in ipairs(plot.pedestals) do
					if ped.model then
						table.insert(candidates, { player = player, plot = plot, ped = ped })
					end
				end
			end
		end
	end
	if #candidates == 0 then
		return
	end
	local target = candidates[math.random(1, #candidates)]
	local victim = target.player
	local stolen = target.ped.model
	Economy.removeOwned(victim, target.ped.ownedId)
	target.ped.model = nil
	target.ped.ownedId = nil
	stolen:SetAttribute("OnPedestal", false)

	local crab = buildCrab()
	crab:PivotTo(CFrame.new(target.plot.position + Vector3.new(0, 1, 0)))
	crab.Parent = world
	banner("NET NABBER!", "A thief crab stole a critter — TAG it to make it drop!", Config.PALETTE.Coral)
	if juice then
		juice:FireClient(victim, "steal", stolen.Position)
	end

	-- Crab carries the critter above its head and scuttles to the portal.
	stolen:PivotTo(CFrame.new(target.plot.position + Vector3.new(0, 3.5, 0)))
	stolen.Parent = world
	local startPos = crab.PrimaryPart.Position
	local portalPos = Vector3.new(0, 1, -95)
	local startTime = os.clock()
	local duration = 25
	local dropped = false
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = math.min((os.clock() - startTime) / duration, 1)
		local pos = startPos:Lerp(portalPos, t)
		pos = Vector3.new(pos.X, 1.2 + math.sin(os.clock() * 8) * 0.15, pos.Z)
		crab:PivotTo(CFrame.new(pos))
		if stolen.Parent then
			stolen:PivotTo(CFrame.new(pos + Vector3.new(0, 2.4, 0)))
		end
		if t >= 1 and not dropped then
			dropped = true
			conn:Disconnect()
			crab:Destroy()
			if stolen.Parent then
				stolen:Destroy()
			end
		end
	end)
	-- Tag the crab: touch drops the critter as a free pickup.
	local tagConn
	tagConn = crab.PrimaryPart.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then
			return
		end
		local player = Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end
		if dropped then
			return
		end
		dropped = true
		conn:Disconnect()
		tagConn:Disconnect()
		crab:Destroy()
		if stolen.Parent then
			stolen:PivotTo(CFrame.new(crab.PrimaryPart.Position + Vector3.new(0, 2, 0)))
			stolen:SetAttribute("OnConveyor", true)
			Bases.armTouch(stolen)
		end
		banner("CRAB TAGGED!", player.DisplayName .. " saved the critter!", Config.PALETTE.Lime)
	end)
	task.delay(duration + 1, function()
		if conn.Connected then
			conn:Disconnect()
		end
		if tagConn.Connected then
			tagConn:Disconnect()
		end
		if crab.Parent then
			crab:Destroy()
		end
	end)
end

local function buildShark()
	local model = Instance.new("Model")
	model.Name = "Shark"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, 2.4, 7)
	body.Color = Color3.fromRGB(120, 140, 170)
	body.Material = Enum.Material.SmoothPlastic
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.Position = Vector3.new(0, 4, 0)
	body.Parent = model
	local fin = Instance.new("Part")
	fin.Name = "Fin"
	fin.Size = Vector3.new(0.2, 1.6, 1.6)
	fin.Color = Color3.fromRGB(90, 110, 140)
	fin.Material = Enum.Material.SmoothPlastic
	fin.Shape = Enum.PartType.Wedge
	fin.Anchored = true
	fin.CanCollide = false
	fin.Position = Vector3.new(0, 5.6, 0)
	fin.Parent = model
	model.PrimaryPart = body
	return model
end

local function sharkSweep()
	local shark = buildShark()
	local z = math.random(-50, 50)
	local startPos = Vector3.new(-90, 4, z)
	local endPos = Vector3.new(90, 4, z)
	shark:PivotTo(CFrame.new(startPos))
	shark.Parent = world
	banner("SHARK SWEEP!", "A shark is crossing the floor — get out of the way!", Color3.fromRGB(255, 90, 90))
	local startTime = os.clock()
	local duration = 12
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = math.min((os.clock() - startTime) / duration, 1)
		local pos = startPos:Lerp(endPos, t)
		shark:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0))
		-- Knock players close to the shark.
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - pos).Magnitude < 9 then
				root.AssemblyLinearVelocity = Vector3.new(0, 18, 0) + (root.Position - pos).Unit * 22
				if juice then
					juice:FireClient(player, "hurt")
				end
			end
		end
		if t >= 1 then
			conn:Disconnect()
			shark:Destroy()
		end
	end)
	task.delay(duration + 1, function()
		if conn.Connected then
			conn:Disconnect()
		end
		if shark.Parent then
			shark:Destroy()
		end
	end)
end

local function goDark()
	local lighting = game:GetService("Lighting")
	local oldAmbient = lighting.Ambient
	local oldBrightness = lighting.Brightness
	lighting.Ambient = Color3.fromRGB(5, 5, 15)
	lighting.Brightness = 0.4
	-- All bases lock while the lights are out: nobody can steal.
	for _, player in ipairs(Players:GetPlayers()) do
		local s = Economy.getState(player)
		s.LockUntil = math.max(s.LockUntil, os.clock() + DARK_DURATION)
	end
	banner("GO DARK!", "Lights out for 20 seconds — all bases locked", Color3.fromRGB(90, 60, 160))
	task.delay(DARK_DURATION, function()
		lighting.Ambient = oldAmbient
		lighting.Brightness = oldBrightness
	end)
end

function Events.start()
	task.spawn(function()
		task.wait(45)
		while true do
			discoFever()
			task.wait(FEVER_EVERY)
		end
	end)
	task.spawn(function()
		task.wait(90)
		while true do
			netNabber()
			task.wait(NABBER_EVERY)
		end
	end)
	task.spawn(function()
		task.wait(130)
		while true do
			sharkSweep()
			task.wait(SHARK_EVERY)
		end
	end)
	task.spawn(function()
		task.wait(180)
		while true do
			goDark()
			task.wait(DARK_EVERY)
		end
	end)
end

return Events
