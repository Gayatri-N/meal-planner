# Delivery plan — [App name]

**Product:** Maharashtrian meal planner, recipe book, grocery assistant, and food diary  
**App name:** `[App name]` (placeholder until chosen)  
**Bundle ID:** `[bundle.id.tbd]`  
**Sources:** [PRD.md](PRD.md), [ARCHITECTURE.md](ARCHITECTURE.md), [CONVENTIONS.md](CONVENTIONS.md)

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
| Folder tree, BLoC, injectable, `GAFont`, `Result` | ● | | | |
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
| Catalog cache + Firestore persistence | | ● | | |
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
- Theme tokens + **`GAFont` only** for fonts  
- `main_dev.dart` (prod flavor later)

**Empty feature folders:** `auth`, `onboarding`, `home`, `recipes`, `track`, `settings`. Stubs: `plan`, `shopping` (filled in V1).

### S2. Firebase (dev)

- Dev project, region `asia-south1`, Spark  
- Auth: Anonymous, Google; Apple capability ready for iOS  
- Firestore + security rules (catalog read if signed in; `users/{uid}` owner only)  
- Analytics + Crashlytics (`runZonedGuarded`, `FlutterError.onError`)  
- App Check when Auth works  
- Budget alerts if/when Blaze is needed (not for seed images in-app)

No Dio, no custom API, no custom sync engine.

### S3. Content pipeline

- Recipe + ingredient JSON schema matching domain models  
- Bundled placeholder images  
- One-time import to Firestore + `meta/catalog.recipesVersion`

---

## MVP — internal daily loop

**Exit:** guest on a real device can onboard, browse/search recipes, put one dish on today, Cook Now → Mark Cooked/Eaten, see history, link Google/Apple without losing data.

### M1. Identity

- Anonymous on first launch; app fully usable  
- Google link same UID (Android + iOS)  
- Apple link on iOS (required if Google is on iOS)  
- Provider-already-in-use: error, no silent merge  
- Guest-uninstall warning in onboarding  
- Account delete: Auth + `users/{uid}` tree  

### M2. Onboarding and language

- Language, veg/non-veg, region, household size → profile  
- UI: English, Marathi, Marathi + English  
- ARB for chrome; recipe/ingredient strings from catalog  

### M3. Catalog, ingredients, search

- Models: `Ingredient` (stable ID, EN/MR, aliases, category, units), `Recipe` (tags, `ingredientLines[]`, steps, times)  
- Local cache after first sync; version stamp to skip full re-download  
- List + detail: photo, names, tags, time, servings stepper  
- Search: EN, MR, transliteration, case, hyphen vs space, aliases  
- Tags on data: region(s), season, festival, occasion — **no hub UI**

### M4. Meals (model first)

- `Meal`: date, mealType, status, `items[]`  
- `MealItem` recipe: `recipeId`, servings, name snapshot fields  
- UI may add **one** catalog recipe per slot  
- Empty Planned slots for today on first open of the day  

### M5. Home, Cook Now, cooking mode

- Bottom nav: Home, Recipes, Track, Settings  
- Home: today’s three slots, names, status  
- Cook Now from Home and recipe detail (no week plan required)  
- Filters: meal type, time, diet  
- Rank: meal type → time → diet → skip last ~3 days if history exists  
- Cooking mode: ingredients, steps, servings, step checkboxes  
- Single recipe only in MVP  

### M6. Track, history, analytics

- Status transitions per PRD §12  
- Mark Cooked / Eaten from cooking mode and Home  
- History snapshots (catalog edits must not rewrite old names)  
- Events: `recommendation:shown|selected`, `recipe:cooked`, `meal:marked_eaten`, `plan:recipe:added`, `recipes:detail:viewed`  

### M7. Offline (MVP)

- Cached recipes: browse, search, cook  
- User docs: Firestore persistence; edits appear immediately  
- Quiet “waiting to sync”; last-write-wins; no conflict UI  

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

- **One active list per planned week** (`shoppingLists/{weekStart}`)  
- Generate/update that list; do not create a new list every tap  
- **Derived** lines from recipe items; **manual** lines never auto-deleted  
- Plan change: recalculate derived; keep manual + check-offs  
- Check off, edit qty, share/export  
- Join on ingredient ID, never display strings  

### V1.7 Favourites and nav

- Favourite recipe; add to plan from favourite  
- Bottom nav: Home, Recipes, Plan, Track, Shopping  
- Pantry under Home / Recipes, not a sixth tab  

### V1.8 Offline and analytics (complete)

- Offline view/edit: plans, track, pantry, shopping list  
- Same Firestore persistence policy as MVP  
- Full funnel analytics per [CONVENTIONS.md](CONVENTIONS.md)  

### V1.9 Content and store

- Catalog toward ~40–80 authentic dishes  
- Privacy policy + support URL  
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

Work top to bottom. Finish a version’s exit criteria before starting the next.

1. Setup S1–S3  
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
- Fonts via `GAFont`  
- Analytics names from [CONVENTIONS.md](CONVENTIONS.md) (`app:plan:recipe:added`, not `app:plan:meal:added`)  
- Natural Marathi, not literal machine translation  

---

## Open decisions

| Topic | Status |
|-------|--------|
| Final app name | Placeholder `[App name]` |
| Bundle ID | `[bundle.id.tbd]` |
| Individual vs organization store accounts | Individual is enough to start |
| Recipe photos | Placeholders until licensed/original set exists |
| Marathi copy reviewer | Required before V1 store |
| Android-first store submit vs both together | Code both; submit Android first if Apple account is delayed |
