-- Deep Sea Disco v2 — shared config (fresh rewrite, 2026-11-20)
-- 48 original dancing sea critters, 8 tiers x 6. Prices follow an
-- exponential curve from $25 to $2,000,000; income = price / 40 (min 1).
-- Nothing here is copied from any earlier version: names, numbers and
-- structure were written fresh for this rebuild.

local Config = {}

Config.CURRENCY_NAME = "Bubbles"
Config.SELL_FRACTION = 0.8
Config.MAX_PEDESTALS = 12
Config.CARRY_BASE = 1
Config.INDEX_BONUS_PER_CRITTER = 0.01 -- +1% income per distinct critter, 48/48 = +48%
Config.REBIRTH_REQUIRE_EARNED = 1000000
Config.REBIRTH_MULTIPLIER = 0.25 -- +25% income per rebirth, stacks
Config.REBIRTH_MAX = 10
Config.LOCK_DURATION = 60
Config.LOCK_COOLDOWN = 120

-- Palette: deep teal/navy + coral + sand + lime
Config.PALETTE = {
	DeepWater = Color3.fromRGB(7, 34, 58),
	Teal = Color3.fromRGB(10, 92, 110),
	Aqua = Color3.fromRGB(28, 170, 190),
	Coral = Color3.fromRGB(255, 107, 107),
	Sand = Color3.fromRGB(255, 214, 140),
	Lime = Color3.fromRGB(170, 255, 110),
	Pink = Color3.fromRGB(255, 120, 200),
	Purple = Color3.fromRGB(150, 100, 255),
	Gold = Color3.fromRGB(255, 205, 60),
	White = Color3.fromRGB(240, 248, 255),
}

Config.TIERS = {
	{ name = "Common", color = Color3.fromRGB(190, 220, 230), multiplier = 1 },
	{ name = "Uncommon", color = Color3.fromRGB(120, 255, 140), multiplier = 1 },
	{ name = "Rare", color = Color3.fromRGB(90, 170, 255), multiplier = 1 },
	{ name = "Epic", color = Color3.fromRGB(190, 110, 255), multiplier = 1 },
	{ name = "Legendary", color = Color3.fromRGB(255, 205, 60), multiplier = 1 },
	{ name = "Mythic", color = Color3.fromRGB(255, 120, 200), multiplier = 1 },
	{ name = "Cosmic", color = Color3.fromRGB(120, 220, 255), multiplier = 1 },
	{ name = "Abyssal", color = Color3.fromRGB(140, 60, 220), multiplier = 1 },
}

-- Mutations: rare spawn variants. Chance is per spawn roll.
Config.MUTATIONS = {
	{ name = "Neon", chance = 0.08, incomeMult = 2, tint = Color3.fromRGB(80, 255, 220) },
	{ name = "Shadow", chance = 0.04, incomeMult = 3, tint = Color3.fromRGB(90, 60, 160) },
	{ name = "Golden", chance = 0.015, incomeMult = 5, tint = Color3.fromRGB(255, 205, 60) },
	{ name = "Rainbow", chance = 0.005, incomeMult = 10, tint = Color3.fromRGB(255, 120, 200) },
}

-- Upgrades: 4 tracks. Cost grows per level.
Config.UPGRADES = {
	{
		id = "fins", name = "Swift Fins", desc = "+4 walk speed per level",
		maxLevel = 5, baseCost = 500, costMult = 2,
	},
	{
		id = "net", name = "Big Net", desc = "+1 carry slot per level",
		maxLevel = 3, baseCost = 1000, costMult = 3,
	},
	{
		id = "amp", name = "Disco Amp", desc = "+10% income per level",
		maxLevel = 5, baseCost = 2000, costMult = 2.5,
	},
	{
		id = "lure", name = "Lucky Lure", desc = "+25% mutation chance per level",
		maxLevel = 4, baseCost = 5000, costMult = 2,
	},
}

-- Quests: simple rotating objectives with flat rewards.
Config.QUESTS = {
	{ id = "collect15", name = "Collect 15 critters", target = 15, reward = 5000, kind = "collect" },
	{ id = "earn100k", name = "Earn 100,000 Bubbles", target = 100000, reward = 10000, kind = "earn" },
	{ id = "legendary", name = "Own a Legendary+ critter", target = 1, reward = 25000, kind = "legendary" },
}

-- Critter data. body: dome | torpedo | curved | wide | long | round.
-- Every critter is human-proportioned: one cohesive body, a head that
-- belongs to that body (no round head floating on a boxy torso).
-- accessory: none | headphones | crown | bowtie | shades | discoball | top hat
local function C(name, body, primary, accent, accessory)
	return { name = name, body = body, primary = primary, accent = accent, accessory = accessory }
end

Config.CRITTERS = {
	-- Common (1-6)
	C("Bubbles McFin", "torpedo", Color3.fromRGB(90, 180, 230), Color3.fromRGB(255, 214, 140), "none"),
	C("Shelly Shuffle", "dome", Color3.fromRGB(255, 170, 140), Color3.fromRGB(255, 230, 200), "bowtie"),
	C("Guppy Groove", "torpedo", Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 120, 120), "none"),
	C("Coral Carl", "wide", Color3.fromRGB(255, 107, 107), Color3.fromRGB(255, 214, 140), "shades"),
	C("Sandy Steps", "round", Color3.fromRGB(240, 210, 160), Color3.fromRGB(120, 200, 220), "none"),
	C("Pearl Pat", "dome", Color3.fromRGB(240, 240, 250), Color3.fromRGB(180, 140, 255), "none"),
	-- Uncommon (7-12)
	C("Jelly Jam", "dome", Color3.fromRGB(255, 120, 200), Color3.fromRGB(255, 220, 240), "headphones"),
	C("Disco Shrimp", "curved", Color3.fromRGB(255, 140, 110), Color3.fromRGB(255, 205, 60), "discoball"),
	C("Tango Turtle", "dome", Color3.fromRGB(90, 200, 130), Color3.fromRGB(255, 214, 140), "top hat"),
	C("Salsa Seahorse", "curved", Color3.fromRGB(255, 190, 90), Color3.fromRGB(255, 107, 107), "none"),
	C("Boogie Barnacle", "round", Color3.fromRGB(170, 190, 210), Color3.fromRGB(120, 255, 140), "shades"),
	C("Mambo Mussel", "dome", Color3.fromRGB(120, 120, 220), Color3.fromRGB(170, 255, 110), "bowtie"),
	-- Rare (13-18)
	C("Electric Eelvis", "long", Color3.fromRGB(255, 230, 80), Color3.fromRGB(90, 180, 255), "headphones"),
	C("Funky Flounder", "wide", Color3.fromRGB(200, 140, 255), Color3.fromRGB(255, 205, 60), "none"),
	C("Twist Tuna", "torpedo", Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 255, 255), "shades"),
	C("Swing Starfish", "wide", Color3.fromRGB(255, 150, 90), Color3.fromRGB(255, 220, 150), "bowtie"),
	C("Samba Squid", "dome", Color3.fromRGB(255, 130, 180), Color3.fromRGB(140, 230, 255), "none"),
	C("Limbo Lobster", "curved", Color3.fromRGB(255, 90, 80), Color3.fromRGB(255, 205, 60), "top hat"),
	-- Epic (19-24)
	C("Neon Narwhal", "torpedo", Color3.fromRGB(120, 240, 255), Color3.fromRGB(255, 120, 200), "discoball"),
	C("Groovy Grouper", "round", Color3.fromRGB(150, 220, 120), Color3.fromRGB(255, 230, 140), "shades"),
	C("Disco Dolphin", "torpedo", Color3.fromRGB(140, 200, 255), Color3.fromRGB(255, 205, 60), "headphones"),
	C("Funk Octopus", "dome", Color3.fromRGB(180, 110, 230), Color3.fromRGB(120, 255, 140), "bowtie"),
	C("Rave Reefshark", "torpedo", Color3.fromRGB(120, 140, 200), Color3.fromRGB(255, 90, 90), "shades"),
	C("Boogie Barracuda", "long", Color3.fromRGB(190, 210, 230), Color3.fromRGB(255, 205, 60), "none"),
	-- Legendary (25-30)
	C("The Abyssal DJ", "dome", Color3.fromRGB(60, 40, 120), Color3.fromRGB(255, 205, 60), "discoball"),
	C("King Krill", "curved", Color3.fromRGB(255, 180, 60), Color3.fromRGB(255, 240, 180), "crown"),
	C("Queen Conch", "dome", Color3.fromRGB(255, 170, 220), Color3.fromRGB(255, 255, 255), "crown"),
	C("DJ Plankton", "round", Color3.fromRGB(140, 255, 200), Color3.fromRGB(255, 120, 200), "headphones"),
	C("Captain Coral", "wide", Color3.fromRGB(255, 107, 107), Color3.fromRGB(255, 230, 150), "top hat"),
	C("Madame Manta", "wide", Color3.fromRGB(90, 80, 180), Color3.fromRGB(180, 220, 255), "bowtie"),
	-- Mythic (31-36)
	C("Leviathan Lights", "long", Color3.fromRGB(80, 220, 200), Color3.fromRGB(255, 240, 150), "discoball"),
	C("Kraken Konga", "dome", Color3.fromRGB(140, 60, 180), Color3.fromRGB(255, 120, 120), "crown"),
	C("Poseidon Pop", "torpedo", Color3.fromRGB(60, 160, 255), Color3.fromRGB(255, 205, 60), "top hat"),
	C("Neptune Nights", "round", Color3.fromRGB(70, 110, 220), Color3.fromRGB(170, 255, 110), "headphones"),
	C("Siren Synth", "curved", Color3.fromRGB(255, 140, 210), Color3.fromRGB(140, 240, 255), "bowtie"),
	C("Triton Twist", "torpedo", Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 230, 90), "shades"),
	-- Cosmic (37-42)
	C("Starlight Stingray", "wide", Color3.fromRGB(180, 200, 255), Color3.fromRGB(255, 240, 160), "discoball"),
	C("Galaxy Gulper", "round", Color3.fromRGB(130, 90, 230), Color3.fromRGB(255, 150, 220), "none"),
	C("Nebula Nudibranch", "curved", Color3.fromRGB(220, 120, 255), Color3.fromRGB(120, 255, 220), "crown"),
	C("Comet Cuttlefish", "dome", Color3.fromRGB(200, 220, 255), Color3.fromRGB(255, 180, 80), "headphones"),
	C("Aurora Angler", "round", Color3.fromRGB(120, 255, 190), Color3.fromRGB(255, 120, 200), "discoball"),
	C("Pulsar Puffer", "round", Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 255, 255), "shades"),
	-- Abyssal (43-48)
	C("Void Viperfish", "long", Color3.fromRGB(50, 30, 90), Color3.fromRGB(180, 80, 255), "shades"),
	C("Eclipse Eel", "long", Color3.fromRGB(40, 40, 80), Color3.fromRGB(255, 205, 60), "crown"),
	C("Midnight Megalodon", "torpedo", Color3.fromRGB(60, 70, 110), Color3.fromRGB(255, 90, 90), "top hat"),
	C("Dark Disco Dragon", "curved", Color3.fromRGB(90, 40, 140), Color3.fromRGB(255, 120, 200), "discoball"),
	C("Shadow Serpent", "long", Color3.fromRGB(70, 60, 120), Color3.fromRGB(120, 255, 220), "bowtie"),
	C("The Deep One", "dome", Color3.fromRGB(30, 30, 70), Color3.fromRGB(255, 205, 60), "crown"),
}

function Config.tierOf(index)
	return math.clamp(math.ceil(index / 6), 1, 8)
end

function Config.priceOf(index)
	return math.max(25, math.floor(25 * (1.271 ^ (index - 1)) + 0.5))
end

function Config.incomeOf(index)
	return math.max(1, math.floor(Config.priceOf(index) / 40 + 0.5))
end

function Config.upgradeCost(upgrade, level)
	-- level is the level being bought (1-based)
	return math.floor(upgrade.baseCost * (upgrade.costMult ^ (level - 1)) + 0.5)
end

-- One frozen feel table (game-feel P-29): every feel number lives here.
Config.FEEL = table.freeze({
	ShakeAddSteal = 0.5, ShakeAddHurt = 0.3, ShakeDecay = 1.3, ShakeMaxAngle = 2.5,
	HitStopLight = 0.06, HitStopHeavy = 0.12,
	CoyoteTime = 0.12, JumpBuffer = 0.12,
	PickupPopScale = 1.25, PickupPopTime = 0.2,
	LabelRiseTime = 1.1, LabelRiseHeight = 2.5,
	BannerInTime = 0.35, BannerHoldTime = 2.6,
	SquashAmount = 0.3, SquashTime = 0.12,
	CountUpTime = 0.6, ParticleBurst = 12,
})

return Config
