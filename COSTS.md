# Costing, store fees, and tools — [App name]

Companion to [PRD.md](PRD.md). Moved out of the PRD so pricing can change without touching product requirements.

Figures as of **September 2026**. Prices, store rules, and Firebase quotas change. Re-check [Apple Developer](https://developer.apple.com), [Google Play](https://play.google.com/console), and [Firebase pricing](https://firebase.google.com/pricing) before you pay.

Two different “Apple/Google” costs: **developer accounts** (required) vs **store commission** (only if you sell digital goods).

---

## A. Required spend to ship

| Item | Cost | Notes |
|------|------|--------|
| Apple Developer Program | **$99 USD / year** | App Store, TestFlight, Sign in with Apple. Local tax/GST may apply. Individual or Organization: same price; Organization needs D-U-N-S. Lapse → app removed. |
| Google Play Console | **$25 USD once** | Non-refundable. No yearly fee. New **personal** accounts: **12 testers opted in for 14 continuous days** before production. Budget 2–4 weeks for first Play launch. |
| Google / Apple sign-in | **$0** | Do **not** enable phone/SMS auth through V1 (per-SMS billing). |
| Flutter, Android Studio, Xcode, GitHub | **$0** | |
| Firebase Analytics, Crashlytics, FCM, App Check (quotas) | **$0** | |
| Privacy policy + support URL | **$0** with a simple hosted page | Required by stores. Generators ~$0–20/month optional. Domain ~$10–15/year optional. |
| Figma | **$0** to view the design system | Paid only for extra seats. |
| Mac | **$0 if you already have one** | Required for iOS. Largest hardware wildcard. |

**Year-1 software fees with a Mac:** about **$99 + $25 = $124** plus tax. Recurring: **~$99/year** (Apple only).

## B. Firebase / Google Cloud (usage)

| Plan | Meaning |
|------|---------|
| Spark | Free, hard caps, no card. Fine if seed images are **in the app**. |
| Blaze | Pay as you go. Same free quotas; **$0 bill** if you stay under them. Set **budget alerts at $10 and $25**. |

**Always $0 on this stack:** Analytics, Crashlytics, Cloud Messaging, Performance Monitoring, A/B Testing, In-App Messaging.

**Auth (anonymous, Google, Apple):** free for early usage. If you later enable **Identity Platform**, first **50,000 MAU/month** are $0, then about **$0.0055 per extra MAU** (50k–100k band). Anonymous opens count as MAU. Do not enable Identity Platform until you need MFA/SAML.

**Firestore (standard edition, free quotas):** 1 GiB stored; 50,000 reads/day; 20,000 writes/day; 20,000 deletes/day; 10 GiB egress/month. Overage is Google Cloud list price (order of magnitude: ~$0.06 / 100k reads, ~$0.18 / 100k writes, ~$0.18 / GB-month — confirm region on the calculator).

**Stay cheap:** the recipe catalog is **bundled in the app** and only updates are read from Firestore; bundle seed images; no phone auth; budget alerts on Blaze.

| Scale (catalog bundled) | Expected bill |
|-----------------------------|---------------|
| You + testers | **$0** (Spark OK) |
| ~500–1,000 DAU | **$0 to a few dollars/month** if reads stay near quota |
| ~10,000 DAU | **Tens of dollars/month**, not hundreds |
| ~50,000 MAU | Auth still $0 without Identity Platform; Firestore maybe **~$50–150/month** depending on listeners |

Naive “load all recipes from cloud on every screen” will blow the read quota. The architecture prevents that ([ARCHITECTURE.md §6](ARCHITECTURE.md#6-data-cloud-vs-phone)).

**Cloud Storage:** as of **3 February 2026**, Storage requires **Blaze** even at tiny volume. Through V1: **bundle images, stay on Spark**. Add Storage in V2 with a budget cap.

**Remote Config** paid overage starts **1 September 2026** after 100,000 fetches/day. Skip through V1. Cloud Functions need Blaze; skip through V1.

New Google Cloud accounts sometimes include **$300 credit** — bonus, not a plan.

## C. If you later charge users (V2)

This is **IAP / subscription**, not the $99 Apple Developer fee.

- Through V1: **free app**, **0%** store commission
- V2 options: optional subscription (extra household, extra collections). Digital goods **must** use App Store / Play billing (no Razorpay inside the app for digital features)
- **Apple:** enroll in [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/) (under $1M prior-year proceeds) for **15%** from day one; otherwise 30% year 1 of a subscription, 15% after 12 months for that subscriber
- **Google Play:** subscriptions typically ~**15%** effective for small developers using Play Billing
- Example: ₹99/month → on the order of **₹84** after 15%, then GST if applicable
- **RevenueCat:** only when you actually sell subscriptions

EU App Store terms changed in 2026 (commission on digital sales). A **free** app with no digital sales does not owe install-based Core Technology Fee at our scale. Re-check if you add IAP and EU distribution.

## D. Tools inventory

**Required to build and ship V1**

- Flutter SDK + Dart
- Android Studio / SDK / emulator
- Xcode + Simulator (Mac)
- IDE of choice
- Git + GitHub
- Apple Developer + App Store Connect + TestFlight
- Google Play Console
- Firebase: Auth, Firestore, Analytics, Crashlytics
- Google Cloud: OAuth clients, SHA-1/256, billing alerts
- Sign in with Apple capability + Service ID
- Figma (view design system)
- Privacy policy page + support email
- Android keystore; Apple certificates (Xcode)

**Strongly recommended, $0**

- Firebase App Check
- Google Cloud budget alerts
- Firestore security rules + indexes
- Release checklist (Fastlane optional)
- TestFlight + 12 Play closed testers

**Do not budget as required for V1**

- Cloud Storage, Functions, FCM, Remote Config
- Codemagic / GitHub Actions macOS minutes
- Custom domain, Google Workspace
- Paid Figma, Mixpanel, Sentry, AdMob, RevenueCat
- Professional photography and legal review (plan for them; not day-one tools)
- D-U-N-S / Organization accounts if you publish as a company

## E. Suggested personal budget

- **Before first store submission:** $0–25 (Play when close to launch); Apple $99 when you need TestFlight / Sign in with Apple on device
- **Launch year:** ~$124 store fees + $0–10/month Firebase with alerts + privacy page
- **Hardware wildcard:** Mac
- **Do not pre-pay:** Mixpanel, VPS, SMS auth, Identity Platform, IAP infra

---

*End of costs.*
