-- Deep Sea Disco v2 — Game.client (fresh rewrite, 2026-11-20)
-- HUD, panels, prompts, Juice wiring. The client only displays and
-- requests; the server decides everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Juice = require(script.Parent:WaitForChild("Juice"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local juiceRemote = remotes:WaitForChild("Juice")
local stateRemote = remotes:WaitForChild("State")
local actionRemote = remotes:WaitForChild("Action")

local function commas(n)
	local s = tostring(math.floor(n))
	return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "DiscoHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function frame(name, size, pos, bg, parent)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = bg
	f.BorderSizePixel = 0
	f.Parent = parent or gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = f
	return f
end

local function label(name, size, pos, text, sizePx, color, parent)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = sizePx
	l.TextColor3 = color
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = false
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent or gui
	return l
end

local function button(name, size, pos, text, parent)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = Color3.fromRGB(20, 80, 100)
	b.Text = text
	b.TextSize = 16
	b.TextColor3 = Color3.fromRGB(240, 248, 255)
	b.Font = Enum.Font.FredokaOne
	b.Parent = parent or gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	b.MouseButton1Click:Connect(function()
		Juice.click()
	end)
	return b
end

-- Money pill (top-left)
local moneyPill = frame("MoneyPill", UDim2.new(0, 250, 0, 64), UDim2.new(0, 12, 0, 12), Color3.fromRGB(7, 34, 58))
moneyPill.BackgroundTransparency = 0.15
local moneyLabel = label("Money", UDim2.new(1, -16, 0, 36), UDim2.new(0, 12, 0, 2), "0", 30, Color3.fromRGB(255, 214, 140), moneyPill)
local perSecondLabel = label("PerSecond", UDim2.new(1, -16, 0, 22), UDim2.new(0, 12, 0, 38), "+$0/s", 16, Color3.fromRGB(170, 255, 110), moneyPill)
local indexLabel = label("Index", UDim2.new(0, 200, 0, 24), UDim2.new(0, 12, 0, 82), "INDEX 0/48", 16, Color3.fromRGB(140, 220, 255), gui)

-- Top-right buttons
local btnUpgrades = button("UpgradesBtn", UDim2.new(0, 110, 0, 42), UDim2.new(1, -480, 0, 12), "UPGRADES")
local btnIndex = button("IndexBtn", UDim2.new(0, 110, 0, 42), UDim2.new(1, -362, 0, 12), "INDEX")
local btnQuests = button("QuestsBtn", UDim2.new(0, 110, 0, 42), UDim2.new(1, -244, 0, 12), "QUESTS")
local btnRebirth = button("RebirthBtn", UDim2.new(0, 110, 0, 42), UDim2.new(1, -126, 0, 12), "REBIRTH")

-- Lock button (bottom-right)
local lockBtn = button("LockBtn", UDim2.new(0, 150, 0, 48), UDim2.new(1, -162, 1, -60), "LOCK BASE")
lockBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)

-- Event banner (top-center, hidden)
local banner = frame("Banner", UDim2.new(0, 620, 0, 70), UDim2.new(0.5, 0, -0.18, 0), Config.PALETTE.Coral)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Visible = false
local bannerTitle = label("Title", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 4), "", 26, Color3.fromRGB(255, 255, 255), banner)
bannerTitle.TextXAlignment = Enum.TextXAlignment.Center
local bannerSub = label("Subtitle", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 40), "", 16, Color3.fromRGB(255, 255, 255), banner)
bannerSub.TextXAlignment = Enum.TextXAlignment.Center
Juice.bindBanner(banner)

-- Prompt (bottom-center)
local promptLabel = label("Prompt", UDim2.new(0, 500, 0, 30), UDim2.new(0.5, -250, 1, -100), "", 20, Color3.fromRGB(255, 255, 255), gui)
promptLabel.TextXAlignment = Enum.TextXAlignment.Center
promptLabel.TextStrokeTransparency = 0.3

-- Panels (center, one at a time)
local panels = {}
local function makePanel(name)
	local p = frame(name, UDim2.new(0, 560, 0, 440), UDim2.new(0.5, -280, 0.5, -220), Color3.fromRGB(10, 50, 70))
	p.Visible = false
	local title = label("Title", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 8), name, 24, Color3.fromRGB(255, 214, 140), p)
	local close = button("Close", UDim2.new(0, 80, 0, 32), UDim2.new(1, -90, 0, 8), "CLOSE", p)
	close.MouseButton1Click:Connect(function()
		p.Visible = false
	end)
	panels[name] = p
	return p
end

local upgradesPanel = makePanel("UPGRADES")
local indexPanel = makePanel("INDEX — 48 CRITTERS")
local questsPanel = makePanel("QUESTS")
local rebirthPanel = makePanel("REBIRTH")

local function togglePanel(p)
	local wasVisible = p.Visible
	for _, other in pairs(panels) do
		other.Visible = false
	end
	p.Visible = not wasVisible
end
btnUpgrades.MouseButton1Click:Connect(function() togglePanel(upgradesPanel) end)
btnIndex.MouseButton1Click:Connect(function() togglePanel(indexPanel) end)
btnQuests.MouseButton1Click:Connect(function() togglePanel(questsPanel) end)
btnRebirth.MouseButton1Click:Connect(function() togglePanel(rebirthPanel) end)
lockBtn.MouseButton1Click:Connect(function()
	actionRemote:FireServer("lock")
end)

-- Panel contents, built once and refreshed from snapshots.
local upgradeRows = {}
do
	local y = 56
	for _, u in ipairs(Config.UPGRADES) do
		label(u.id .. "Name", UDim2.new(0.55, 0, 0, 26), UDim2.new(0, 12, 0, y), u.name .. " — " .. u.desc, 15, Color3.fromRGB(240, 248, 255), upgradesPanel)
		local buy = button(u.id .. "Buy", UDim2.new(0, 200, 0, 34), UDim2.new(1, -212, 0, y - 4), "BUY", upgradesPanel)
		buy.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
		buy.TextColor3 = Color3.fromRGB(60, 40, 0)
		buy.MouseButton1Click:Connect(function()
			actionRemote:FireServer("buyUpgrade", u.id)
		end)
		upgradeRows[u.id] = buy
		y += 52
	end
	label("UpgradesNote", UDim2.new(1, -24, 0, 60), UDim2.new(0, 12, 0, y + 8),
		"Upgrades are permanent. Fins = speed, Net = carry slots, Amp = income, Lure = mutation luck.", 14,
		Color3.fromRGB(170, 220, 235), upgradesPanel).TextWrapped = true
end

local indexCells = {}
do
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 122, 0, 44)
	grid.CellPadding = UDim2.new(0, 6, 0, 6)
	grid.Parent = indexPanel
	local holder = frame("GridHolder", UDim2.new(1, -20, 1, -60), UDim2.new(0, 10, 0, 50), Color3.fromRGB(7, 34, 58), indexPanel)
	grid.Parent = holder
	for i, critter in ipairs(Config.CRITTERS) do
		local tier = Config.TIERS[Config.tierOf(i)]
		local cell = Instance.new("TextButton")
		cell.Name = "Critter" .. tostring(i)
		cell.BackgroundColor3 = Color3.fromRGB(20, 70, 90)
		cell.Text = critter.name .. "\n$" .. commas(Config.priceOf(i)) .. "  $" .. commas(Config.incomeOf(i)) .. "/s"
		cell.TextSize = 11
		cell.TextColor3 = tier.color
		cell.Font = Enum.Font.GothamBold
		cell.Parent = holder
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = cell
		indexCells[i] = cell
	end
end

local questRows = {}
do
	local y = 56
	for _, q in ipairs(Config.QUESTS) do
		label(q.id .. "Name", UDim2.new(0.6, 0, 0, 26), UDim2.new(0, 12, 0, y), q.name, 16, Color3.fromRGB(240, 248, 255), questsPanel)
		local claim = button(q.id .. "Claim", UDim2.new(0, 180, 0, 34), UDim2.new(1, -192, 0, y - 4), "CLAIM", questsPanel)
		claim.BackgroundColor3 = Color3.fromRGB(170, 255, 110)
		claim.TextColor3 = Color3.fromRGB(20, 60, 20)
		claim.MouseButton1Click:Connect(function()
			actionRemote:FireServer("claimQuest", q.id)
		end)
		questRows[q.id] = { button = claim, label = nil }
		y += 52
	end
end

local rebirthInfo = label("RebirthInfo", UDim2.new(1, -24, 0, 90), UDim2.new(0, 12, 0, 56),
	"", 16, Color3.fromRGB(240, 248, 255), rebirthPanel)
rebirthInfo.TextWrapped = true
local rebirthBtn = button("RebirthNow", UDim2.new(0, 220, 0, 44), UDim2.new(0.5, -110, 0, 170), "REBIRTH NOW", rebirthPanel)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
rebirthBtn.TextColor3 = Color3.fromRGB(60, 40, 0)
rebirthBtn.MouseButton1Click:Connect(function()
	actionRemote:FireServer("rebirth")
end)

-- State
local lastBubbles = 0
local lastSnapshot = nil
local tickCount = 0

stateRemote.OnClientEvent:Connect(function(snap)
	lastSnapshot = snap
	tickCount += 1
	Juice.countUp(moneyLabel, lastBubbles, snap.bubbles, 0.6)
	lastBubbles = snap.bubbles
	perSecondLabel.Text = "+$" .. commas(snap.perSecond) .. "/s"
	indexLabel.Text = "INDEX " .. tostring(snap.indexCount) .. "/" .. tostring(snap.indexTotal)
		.. "  (+" .. tostring(snap.indexCount) .. "% income)"
	-- Upgrades
	for _, u in ipairs(Config.UPGRADES) do
		local level = snap.upgrades[u.id] or 0
		local buy = upgradeRows[u.id]
		if buy then
			if level >= u.maxLevel then
				buy.Text = "MAX (" .. tostring(level) .. "/" .. tostring(u.maxLevel) .. ")"
			else
				buy.Text = "BUY $" .. commas(Config.upgradeCost(u, level + 1)) .. "  (Lv " .. tostring(level) .. ")"
			end
		end
	end
	-- Index owned highlight
	local ownedSet = {}
	for _, c in ipairs(snap.owned) do
		ownedSet[c.index] = true
	end
	for i, cell in ipairs(indexCells) do
		if ownedSet[i] then
			cell.BackgroundColor3 = Color3.fromRGB(40, 120, 90)
		else
			cell.BackgroundColor3 = Color3.fromRGB(20, 70, 90)
		end
	end
	-- Quests
	for _, q in ipairs(snap.quests) do
		local row = questRows[q.id]
		if row then
			if q.claimed then
				row.button.Text = "DONE"
			elseif q.progress >= q.target then
				row.button.Text = "CLAIM $" .. commas(q.reward)
			else
				row.button.Text = commas(q.progress) .. "/" .. commas(q.target)
			end
		end
	end
	-- Rebirth
	rebirthInfo.Text = "Rebirths: " .. tostring(snap.rebirths) .. "  (+"
		.. tostring(snap.rebirths * 25) .. "% income)\nEarned since rebirth: $"
		.. commas(snap.rebirthProgress) .. " / $" .. commas(snap.rebirthTarget)
		.. "\nRebirth resets your Bubbles and your base, but keeps your index and upgrades."
	rebirthBtn.Visible = snap.canRebirth
	-- Lock button
	if snap.lockRemaining > 0 then
		lockBtn.Text = "LOCKED " .. tostring(math.ceil(snap.lockRemaining)) .. "s"
	elseif snap.lockCooldownRemaining > 0 then
		lockBtn.Text = "LOCK (" .. tostring(math.ceil(snap.lockCooldownRemaining)) .. "s)"
	else
		lockBtn.Text = "LOCK BASE"
	end
	-- Floating income label every 3rd tick, at the character.
	if tickCount % 3 == 0 and snap.perSecond > 0 then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			Juice.floatLabel(root, "+$" .. commas(snap.perSecond) .. "/s", Color3.fromRGB(120, 255, 140))
		end
	end
end)

-- Juice events from the server
juiceRemote.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "event" then
		Juice.eventBanner(a, b, c)
	elseif kind == "deposit" then
		Juice.pop(moneyPill, 1.12, 0.2)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			Juice.floatLabel(root, "+$" .. commas(a or 0), Color3.fromRGB(255, 214, 140))
		end
	elseif kind == "steal" then
		Juice.addShake(0.5)
		Juice.eventBanner("STOLEN!", "A critter was taken from your base!", Color3.fromRGB(255, 90, 90))
	elseif kind == "hurt" then
		Juice.addShake(0.3)
		Juice.hitStop(0.06)
	end
end)

-- Proximity prompt + E to interact
local function nearestAction()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local world = workspace:WaitForChild("World")
	for _, model in ipairs(world:GetChildren()) do
		if model:IsA("Model") and string.sub(model.Name, 1, 4) == "Plot" then
			local sellPad = model:FindFirstChild("SellPad")
			if sellPad then
				local d = (root.Position - sellPad.Position).Magnitude
				if d < nearestSellDist then
					nearestSellDist = d
					nearestSell = sellPad
				end
			end
			-- Deposit only on the player's OWN plot (sign carries their name).
			local sign = model:FindFirstChild("Sign")
			local signGui = sign and sign:FindFirstChildOfClass("SurfaceGui")
			local signLabel = signGui and signGui:FindFirstChildOfClass("TextLabel")
			if signLabel and string.find(signLabel.Text, player.DisplayName, 1, true) then
				local floorPart = model:FindFirstChild("Floor")
				if floorPart then
					local d = (root.Position - floorPart.Position).Magnitude
					if d < 30 then
						return { kind = "deposit", dist = d }
					end
				end
			end
		end
	end
	if nearestSell then
		return { kind = "sell", dist = nearestSellDist }
	end
	return nil
end

RunService.Heartbeat:Connect(function()
	local action = nearestAction()
	if action then
		if action.kind == "deposit" then
			promptLabel.Text = "[E]  DEPOSIT critter on a pedestal"
		else
			promptLabel.Text = "[E]  SELL carried critter (80%)"
		end
	else
		promptLabel.Text = ""
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		local action = nearestAction()
		if action then
			actionRemote:FireServer(action.kind)
		end
	elseif input.KeyCode == Enum.KeyCode.L then
		actionRemote:FireServer("lock")
	end
end)
