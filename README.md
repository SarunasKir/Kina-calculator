# Kina Calculator

A local calculator for Aion 2 that compares the real-money cost of buying Kina
from a third-party seller against the official Quna shop, including VAT and
payment fees. It is a rebuild of the v55 Windows app for Windows and Android.

## Layout

| Path | What it holds |
| --- | --- |
| `packages/kina_core` | Calculations, Kina price parser and currency maths (pure Dart) |
| `docs/` | Architecture decision records |
| `tool/` | Scripts used by CI |

The Flutter app, local storage and Wi-Fi sync will be added in later pull
requests.

## Development

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.47 or newer), then from the repository root:

```sh
dart pub get
dart format .
dart analyze --fatal-infos
cd packages/kina_core && dart test
```

CI runs formatting, analysis and tests on every push and pull request, and
requires 100% line coverage for `kina_core`.

## Calculation rules

Every formula matches v55. Money is rounded to the nearest cent, half away
from zero, at each displayed step:

1. Subtotal = Kina (millions) × seller price per 1M
2. VAT = subtotal × VAT %
3. Fee = (subtotal + VAT) × fee % + fixed fee
4. Official cost = Quna needed ÷ Quna per pack × pack price, where
   Quna needed = Kina (millions) × Quna per chest ÷ Kina per chest (millions)
5. Savings = official cost − RMT total
