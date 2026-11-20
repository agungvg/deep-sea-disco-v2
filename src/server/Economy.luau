-- Deep Sea Disco v2 — Economy (fresh rewrite, 2026-11-20)
-- Owns all player state: Bubbles, owned critters, upgrades, rebirths,
-- quests, index, locks. DataStore guarded with pcall everywhere so a
-- save/load failure can never break the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Economy = {}
local states = {}
local feverUntil = 0
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("DSD2_PlayerData_v1")
end)

local function defaultState()
	return {
		Bubbles = 0,
		TotalEarned = 0,
		EarnedSinceRebirth = 0,
		Collected = 0,
		Index = {}, -- [index] = true
		IndexCount = 0,
		Owned = {}, -- {id, index, mutation, income}
		Upgrades = { fins = 0, net = 0, amp = 0, lure = 0 },
		Rebirths = 0,
		Quests = {}, -- [id] = {claimed = bool}
		LockUntil = 0,
		LockCooldownUntil = 0,
		StealCooldownUntil = 0,
	}
end

function Economy.getState(player)
	local s = states[player]
	if not s then
		s = defaultState()
		states[player] = s
	end
	return s
end

function Economy.setFever(untilTime)
	feverUntil = untilTime
end

function Economy.isFever()
	return os.clock() < feverUntil
end

function Economy.feverRemaining()
	return math.max(0, feverUntil - os.clock())
end

function Economy.carrySlots(player)
	local s = Economy.getState(player)
	return Config.CARRY_BASE + (s.Upgrades.net or 0)
end

function Economy.walkSpeed(player)
	local s = Economy.getState(player)
	return 16 + 4 * (s.Upgrades.fins or 0)
end

function Economy.mutationLuck(player)
	local s = Economy.getState(player)
	return 1 + 0.25 * (s.Upgrades.lure or 0)
end

function Economy.incomePerSecond(player)
	local s = Economy.getState(player)
	local base = 0
	for _, c in ipairs(s.Owned) do
		base += c.income
	end
	local mult = 1
	mult *= 1 + 0.10 * (s.Upgrades.amp or 0)
	mult *= 1 + Config.INDEX_BONUS_PER_CRITTER * s.IndexCount
	mult *= 1 + Config.REBIRTH_MULTIPLIER * s.Rebirths
	if Economy.isFever() then
		mult *= 2
	end
	return math.floor(base * mult + 0.5)
end

function Economy.addBubbles(player, amount)
	local s = Economy.getState(player)
	s.Bubbles += amount
	if amount > 0 then
		s.TotalEarned += amount
		s.EarnedSinceRebirth += amount
	end
end

-- Adds a critter to the player's owned list (called on deposit).
-- Returns the owned entry, or nil if the player already owns 12.
function Economy.addOwned(player, index, mutation, income)
	local s = Economy.getState(player)
	if #s.Owned >= Config.MAX_PEDESTALS then
		return nil
	end
	local entry = {
		id = HttpService:GenerateGUID(false),
		index = index,
		mutation = mutation or "",
		income = income,
	}
	table.insert(s.Owned, entry)
	s.Collected += 1
	if not s.Index[index] then
		s.Index[index] = true
		s.IndexCount += 1
	end
	return entry
end

function Economy.removeOwned(player, id)
	local s = Economy.getState(player)
	for i, c in ipairs(s.Owned) do
		if c.id == id then
			table.remove(s.Owned, i)
			return c
		end
	end
	return nil
end

function Economy.hasLegendary(player)
	local s = Economy.getState(player)
	for _, c in ipairs(s.Owned) do
		if Config.tierOf(c.index) >= 5 then
			return true
		end
	end
	return false
end

function Economy.questProgress(player, quest)
	local s = Economy.getState(player)
	if quest.kind == "collect" then
		return math.min(s.Collected, quest.target)
	elseif quest.kind == "earn" then
		return math.min(s.TotalEarned, quest.target)
	elseif quest.kind == "legendary" then
		return Economy.hasLegendary(player) and 1 or 0
	end
	return 0
end

function Economy.snapshot(player)
	local s = Economy.getState(player)
	local owned = {}
	for _, c in ipairs(s.Owned) do
		table.insert(owned, { id = c.id, index = c.index, mutation = c.mutation, income = c.income })
	end
	local quests = {}
	for _, q in ipairs(Config.QUESTS) do
		local qstate = s.Quests[q.id] or {}
		table.insert(quests, {
			id = q.id,
			name = q.name,
			target = q.target,
			reward = q.reward,
			progress = Economy.questProgress(player, q),
			claimed = qstate.claimed == true,
		})
	end
	return {
		bubbles = s.Bubbles,
		perSecond = Economy.incomePerSecond(player),
		indexCount = s.IndexCount,
		indexTotal = #Config.CRITTERS,
		owned = owned,
		upgrades = s.Upgrades,
		rebirths = s.Rebirths,
		quests = quests,
		lockUntil = s.LockUntil,
		lockCooldownUntil = s.LockCooldownUntil,
		lockRemaining = math.max(0, s.LockUntil - os.clock()),
		lockCooldownRemaining = math.max(0, s.LockCooldownUntil - os.clock()),
		feverRemaining = Economy.feverRemaining(),
		canRebirth = s.EarnedSinceRebirth >= Config.REBIRTH_REQUIRE_EARNED and s.Rebirths < Config.REBIRTH_MAX,
		rebirthProgress = math.min(s.EarnedSinceRebirth, Config.REBIRTH_REQUIRE_EARNED),
		rebirthTarget = Config.REBIRTH_REQUIRE_EARNED,
	}
end

function Economy.save(player)
	local s = states[player]
	if not s or not store then
		return
	end
	local data = {
		Bubbles = s.Bubbles,
		TotalEarned = s.TotalEarned,
		EarnedSinceRebirth = s.EarnedSinceRebirth,
		Collected = s.Collected,
		Index = s.Index,
		Owned = s.Owned,
		Upgrades = s.Upgrades,
		Rebirths = s.Rebirths,
		Quests = s.Quests,
	}
	pcall(function()
		store:SetAsync("player_" .. tostring(player.UserId), data)
	end)
end

function Economy.load(player)
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync("player_" .. tostring(player.UserId))
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	local s = Economy.getState(player)
	if type(data.Bubbles) == "number" then s.Bubbles = data.Bubbles end
	if type(data.TotalEarned) == "number" then s.TotalEarned = data.TotalEarned end
	if type(data.EarnedSinceRebirth) == "number" then s.EarnedSinceRebirth = data.EarnedSinceRebirth end
	if type(data.Collected) == "number" then s.Collected = data.Collected end
	if type(data.Rebirths) == "number" then s.Rebirths = data.Rebirths end
	if type(data.Index) == "table" then
		s.Index = data.Index
		local count = 0
		for _ in pairs(s.Index) do count += 1 end
		s.IndexCount = count
	end
	if type(data.Owned) == "table" then s.Owned = data.Owned end
	if type(data.Upgrades) == "table" then
		for k, v in pairs(data.Upgrades) do
			if s.Upgrades[k] ~= nil and type(v) == "number" then
				s.Upgrades[k] = v
			end
		end
	end
	if type(data.Quests) == "table" then s.Quests = data.Quests end
end

-- Income tick + autosave. Runs on the server only.
function Economy.start(stateRemote)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local perSecond = Economy.incomePerSecond(player)
				if perSecond > 0 then
					Economy.addBubbles(player, perSecond)
				end
				stateRemote:FireClient(player, Economy.snapshot(player))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				Economy.save(player)
			end
		end
	end)
end

function Economy.clearOnLeave(player)
	Economy.save(player)
	states[player] = nil
end

return Economy
