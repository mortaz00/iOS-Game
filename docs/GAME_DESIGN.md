# Gem Miner — Game & Engagement Design

Gem Miner is an idle/tap mining game. The genre was chosen deliberately: idle
games have the purest "core loop" in mobile gaming (tap → number goes up →
buy upgrade → number goes up faster), which makes every engagement and
monetization system easy to attach and easy to tune.

## The core loop

```
TAP gem → earn crystals → buy miners/upgrades → production grows
   ↑                                                    │
   └──────────── bigger numbers feel great ←────────────┘
```

Long loop: reach 1M crystals → **Prestige** → reset run for permanent +10%
shards → climb back faster → repeat.

## How each mechanic maps to reward psychology

The four "feel-good chemicals" the design targets, and the mechanics built
for each (file references point at the implementation):

### Dopamine — anticipation & variable rewards
Dopamine responds most strongly to *unpredictable* rewards (variable-ratio
schedules — the slot machine effect) and to anticipation of progress.

- **Critical taps**: 5% chance of a ×10 crit with a big golden floater and a
  heavy haptic (`Balance.critChance`, `GameState.mine()`). Every tap is a
  small lottery ticket.
- **Lucky Comet**: appears at random intervals (90–240s) and disappears in
  12 seconds if ignored (`RandomEventManager`). Variable-interval reward +
  urgency window = the strongest attention hook in the game.
- **Near-miss pricing**: exponential generator costs mean the next upgrade is
  always *almost* affordable.
- **Milestones**: every 25 levels a generator's output doubles — a visible
  upcoming spike to anticipate (`Balance.milestoneEvery`).

### Serotonin — status, progress, mastery
Serotonin tracks feelings of status and accomplishment.

- **Prestige shards** are a permanent, visible status number ("✦ +120%")
  shown on the main screen — accumulated mastery that never resets.
- **Lifetime stats** in Settings; the compact-number ladder itself (K → M →
  B → T...) is a status ladder.
- **Collection/unlock feel**: seven escalating miner types from Pickaxe
  Gnome to Black Hole Siphon.

### Oxytocin — social connection (roadmap)
Not yet implemented; the highest-value additions in order:
1. Game Center leaderboards (lifetime crystals, prestige count).
2. Gifting: send a friend a daily "lucky charm" (both get a bonus).
3. Guild/co-op mining events.

### Endorphins — sensory pleasure, "juice"
- Haptics on every meaningful event, scaled to importance (light tap → heavy
  crit → success notification on rewards) — `Haptics.swift`.
- Floating reward numbers, springy gem squash-and-stretch, glow that
  intensifies during Frenzy, pulsing comet (`MineView`, `CometButton`).
- Add sound and particles next; juice is the cheapest retention investment.

## Habit formation & retention

- **Daily streaks** (`DailyRewardManager`): escalating 7-day reward cycle.
  Day 7 pays 16× day 1. Missing a day resets the streak — loss aversion is a
  stronger motivator than the reward itself.
- **Offline earnings cap** (`Balance.offlineCapHours` = 8h at 50% rate): the
  game keeps "cooking" while away, but capping it creates an appointment —
  check in roughly twice a day or waste production.
- **Welcome-back moment** (`OfflineEarningsView`): returning always opens
  with a reward, so launching the app is itself reinforced.
- **Session-end hook**: boosts last 4h, longer than a session, so there's
  always something running that the player will want to come back to.

## Tuning knobs

Everything lives in `BalanceConfig.swift`. The three numbers that matter
most when tuning retention vs. progression speed:

| Knob | Current | Effect |
|------|---------|--------|
| `costGrowth` | 1.15 | Higher = slower progression, longer game |
| `offlineCapHours` | 8 | Lower = more check-ins per day |
| `shardBonusPerShard` | 0.10 | Higher = faster prestige loop spiral |

## Ethical guardrails

Engagement design and exploitation are separated by a few concrete rules
this project follows — they also keep you on the right side of App Store
review (guideline 3.1) and consumer-protection law in several markets:

- All ads are **opt-in rewarded ads**; nothing is gated behind forced ads.
- Real-money prices are always shown in local currency via StoreKit before
  purchase; no obfuscated multi-step currency conversions for IAP items.
- No mechanics that punish *not paying* — paying accelerates, never unlocks
  the only path.
- The streak resets state, it never destroys purchased goods.
- Settings carries a "take breaks / spend responsibly" note; if you target
  a young audience, App Store kids-category rules prohibit most of the ad
  stack here — choose your age rating deliberately.
