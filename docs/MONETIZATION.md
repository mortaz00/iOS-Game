# Gem Miner — Monetization Design

Two revenue streams, both implemented: **rewarded video ads** (AdMob) and
**in-app purchases** (StoreKit 2). The design principle: every monetization
touchpoint must *feel like a gift*, not a toll.

## Rewarded ad placements

Rewarded ads convert best when offered at a moment of desire. The four
placements, in typical order of revenue contribution:

| Placement | Offer | Why it converts | Code |
|-----------|-------|-----------------|------|
| Offline doubler | ×2 your away earnings | Shown at app open, biggest visible number of the session | `OfflineEarningsView` |
| Production boost | ×2 everything for 4h | Always-visible button on main screen when inactive | `MineView.boostButton` |
| Lucky Comet | ×7 tap frenzy + gems vs. a small free option | Scarcity (12s window) + contrast against the small reward | `CometOfferView` |
| Free gems | 25 gems / 15-min cooldown | Teaches gem value to non-payers; cooldown protects eCPM | `StoreView.freeSection` |

Notes:
- The SDK ships pointed at **Google's official test IDs**. Before release,
  create your own app + ad units in the AdMob console, replace
  `GADApplicationIdentifier` in `project.yml` and `rewardedUnitID` in
  `AdMobProvider.swift`.
- A simulated-ad fallback (`AdsManager`) keeps the full loop testable with
  no SDK or network — also useful for UI tests.
- Interstitials are deliberately absent from v1. They depress retention in
  idle games; add them only after measuring, and gate them behind
  `hasRemoveAds` if you do.

## IAP catalog

| Product | Type | Price | Role |
|---------|------|-------|------|
| Fistful of Gems (120) | Consumable | $1.99 | Entry price point |
| Sack of Gems (700) | Consumable | $7.99 | "Best seller" anchor |
| Gem Vault (4000) | Consumable | $29.99 | Whale tier; makes $7.99 look cheap (anchoring) |
| Starter Pack | Non-consumable | $3.99 | 300 gems + 24h boost, only offered in the first 48h — converts players into *payers* early, which is the single biggest predictor of LTV |
| Remove Ads | Non-consumable | $4.99 | Insurance product; also signals fairness |
| Permanent ×2 | Non-consumable | $9.99 | The "patron" purchase for engaged non-gem-buyers |

Gems sink into **Time Warps** (instant production hours), which scale with
the player's own economy — so gem value never goes stale.

`GemMiner/Resources/Products.storekit` mirrors this catalog for local
testing (Xcode scheme → StoreKit Configuration). Recreate the same product
IDs in App Store Connect for production.

## KPIs to instrument before launch

- D1 / D7 / D30 retention (the genre lives or dies on D1 > 40%)
- Rewarded-ad engagement rate (target: >30% of DAU watch ≥1/day)
- Conversion to payer, time-to-first-purchase, ARPDAU
- Session count/day and session length (idle games want *many short* sessions)

Add an analytics SDK (e.g. Firebase) and log: `ad_watched(placement)`,
`iap_purchased(product)`, `prestige`, `streak_day`, `comet_caught`.

## Compliance checklist

- [ ] App Tracking Transparency prompt (implemented) + Privacy Nutrition Label
- [ ] `SKAdNetworkItems`: paste Google's full current list into `project.yml`
      (only the primary ID is included now)
- [ ] Google UMP / GDPR consent flow for EEA users before ad serving
- [ ] Age rating: this monetization stack requires a non-kids rating
- [ ] "Restore Purchases" visible (implemented — Shop and Settings)
- [ ] Loot-box style mechanics: none present; if you add gacha later,
      several markets require disclosure of odds
