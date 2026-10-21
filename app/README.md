# kina_app

The Flutter app for Windows and Android. It uses `kina_core` for every
calculation and `kina_data` for local storage.

## Run

```sh
flutter run -d windows   # on a Windows PC
flutter run -d android   # with a phone or emulator connected
```

## Layout

| Path | What it holds |
| --- | --- |
| `lib/main.dart` | Opens the database and starts the app |
| `lib/src/app.dart` | App root and navigation: side rail on wide windows, bottom bar on phones |
| `lib/src/providers.dart` | Riverpod providers: database, repositories, settings, profiles, snapshots, journal |
| `lib/src/calculator/` | Calculator screen, its logic (currency switch, manual and synced rates) and view model |
| `lib/src/marketplace/` | Marketplace item valuation and the purchase journal |
| `lib/src/analysis/` | Price breakdown, profiles, snapshot history and its chart |
| `lib/src/more/` | Help guides, v55 import and about |
| `lib/src/help/` | Help text for VAT, payment fees and Know the risks |
| `lib/src/export/` | CSV for the calculation, journal and price history |
| `lib/src/files/` | Save and open dialogs (faked in tests) |
| `lib/src/rates/` | Frankfurter (ECB) client, the only network call |
| `lib/src/theme.dart` | Colours and shapes; swap the look here |
| `test/goldens/` | Screen images at Windows and phone sizes, light and dark |

## Test

```sh
flutter test --exclude-tags golden   # unit and widget tests
flutter test --tags golden           # screen images (Linux only)
flutter test --tags golden --update-goldens   # after an intended UI change
```
