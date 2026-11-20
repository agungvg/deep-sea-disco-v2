-- Deep Sea Disco v2 — Bases (fresh rewrite, 2026-11-20)
-- Player plots, pedestals, carry / deposit / sell / steal / lock.
-- The server owns every transfer: a client can only request, never take.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local Bases = {}
local plots = {} -- [plotIndex] = {owner, position, pedestals = { {part, ownedId, model} }, sellPad}
local playerPlot = {} -- [player] = plotIndex
local carried = {} -- [player] = { {model, index, mutation, income, price, fromPlot, fromPedestal} }
local touchConns = {} -- [model] = RBXScriptConnection

local PLOT_COUNT = 8
local PLOT_RADIUS = 72
local PLOT_COLORS = {
	Color3.fromRGB(255, 107, 107), Color3.fromRGB(255, 205, 60),
	Color3.fromRGB(170, 255, 110), Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(255, 120, 200), Color3.fromRGB(150, 100, 255),
	Color3.fromRGB(120, 255, 220), Color3.fromRGB(255, 170, 90),
}

local function part(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function Bases.buildPlots(parent)
	for i = 1, PLOT_COUNT do
		local angle = (i - 1) / PLOT_COUNT * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * PLOT_RADIUS, 0, math.sin(angle) * PLOT_RADIUS)
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. tostring(i)
		plot.Parent = parent

		local floor = part("Floor", Vector3.new(28, 1, 28), PLOT_COLORS[i], Enum.Material.SmoothPlastic)
		floor.Position = pos + Vector3.new(0, 0.5, 0)
		floor.Parent = plot

		-- Owner sign
		local sign = part("Sign", Vector3.new(8, 3, 0.5), Color3.fromRGB(240, 248, 255), Enum.Material.SmoothPlastic)
		sign.Position = pos + Vector3.new(0, 5, -13)
		sign.Parent = plot
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = sign
		local signLabel = Instance.new("TextLabel")
		signLabel.Size = UDim2.fromScale(1, 1)
		signLabel.BackgroundTransparency = 1
		signLabel.Text = "EMPTY PLOT"
		signLabel.TextColor3 = Color3.fromRGB(10, 40, 60)
		signLabel.Font = Enum.Font.FredokaOne
		signLabel.TextScaled = true
		signLabel.Parent = signGui

		-- 12 pedestals, 3 rows x 4
		local pedestals = {}
		for row = 1, 3 do
			for col = 1, 4 do
				local ped = part("Pedestal", Vector3.new(4, 1, 4), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
				ped.Position = pos + Vector3.new((col - 2.5) * 5.5, 1.5, (row - 2) * 6)
				ped.Parent = plot
				table.insert(pedestals, { part = ped, ownedId = nil, model = nil })
			end
		end

		-- Sell pad at the plot entrance
		local sell = part("SellPad", Vector3.new(6, 1, 6), Color3.fromRGB(255, 205, 60), Enum.Material.Neon)
		sell.Position = pos + Vector3.new(0, 1.5, 13)
		sell.Parent = plot
		local sellGui = Instance.new("SurfaceGui")
		sellGui.Face = Enum.NormalId.Top
		sellGui.Parent = sell
		local sellLabel = Instance.new("TextLabel")
		sellLabel.Size = UDim2.fromScale(1, 1)
		sellLabel.BackgroundTransparency = 1
		sellLabel.Text = "SELL 80%"
		sellLabel.TextColor3 = Color3.fromRGB(60, 40, 0)
		sellLabel.Font = Enum.Font.FredokaOne
		sellLabel.TextScaled = true
		sellLabel.Parent = sellGui

		plots[i] = {
			owner = nil, position = pos, pedestals = pedestals,
			sellPad = sell, signLabel = signLabel, model = plot,
		}
	end
end

function Bases.assign(player)
	for i, plot in ipairs(plots) do
		if plot.owner == nil then
			plot.owner = player
			playerPlot[player] = i
			plot.signLabel.Text = player.DisplayName .. "'s BASE"
			return i
		end
	end
	return nil
end

function Bases.getPlot(player)
	local i = playerPlot[player]
	if i then
		return plots[i]
	end
	return nil
end

function Bases.plotIndexOf(player)
	return playerPlot[player]
end

function Bases.isLocked(player)
	local s = Economy.getState(player)
	return os.clock() < s.LockUntil
end

function Bases.carriedCount(player)
	local list = carried[player]
	return list and #list or 0
end

local function setAnchored(model, anchored)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = anchored
			d.CanCollide = false
		end
	end
end

local function attachToPlayer(player, model)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not model.PrimaryPart then
		return false
	end
	setAnchored(model, false)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(0, 3.4, 0)
	weld.Parent = model.PrimaryPart
	return true
end

local function detachCarry(model)
	local weld = model.PrimaryPart and model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
end

-- Called when a player touches a critter model (conveyor or pedestal).
function Bases.handleTouch(model, hit)
	local char = hit.Parent
	if not char then
		return
	end
	local player = Players:GetPlayerFromCharacter(char)
	if not player then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Conveyor critter: free pickup.
	if model:GetAttribute("OnConveyor") == true then
		Bases.tryPickup(player, model)
		return
	end
	-- Pedestal critter: steal from another player's base.
	if model:GetAttribute("OnPedestal") == true then
		Bases.trySteal(player, model)
	end
end

function Bases.armTouch(model)
	if touchConns[model] then
		return
	end
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	touchConns[model] = primary.Touched:Connect(function(hit)
		Bases.handleTouch(model, hit)
	end)
end

function Bases.disarmTouch(model)
	local conn = touchConns[model]
	if conn then
		conn:Disconnect()
		touchConns[model] = nil
	end
end

-- Pick up a conveyor critter. Returns true on success.
function Bases.tryPickup(player, model)
	if not model.Parent then
		return false
	end
	if Bases.carriedCount(player) >= Economy.carrySlots(player) then
		return false
	end
	if not attachToPlayer(player, model) then
		return false
	end
	model:SetAttribute("OnConveyor", false)
	local list = carried[player]
	if not list then
		list = {}
		carried[player] = list
	end
	table.insert(list, {
		model = model,
		index = model:GetAttribute("CritterIndex"),
		mutation = model:GetAttribute("Mutation") or "",
		income = model:GetAttribute("Income") or 0,
		price = model:GetAttribute("Price") or 0,
		fromPlot = nil,
		fromPedestal = nil,
	})
	return true
end

-- Steal a critter off another player's pedestal.
function Bases.trySteal(player, model)
	local s = Economy.getState(player)
	if os.clock() < s.StealCooldownUntil then
		return false
	end
	local ownerId = model:GetAttribute("OwnerUserId")
	if not ownerId or ownerId == player.UserId then
		return false
	end
	local victim = Players:GetPlayerByUserId(ownerId)
	if not victim then
		return false
	end
	if Bases.isLocked(victim) then
		return false
	end
	if Bases.carriedCount(player) >= Economy.carrySlots(player) then
		return false
	end
	-- Find and clear the pedestal slot.
	local plot = Bases.getPlot(victim)
	if not plot then
		return false
	end
	for i, ped in ipairs(plot.pedestals) do
		if ped.model == model then
			ped.model = nil
			ped.ownedId = nil
			break
		end
	end
	Economy.removeOwned(victim, model:GetAttribute("OwnedId"))
	model:SetAttribute("OnPedestal", false)
	if not attachToPlayer(player, model) then
		return false
	end
	s.StealCooldownUntil = os.clock() + 10
	local list = carried[player]
	if not list then
		list = {}
		carried[player] = list
	end
	table.insert(list, {
		model = model,
		index = model:GetAttribute("CritterIndex"),
		mutation = model:GetAttribute("Mutation") or "",
		income = model:GetAttribute("Income") or 0,
		price = model:GetAttribute("Price") or 0,
		fromPlot = Bases.plotIndexOf(victim),
		fromPedestal = nil,
		stolenFrom = victim,
	})
	return true
end

-- Deposit the first carried critter onto a free pedestal of the player's plot.
-- Returns the owned entry or nil.
function Bases.deposit(player)
	local list = carried[player]
	if not list or #list == 0 then
		return nil
	end
	local plot = Bases.getPlot(player)
	if not plot then
		return nil
	end
	local entry = list[1]
	local slot = nil
	local slotIndex = nil
	for i, ped in ipairs(plot.pedestals) do
		if ped.model == nil then
			slot = ped
			slotIndex = i
			break
		end
	end
	if not slot then
		return nil
	end
	detachCarry(entry.model)
	setAnchored(entry.model, true)
	local target = slot.part.Position + Vector3.new(0, 0.5, 0)
	entry.model:PivotTo(CFrame.new(target))
	entry.model:SetAttribute("OnPedestal", true)
	entry.model:SetAttribute("OwnerUserId", player.UserId)
	local owned = Economy.addOwned(player, entry.index, entry.mutation, entry.income)
	if not owned then
		return nil
	end
	entry.model:SetAttribute("OwnedId", owned.id)
	slot.model = entry.model
	slot.ownedId = owned.id
	Bases.armTouch(entry.model) -- pedestal critters can be stolen: touch must stay armed
	table.remove(list, 1)
	return owned
end

-- Sell the first carried critter for 80% of its price.
function Bases.sell(player)
	local list = carried[player]
	if not list or #list == 0 then
		return nil
	end
	local entry = list[1]
	table.remove(list, 1)
	local payout = math.floor(entry.price * Config.SELL_FRACTION + 0.5)
	Bases.disarmTouch(entry.model)
	entry.model:Destroy()
	Economy.addBubbles(player, payout)
	return payout
end

-- Drop carried critters at the player's position (on death).
function Bases.dropCarried(player)
	local list = carried[player]
	if not list then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local dropPos = root and root.Position or Vector3.new(0, 5, 0)
	for _, entry in ipairs(list) do
		if entry.model.Parent then
			detachCarry(entry.model)
			setAnchored(entry.model, true)
			entry.model:PivotTo(CFrame.new(dropPos + Vector3.new(math.random(-4, 4), 2, math.random(-4, 4))))
			entry.model:SetAttribute("OnConveyor", true)
			Bases.armTouch(entry.model)
		end
	end
	carried[player] = {}
end

-- Clear a base entirely (rebirth).
function Bases.clearBase(player)
	local plot = Bases.getPlot(player)
	if not plot then
		return
	end
	for _, ped in ipairs(plot.pedestals) do
		if ped.model then
			Bases.disarmTouch(ped.model)
			ped.model:Destroy()
			ped.model = nil
			ped.ownedId = nil
		end
	end
	local s = Economy.getState(player)
	s.Owned = {}
end

function Bases.freePlot(player)
	local i = playerPlot[player]
	if i and plots[i] then
		plots[i].owner = nil
		plots[i].signLabel.Text = "EMPTY PLOT"
	end
	playerPlot[player] = nil
	local list = carried[player]
	if list then
		for _, entry in ipairs(list) do
			if entry.model.Parent then
				entry.model:Destroy()
			end
		end
	end
	carried[player] = nil
end

function Bases.getCarried(player)
	return carried[player] or {}
end

return Bases
