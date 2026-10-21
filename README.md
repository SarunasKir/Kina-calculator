# Kina Calculator

A local calculator for Aion 2 that compares the real-money cost of buying Kina
from a third-party seller against the official Quna shop, including VAT and
payment fees. It is a rebuild of the v55 Windows app for Windows and Android.

## Layout

| Path | What it holds |
| --- | --- |
| `app` | The Flutter app for Windows and Android |
| `packages/kina_core` | Calculations, Kina price parser and currency maths (pure Dart) |
| `packages/kina_data` | SQLite storage (Drift) for settings, profiles, price history and the purchase journal, plus v55 import |
| `packages/kina_sync` | Wi-Fi sync: the hub inside the PC app, the phone client, pairing, discovery and merging |
| `docs/` | Architecture decision records and the [sync design](docs/sync.md) |
| `tool/` | Scripts used by CI |

## Development

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.47 or newer), then from the repository root:

```sh
dart pub get
dart format .
dart analyze --fatal-infos
(cd packages/kina_core && dart test)
(cd packages/kina_data && dart test)
(cd packages/kina_sync && dart test)
(cd app && flutter test)
```

Every push builds an Android APK and a Windows installer; download them from
the run's artifacts on the Actions tab. To publish a release that installs
without developer tools, push a version tag; see
[docs/releasing.md](docs/releasing.md).

After changing a table in `packages/kina_data/lib/src/database.dart`,
regenerate the Drift code with
`cd packages/kina_data && dart run build_runner build`.

CI runs formatting, analysis and tests on every push and pull request, and
requires 100% line coverage for the three packages (generated code excluded)
and 95% for the app. Screen images in `app/test/goldens` must match.

## Calculation rules

Every formula matches v55. Money is rounded to the nearest cent, half away
from zero, at each displayed step:

1. Subtotal = Kina (millions) × seller price per 1M
2. VAT = subtotal × VAT %
3. Fee = (subtotal + VAT) × fee % + fixed fee
4. Official cost = Quna needed ÷ Quna per pack × pack price, where
   Quna needed = Kina (millions) × Quna per chest ÷ Kina per chest (millions)
5. Savings = official cost − RMT total

## Seller sites and extra fees

Each seller in the comparison can have a site address and its own fees.
Open "Site and fees" on a seller row:

- **Extra site fee** (%) and **extra fixed fee** are added to the payment
  method's fee percent and fixed fee for that seller only. The cheapest seller
  is the one with the lowest total after these fees.
- **Site address** with **Fetch price** (per seller) or **Fetch prices** (all
  sellers) reads the current price and puts it in the seller's price field.
  Nothing is fetched until you press a button.
- **Read as**: *Automatic* understands JSON feeds with `price`/`rate`/`cost`
  fields, prices written with their unit (`€1.25 / 1M`, `$9 per 10M`),
  schema.org product data (JSON-LD, `itemprop`, `product:price:amount`).
  *JSON address* follows a path such as `data.items[0].price`. *Page selector*
  uses a CSS selector such as `.price`.
- **Price is for** (1M, 10M, 100M, 1B) and **Site currency** tell the app how
  to turn the site's number into a price per 1M in your calculator currency,
  using the stored exchange rates. Sync online rates first for other
  currencies.

Pages that build their prices with JavaScript cannot be read this way; use a
JSON address if the site offers one. Only fetch from sites whose terms allow
automated reading.
