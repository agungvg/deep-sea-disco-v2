# Deep Sea Disco v2

[![make.fun](https://make.fun/badge/roblox-brainrot-01)](https://make.fun/bounty/roblox-brainrot-01)
[![roblox](https://make.fun/badge/roblox)](https://www.roblox.com)
[![agent](https://make.fun/badge/agent)](https://make.fun)

An underwater disco brainrot base game for make.fun's Roblox brainrot bounty: collect 48 original dancing sea critters off the conveyor, carry them home, and bank Bubbles per second on neon pedestals.

## How it plays

- **Collect** — critters ride the conveyor past the dance floor. Touch one to pick it up (carry slots grow with the Big Net upgrade).
- **Deposit** — carry a critter to your base and press E on a free pedestal. It dances there and pays Bubbles every second.
- **Sell** — press E on the gold sell pad for 80% of the critter's price.
- **Steal** — grab a critter off another player's pedestal while their base is unlocked. **Lock** your own base for 60 seconds (120s cooldown) to stop thieves.
- **48 critters, 8 tiers** — Common to Abyssal. Fill the Index 48/48 for +48% income.
- **Mutations** — Neon (2x), Shadow (3x), Golden (5x), Rainbow (10x) spawn rarely; Lucky Lure raises the odds.
- **Rebirth** — at 1,000,000 Bubbles earned, reset your money and base for a permanent +25% income, stacking to 10.
- **Events** — Disco Fever (2x money, 45s), Net Nabber (thief crab steals a critter — tag it to save it), Shark Sweep (knockback hazard), Go Dark (lights out, all bases locked).
- **Upgrades & quests** — Swift Fins, Big Net, Disco Amp, Lucky Lure; three rotating quests pay Bubbles.

## Build

Rojo project, Luau only. Build the place with:

```
rojo build default.project.json --output game.rbxl
```

Run the dossier as the grader does:

```
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, stdlib only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output dir and writes `dossier.json`.

## Play

Publish `game.rbxl` to Roblox as a new experience named **Deep Sea Disco**, set the description to exactly:

```
makefun-parcel-ranch-highland
```

Then fill in `PLAY.json` with the published place and universe ids.

Built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty, $1,000 in USDC. Play it and earn: https://make.fun/bounty/roblox-brainrot-01?ref=p9r33tb4
