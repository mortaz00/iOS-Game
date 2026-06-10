# 💎 Gem Miner — Idle Mining Game for iOS

A complete, ready-to-build idle/tap game in SwiftUI, monetized with
**rewarded video ads** (AdMob) and **in-app purchases** (StoreKit 2), and
built around the reward-psychology loops that drive retention in top-grossing
idle games.

| | |
|---|---|
| 🎮 Core loop | Tap to mine crystals → buy auto-miners → prestige for permanent bonuses |
| 🎰 Dopamine | Critical taps (5% ×10), random Lucky Comet events, milestone doublings |
| 🔥 Habit | 7-day escalating daily streak, 8h-capped offline earnings |
| 📺 Ads | 4 rewarded placements (offline ×2, 4h boost, comet mega-reward, free gems) |
| 💰 IAP | Gem packs, limited-time starter pack, remove ads, permanent ×2 |

> **Note — current design direction:** the design has since evolved into
> **Gem Miner: Deep Descent**, a drill-mining game with real gameplay and a
> social layer (async raids, leaderboard, friends). The playable prototype
> lives in [`preview/index.html`](preview/index.html) and deploys to GitHub
> Pages via `.github/workflows/pages.yml` (enable in Settings → Pages →
> Source: *GitHub Actions*). The SwiftUI code in `GemMiner/` reflects the
> earlier idle-tapper design; once the prototype's mechanics are approved
> it will be ported to SpriteKit. The monetization layer
> (`GemMiner/Monetization/`) carries over unchanged.

Design rationale: [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) ·
Monetization & compliance: [`docs/MONETIZATION.md`](docs/MONETIZATION.md)

## Build & run

Requires a Mac with Xcode 15+. The Xcode project is generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open GemMiner.xcodeproj
```

Then build and run on the iOS Simulator. Everything works immediately:

- **Ads**: AdMob ships with Google's official *test* ad units. If the SDK or
  network is unavailable, a built-in simulated ad plays instead, so the whole
  reward loop is always testable.
- **Purchases**: in Xcode, edit the scheme → Run → Options → StoreKit
  Configuration → select `GemMiner/Resources/Products.storekit` to test all
  six products locally with no App Store account.

## Before shipping

1. Set your real bundle ID in `project.yml`.
2. Create an AdMob app + rewarded ad unit; replace `GADApplicationIdentifier`
   in `project.yml` and `rewardedUnitID` in
   `GemMiner/Monetization/AdMobProvider.swift`; paste Google's full
   SKAdNetwork ID list.
3. Recreate the product IDs from `Products.storekit` in App Store Connect.
4. Add a GDPR consent flow (Google UMP) and your privacy policy.
5. Work through the compliance checklist in `docs/MONETIZATION.md`.

## Project layout

```
GemMiner/
├── App/            GemMinerApp.swift — entry point, scene lifecycle
├── Models/         GameState (economy + persistence), BalanceConfig (all
│                   tuning numbers), DailyRewardManager, RandomEventManager
├── Monetization/   AdsManager (+ simulated fallback), AdMobProvider,
│                   StoreManager (StoreKit 2)
├── Views/          Mine / Upgrades / Shop / Prestige tabs, reward sheets
├── Utilities/      Haptics, compact number formatting
└── Resources/      Products.storekit test catalog
```

All game-economy tuning lives in one file: `GemMiner/Models/BalanceConfig.swift`.
