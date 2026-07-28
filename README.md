# Home Service App — ProKit UI reference clone

## What's actually here

Full Flutter source for:
- Onboarding (3-page swipe intro → Get Started)
- Login / Sign Up — real Firebase Auth (email + password)
- Home screen — search bar, category chips, services grouped by category, all from a live Firestore stream
- Service Details screen — full description/price from Firestore
- Admin Panel screen — form to add services, live list with delete, writes straight to Firestore

This was written in a sandbox with no Flutter SDK and no access to pub.dev, so **none of it has been compiled**. Treat it as a strong first draft, not a verified build. Run `flutter analyze` and `flutter pub get` locally before trusting it.

## Gaps you should know about now, not after you've built it

1. **OTP screen — not built.** Your screenshots show a phone-number + OTP verification step. The PRD's written requirements say email/password only. I built email/password (matches the spec you wrote, not the spec implied by the screenshot) because a fake OTP screen that doesn't actually verify anything is worse than no OTP screen — it would look done and not be done. If you actually need phone auth, that's Firebase Phone Auth with reCAPTCHA/SMS quotas — a separate, non-trivial piece of work. Say so and I'll scope it properly.

2. **"Book This Service" button does nothing but show a snackbar.** Booking/scheduling was never in your PRD's scope (section 3 stops at "Detail Inspection Window"). I didn't invent a fake booking flow to look more complete.

3. **Images are placeholders, not real assets.** `assets/images/` has `.txt` stand-ins, not actual PNGs. The PRD's constraint ("local assets only, no Firebase Storage") is honored in the code — `local_image_asset_key` is read from Firestore and mapped to a local asset path — but you need to drop real PNGs into that folder with matching filenames (see `category_model.dart` for the exact keys) or the app will render a fallback icon instead of a photo.

4. **`firebase_options.dart` is a placeholder.** The app will not connect to Firebase until you run `flutterfire configure` against your own project. This isn't optional — nothing works without it.

5. **Admin Panel has no access control by default.** Right now it's a screen anyone in the app can navigate to from the Home screen's top bar. I added `firestore.rules` that restricts writes to a whitelisted `admins` collection — **you need to deploy those rules and manually add your own UID to `admins/{uid}` in the console**, or any signed-in user can add/delete services. If this is genuinely admin-only tooling, it also shouldn't ship inside the same binary as the consumer app long-term — that's a call for you to make, not something I decided silently.

## Setup

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure   # select/create your Firebase project, overwrites firebase_options.dart
```

In the Firebase console:
- Enable **Authentication → Email/Password**
- Enable **Authentication → Phone no/OTP**
- Create **Firestore Database** (production mode)
- Deploy `firestore.rules` (or paste them into the console's Rules tab)
- Add your own UID as a document in `admins/{your-uid}` so you can use the Admin Panel

Then:
```bash
flutter run
```

## Testing the flow the PRD asks for

1. Sign up / log in.
2. Open Admin Panel (icon in Home screen's top bar).
3. Add a service: title, description, price 500, category "Plumbing".
4. Go back to Home — it should appear under "Plumbing" within seconds (it's a live `snapshots()` stream, not a manual refresh).
5. Tap it — details screen should show the same title/price/description.

If step 4 doesn't happen instantly, the most likely cause is Firestore rules blocking the read, not the app code — check the console's rules simulator first.
