# Delivery plan — [App name]

**Product:** Maharashtrian meal planner, recipe book, grocery assistant, and food diary  
**App name:** `[App name]` (placeholder until chosen)  
**Bundle ID:** `[bundle.id.tbd]`  
**Sources:** [PRD.md](PRD.md), [ARCHITECTURE.md](ARCHITECTURE.md), [CONVENTIONS.md](CONVENTIONS.md), [COSTS.md](COSTS.md)

This plan covers **setup → public product → later features**. It is divided by **version**, then by **functionality**. It is not a 10-day calendar.

| Version | What it is | Who can use it |
|---------|------------|----------------|
| **Setup** | Repo, Firebase, design tokens, empty shell | Developer only |
| **MVP** | Daily loop on a real device | Internal TestFlight / APK |
| **V1** | First public store app | Play + App Store |
| **V2** | Depth: thali, regions, festivals, stats, family, nutrition, paid | Existing users |

The **domain model from MVP is the V1 model** (`meal_items[]`, ingredient IDs, history snapshots). Later versions add UI and extra documents; they do not redesign meals.

---

## Version map (functionality)

| Functionality | Setup | MVP | V1 | V2 |
|---------------|:-----:|:---:|:--:|:--:|
| Flutter + Firebase + Crashlytics + Analytics wiring | ● | | | |
| Folder tree, BLoC, injectable, `AppFont`, `Result` | ● | | | |
| Guest (anonymous) auth | | ● | | |
| Google + Apple link, same UID, no silent merge | | ● | | |
| Account delete | | ● | | |
| Onboarding (language, diet, region, household size) | | ● | | |
| Bilingual UI EN / MR / EN+MR | | ● | | |
| Recipe catalog + detail + servings | | ● | | |
| Ingredient IDs + aliases on catalog | | ● | | |
| Tolerant search | | ● | | |
| Region / season / festival / occasion **tags on data** | | ● | | |
| Home: today’s breakfast / lunch / dinner | | ● | | |
| Meal = `meal_items[]` (one recipe in UI is OK) | | ● | | |
| Cook Now + cooking mode (single recipe) | | ● | | |
| Track Planned / Cooked / Eaten / Skipped | | ● | | |
| History snapshots | | ● | | |
| Bundled catalog + Firestore persistence | | ● | | |
| Analytics consent in onboarding | | ● | | |
| Repeat setting stored (used in Cook Now) | | ● | | |
| Seed recipes (start ~15–20, grow toward 40–80 by V1) | | ● | ● | |
| Multi-item meal editor (Varan + rice + bhaji…) | | | ● | |
| Multi-item cooking session (slot-level cooked/eaten) | | | ● | |
| Manual food (tea, leftover bhaji) | | | ● | |
| Snack slots on Track | | | ● | |
| Weekly planner (generate, copy, randomize, servings) | | | ● | |
| Replace meal (same recommendation engine) | | | ● | |
| Ranked “what should I cook?” + pantry in ranking | | | ● | |
| Favourites + add to plan | | | ● | |
| Pantry CRUD + missing-ingredient match | | | ● | |
| Grocery: one list per week, derived vs manual | | | ● | |
| Serving size carried across recipe / plan / cook / shop | | | ● | |
| Full offline for plan, track, pantry, shop | | | ● | |
| Product-loop analytics (shown → selected → cooked → eaten) | | ● | ● | |
| Seed content: recipes, Marathi copy review, photos | ● | ● | ● | |
| Quiet “waiting to sync”; last-write-wins | | ● | ● | |
| Play closed test + store listings + privacy policy | | | ● | |
| Regional browse hub | | | | ● |
| Thali builder UI (uses `meal_items`) | | | | ● |
| Seasonal / festival collection screens | | | | ● |
| Food statistics | | | | ● |
| Advanced recommendation weights | | | | ● |
| Family / household profiles | | | | ● |
| Nutrition UI | | | | ● |
| FCM, Remote Config, Cloud Functions | | | | ● |
| Phone auth / MFA | | | | ● |
| Cloud Storage for remote photos | | | | ● |
| Subscriptions / ads | | | | ● |

---

## Setup — project and backend

Do this once before MVP features.

### S1. Flutter app

- `flutter create` iOS + Android  
- Bundle ID `[bundle.id.tbd]`  
- Single package, folders per [ARCHITECTURE.md](ARCHITECTURE.md): `app`, `core`, `design_system`, `localization`, `domain`, `data`, `features`, `handlers`  
- `go_router`, `flutter_bloc`, `injectable` + `get_it`, `equatable`  
- `Result<T>`, `AppException`, logger  
- Theme tokens + **`AppFont` only** for fonts  
- `main_dev.dart` (prod flavor later)

**Empty feature folders:** `auth`, `onboarding`, `home`, `recipes`, `track`, `settings`. Stubs: `plan`, `shopping`, `pantry` (filled in V1).

### S2. Firebase (dev)

- Dev project, Firestore location `asia-south1` (permanent — choose once), Spark  
- Auth: Anonymous, Google; Apple capability ready for iOS  
- Firestore + security rules (catalog read if signed in; `users/{uid}` owner only)  
- Analytics + Crashlytics (`runZonedGuarded`, `FlutterError.onError`)  
- App Check when Auth works  
- Budget alerts if/when Blaze is needed (not for seed images in-app)

No Dio, no custom API, no custom sync engine.

### S3. Content pipeline

- Recipe + ingredient JSON schema matching domain models ([ARCHITECTURE.md §6](ARCHITECTURE.md#6-data-cloud-vs-phone))  
- `assets/catalog/catalog.json` bundled in the app; bundled placeholder images  
- Small script that validates the JSON (every `ingredientId` exists, EN + MR names present, units in `commonUnits`)  
- Same script can publish updates to Firestore (`updatedAt`, `deleted` tombstones, bump `meta/catalog.catalogVersion`) — needed only after the first release

---

## Content workstream (runs in parallel)

Content is the biggest schedule risk ([PRD §33](PRD.md#33-risks)), so it starts at Setup and runs alongside engineering — not as a V1 afterthought.

| By | Content milestone |
|----|-------------------|
| End of Setup | Ingredient list (~100 core ingredients, EN/MR names, aliases, units); recipe template agreed |
| MVP ship | ~15–20 recipes written, cooked once to verify quantities, Marathi reviewed |
| V1 closed test | ~40–80 recipes across meal types, veg/non-veg, major regions; photos for all; Marathi reviewer sign-off |

- Find the Marathi copy reviewer **during Setup**, not before store submission
- Photograph while test-cooking each recipe — one session, two outputs
- Track progress in a simple sheet: recipe → written → cooked → reviewed → photographed

---

## MVP — internal daily loop

**Exit:** guest on a real device can onboard, browse/search recipes, put one dish on today, Cook Now → Mark Cooked/Eaten, see history, link Google/Apple without losing data.

### M1. Identity

- Anonymous on first launch; app fully usable  
- Google link same UID (Android + iOS)  
- Apple link on iOS (required if Google is on iOS)  
- Provider-already-in-use: explicit dialog ([PRD §4](PRD.md#4-auth-and-personalization)), no silent merge  
- Guest-uninstall warning in onboarding  
- Account delete: re-auth → Apple token revoke → delete `users/{uid}` data → delete Auth user ([ARCHITECTURE.md §8](ARCHITECTURE.md#8-auth-in-code))  

### M2. Onboarding and language

- Language, veg/non-veg, region, household size → profile  
- Analytics consent prompt; Analytics collection off until consent where required  
- UI: English, Marathi, Marathi + English  
- ARB for chrome; recipe/ingredient strings from catalog  

### M3. Catalog, ingredients, search

- Models: `Ingredient` (stable ID, EN/MR, aliases, category, units), `Recipe` (tags, `ingredientLines[]`, steps, times)  
- Load bundled catalog at startup; works offline on first launch  
- List + detail: photo, names, tags, time, servings stepper  
- In-memory search: EN, MR, transliteration, case, hyphen vs space, aliases, small typo tolerance; table-driven tests  
- Tags on data: region(s), season, festival, occasion — **no hub UI**

### M4. Meals (model first)

- `users/{uid}/days/{date}` with slots → `{ status, statusChangedAt, items }` — single source for plan, track, and history  
- `Meal`: date, mealType, status, items (map keyed by `itemId`)  
- `MealItem` recipe: `recipeId`, servings, name snapshot fields  
- UI may add **one** catalog recipe per slot  
- Do not write empty slots; a missing slot reads as empty  

### M5. Home, Cook Now, cooking mode

- Bottom nav: Home, Recipes, Track; profile / language / auth in overflow  
- Home: today’s three slots, names, status  
- Cook Now from Home and recipe detail (no week plan required)  
- Filters: meal type, time, diet  
- Simple rank: meal type → time → diet → drop recipes inside the repeat window  
- Slot rules: empty → add; different items → Replace / Cancel ([PRD §9](PRD.md#9-cook-now-and-cooking-mode))  
- Cooking mode: ingredients, steps, servings, step checkboxes  
- Single recipe only in MVP  

### M6. Track, history, analytics

- Status transitions per PRD §12  
- Mark Cooked / Eaten from cooking mode and Home  
- History snapshots (catalog edits must not rewrite old names)  
- Events: all rows marked MVP in [CONVENTIONS.md § Analytics events](CONVENTIONS.md#analytics-events); logged from use cases  

### M7. Offline (MVP)

- Bundled recipes: browse, search, cook  
- User docs: Firestore persistence; snapshot streams; writes not awaited ([ARCHITECTURE.md §7](ARCHITECTURE.md#7-firestore-offline-implementation-rules))  
- Quiet “waiting to sync” from `hasPendingWrites`; last-write-wins per field; no conflict UI  
- Test: airplane mode → mark eaten → kill app → reopen → still eaten → go online → synced  

### M8. MVP ship

- Internal TestFlight + Android APK  
- ~15–20 seed recipes with real ingredient IDs  
- Not Play 12-tester / production listing yet  

**MVP done when:** PRD Loop A minus week/grocery works; search aliases work; Google link keeps history; `meal_items[]` in Firestore.

---

## V1 — first public product

**Exit:** store-ready app: week plan, kirana list, pantry, multi-dish meals, manual diary food, ranked replace.

### V1.1 Multi-item meals and cooking

- Add several catalog recipes to one slot  
- Cooking mode: one session, sequential recipes, servings kept  
- Mark Cooked / Eaten on the **slot**, not per dish  
- No timers / parallel-dish orchestration  

### V1.2 Manual food and snacks

- Manual item: label (+ optional quantity text); no Recipe; no grocery  
- Appears in history  
- Morning / evening snack slots on Track; Home can stay three mains  

### V1.3 Weekly plan

- Week grid (Monday start), breakfast / lunch / dinner  
- Generate week, copy previous week, randomize, avoid repeats  
- Servings: `scaledQty = recipeQty × (itemServings / recipeBaseServings)`; value carried across recipe, plan, Cook Now, grocery  

### V1.4 Recommendations and replace

- Deterministic rank: meal type → time → diet → pantry missing count → repeat window → season → recent avoidance → light favourite boost → variety  
- Replace: same slot + constraints; ranked alternatives; not random  
- “What should I cook?” uses the same engine; pantry feeds it when set  
- No LLM  

### V1.5 Pantry

- Add / remove / search ingredients by ID  
- Recipes ranked by fewest missing; show missing list  
- Usable without the week planner  

### V1.6 Grocery

- Rules: [PRD §16](PRD.md#16-grocery-list); shape: [ARCHITECTURE.md §6](ARCHITECTURE.md#6-data-cloud-vs-phone)  
- One list per planned week; lines as a map; derived keys `d_{ingredientId}_{unit}`, manual keys `m_*`  
- Regenerate touches only `d_*` keys and keeps their `checked`  
- Check off, edit qty, share/export  
- Unit tests: aggregation by ID + unit, regeneration keeps manuals and check-offs  

### V1.7 Favourites and nav

- Favourite recipe; add to plan from favourite  
- Bottom nav: Home, Recipes, Plan, Track, Shopping  
- Pantry under Home / Recipes, not a sixth tab  

### V1.8 Offline and analytics (complete)

- Offline view/edit: plans, track, pantry, shopping list  
- Same Firestore persistence policy as MVP  
- Full funnel analytics per [CONVENTIONS.md](CONVENTIONS.md)  

### V1.9 Content and store

- Catalog toward ~40–80 authentic dishes (see Content workstream)  
- Privacy policy covering DPDP + GDPR, support URL, web account-deletion request page  
- Play: 12 testers × 14 days, then production  
- App Store listing; Apple Developer if not already  
- Data safety / privacy nutrition labels  

**V1 done when:** PRD acceptance loops A–E pass (plan/eat, pantry, grocery integrity, manual food, auth keep-data).

---

## V2 — later product

Do not start until V1 is in stores. Data from MVP/V1 should already allow these without migrating meals.

| Workstream | Scope |
|------------|--------|
| **Discover** | Regional browse hub; seasonal and festival collection screens (tags already on recipes) |
| **Thali** | Builder UI composing `meal_items` (rice/poli/bhakri + dal + bhaji + sides + dessert) |
| **Insights** | Food history statistics (“माझा आहार”) |
| **Smarter recs** | Extra weights: day of week, region, festival, household size |
| **Household** | Family / extra profiles |
| **Nutrition** | Optional nutrition fields already on recipes; UI only in V2 |
| **Platform** | FCM reminders, Remote Config, Cloud Functions if needed, Cloud Storage photos, phone auth |
| **Monetization** | Optional subscription / ads; store IAP; Small Business Program |

---

## Suggested build order

Work top to bottom. Finish a version’s exit criteria before starting the next. The content workstream runs alongside all of these.

1. Setup S1–S3 (and start content)  
2. MVP M3 catalog shape + M4 meal model (even before pretty UI)  
3. MVP M1–M2 auth and onboarding  
4. MVP M5–M7 home, cook, track, offline  
5. MVP M8 internal builds  
6. V1.1–V1.2 multi-item + manual food  
7. V1.3–V1.5 plan, recs, pantry  
8. V1.6 grocery  
9. V1.7–V1.9 polish and stores  
10. V2 workstreams as product priority (thali and collections are the natural follow-on)

---

## Engineering rules (all versions)

- Page → BLoC → UseCase → domain port → Firestore / cache  
- `domain` does not import `data`  
- No custom offline sync; no Cloud Functions **only** for sync  
- Fonts via `AppFont`  
- Analytics names only from [CONVENTIONS.md](CONVENTIONS.md) (Firebase-valid `snake_case`, ≤ 40 chars); logged from use cases  
- Never await Firestore user-data writes in UI flows  
- Natural Marathi, not literal machine translation  

---

## Open decisions

| Topic | Status |
|-------|--------|
| Final app name | Placeholder `[App name]` |
| Bundle ID | `[bundle.id.tbd]` |
| Individual vs organization store accounts | Individual is enough to start |
| Recipe photos | Placeholders until licensed/original set exists |
| Marathi copy reviewer | Find during Setup; sign-off required before V1 store |
| Android-first store submit vs both together | Code both; submit Android first if Apple account is delayed |
