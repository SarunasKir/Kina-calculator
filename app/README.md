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
| `lib/src/providers.dart` | Riverpod providers: database, settings, derived view |
| `lib/src/calculator/` | Calculator screen, its logic (currency switch, manual and synced rates) and view model |
| `lib/src/rates/` | Frankfurter (ECB) client, the only network call |
| `lib/src/theme.dart` | Colours and shapes; swap the look here |
| `test/goldens/` | Screen images at Windows and phone sizes, light and dark |

## Test

```sh
flutter test --exclude-tags golden   # unit and widget tests
flutter test --tags golden           # screen images (Linux only)
flutter test --tags golden --update-goldens   # after an intended UI change
```
