# AGENTS.md

## Project

FIGUGOL is a Flutter mobile app for trading football stickers. The product is inspired by the excitement around a global football tournament, but it must avoid protected brands and official tournament wording.

Use generic Spanish product terms such as:

- figuritas
- coleccion
- torneo mundial
- album futbolero
- stickers
- intercambio


## Technical Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage only when there is a clear need
- Google Sign-In
- Geolocation
- QR flows
- Simulated Stripe-like payments for the first phase

No real payment data, payment credentials, cards, charges, or production payment flows should be implemented in this phase.

## Development Rules

- Build with a clean, scalable architecture.
- Separate the app by feature folders.
- Use clear English names for code, files, classes, methods, variables, and Firestore fields.
- Use Spanish for user-visible text.
- Do not implement the app in `main.dart` beyond bootstrapping and dependency setup.
- Keep code modular, maintainable, and ready to grow.
- Before adding a dependency, explain why it is necessary and what problem it solves.
- After each important code change, run `flutter analyze`.
- If `flutter analyze` reports errors, fix them before continuing.
- Prefer Android-first decisions unless a task explicitly targets another platform.
- Verify internet connectivity before important remote operations.
- Use strongly defined models for Firestore data.
- Avoid hardcoded sample data in production paths unless it is clearly marked as mock or seed data.
- Keep simulated payment logic isolated so it can later be replaced by a real provider.

## Expected Structure

Use this structure as the baseline:

```text
lib/
  core/
  features/
    auth/
    profile/
    stickers/
    location/
    offers/
    marketplace/
    qr_exchange/
    payments/
  shared/
```

Suggested responsibilities:

- `core/`: app configuration, constants, errors, networking/connectivity, Firebase setup, routing, theme, shared utilities.
- `features/auth/`: Firebase Authentication, Google Sign-In, login, signup, logout, auth state.
- `features/profile/`: user profile, collector preferences, avatar, city or approximate location metadata.
- `features/stickers/`: sticker catalog, owned stickers, missing stickers, duplicates, album progress.
- `features/location/`: geolocation permissions, nearby collectors, distance helpers.
- `features/offers/`: trade offers, offer states, proposal and acceptance flows.
- `features/marketplace/`: listings, discovery, filters, simulated buying intent.
- `features/qr_exchange/`: QR generation, QR scanning, exchange confirmation.
- `features/payments/`: simulated payment sessions, fake checkout result, payment status models.
- `shared/`: reusable widgets, shared presentation helpers, formatters, validators.

Each feature should generally be split into layers when useful:

```text
feature_name/
  data/
    models/
    repositories/
    sources/
  domain/
    entities/
    repositories/
    use_cases/
  presentation/
    pages/
    widgets/
    controllers/
```

Keep the layering practical. Do not add empty folders or abstractions until they help the current stage.

## Firebase And Data

- Firestore collections must use English names.
- User-visible labels coming from Firestore can be Spanish.
- Model classes should define serialization explicitly with `fromJson`, `toJson`, or the serialization pattern already used in the codebase.
- Store only the minimum location data needed for the feature.
- Avoid storing sensitive personal data unless the current task explicitly requires it and the privacy implications are addressed.
- Payment-related documents must represent simulated data only.

Example collection names:

- `users`
- `sticker_collections`
- `stickers`
- `trade_offers`
- `marketplace_listings`
- `qr_exchanges`
- `simulated_payments`

## Connectivity

Before important operations involving Firebase, geolocation, QR exchange confirmation, marketplace actions, or simulated payments:

- Check whether the device appears to have internet access.
- Show a Spanish user-facing message if the action cannot continue.
- Keep connectivity checks in `core/` or a shared service instead of duplicating logic across features.

## Payments

Payments are simulated in this phase.

Allowed:

- Fake checkout screens.
- Simulated payment intents or sessions.
- Test-only statuses such as `pending`, `approved`, `rejected`, and `cancelled`.
- Clearly fake transaction identifiers.

Not allowed:

- Real Stripe SDK setup.
- Real card collection.
- Real payment credentials.
- Production payment provider secrets.
- Any flow that can charge a user.

## UX And Copy

- User-visible text must be Spanish.
- Product copy must be generic and legally safe.
- Avoid official tournament language.
- Keep screens focused on completing real user tasks: collecting, finding, trading, scanning, and managing offers.
- Design for Android first.

## Workflow For Future Changes

For each stage:

1. Identify the feature being changed.
2. Keep edits scoped to that feature and any necessary shared/core support.
3. Explain any new dependency before adding it.
4. Implement the smallest functional step.
5. Run `flutter analyze`.
6. Fix analysis errors before moving to the next step.
7. Summarize what changed and what the next stage should be.

## First Milestones

Recommended build order:

1. Establish app structure, theme, routing, and core utilities.
2. Implement Firebase initialization and authentication shell.
3. Add Google Sign-In and auth state handling.
4. Create profile setup.
5. Model stickers, owned stickers, missing stickers, and duplicates.
6. Add trade offer creation and listing.
7. Add approximate location-based discovery.
8. Add QR exchange confirmation.
9. Add marketplace listing flow.
10. Add simulated payments.

