# Period Tracker

A Flutter app for tracking menstrual cycles, predicting future periods, and analysing cycle health — built by KiwiNovas.

---

## Features

| Epic | Story | Description |
|------|-------|-------------|
| **E1 – Period Tracking** | E1-S1 | Edit period start date |
| | E1-S2 | Delete a wrong period log (with confirmation) |
| | E1-S3 | SnackBar confirmation after every log action |
| **E2 – Calendar** | E2-S1 | Period days highlighted in pink |
| | E2-S2 | Navigate forward/back between months |
| | E2-S3 | Tap a date to log or end a period |
| | E2-S4 | Today's date marked with a border |
| **E3 – Predictions** | E3-S1 | Next expected period shown on dashboard |
| | E3-S2 | Average cycle length calculated from past cycles |
| | E3-S3 | Predicted dates highlighted on the calendar |
| | E3-S4 | Prediction auto-updates on every log change |
| **E4 – Analysis** | E4-S1 | Average cycle length |
| | E4-S2 | Average period length |
| | E4-S3 | Last cycle summary |
| | E4-S4 | Regular / irregular cycle indicator |
| **E5 – Profile & Settings** | E5-S1 | Update age |
| | E5-S2 / S4 | Dark mode toggle |
| | E5-S3 | Delete all data |

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.38+ / Dart 3.10+ |
| State management | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) 2.x (`ChangeNotifierProvider`) |
| Local storage | [hive](https://pub.dev/packages/hive) + [hive_flutter](https://pub.dev/packages/hive_flutter) (manual `TypeAdapter`, no build_runner) |
| Calendar widget | [table_calendar](https://pub.dev/packages/table_calendar) 3.x |
| Design system | KiwiNovas design system (local package at `../mobile-platform`) |
| Date formatting | [intl](https://pub.dev/packages/intl) |

---

## Project Structure

```
lib/
├── main.dart                  # App entry point — Hive init, ProviderScope, theme
├── models/
│   ├── period.dart            # Period model + manual Hive TypeAdapter
│   └── user_profile.dart      # UserProfile model + manual Hive TypeAdapter
├── services/
│   ├── period_service.dart    # All business logic (CRUD, predictions, analytics)
│   └── providers.dart         # Riverpod providers
└── screens/
    ├── main_screen.dart       # Bottom navigation host
    ├── dashboard_screen.dart  # Home — next predicted period + quick log
    ├── calendar_screen.dart   # Monthly calendar with period/prediction highlights
    ├── log_screen.dart        # Period log list — edit & delete
    ├── analysis_screen.dart   # Cycle stats — averages, regularity
    └── profile_screen.dart    # Age, dark mode, delete data
```

---

## How to Run

### Prerequisites
- Flutter SDK >= 3.10 (`flutter --version`)
- Dart SDK >= 3.10 (bundled with Flutter)
- The `mobile-platform` packages at `../mobile-platform` relative to this folder

### Install dependencies
```bash
flutter pub get
```

### Run on a device / simulator
```bash
# List available devices
flutter devices

# iOS Simulator
flutter run -d <simulator-id>

# Android emulator
flutter run -d <emulator-id>

# macOS desktop
flutter run -d macos

# Chrome (web — quickest for local testing)
flutter run -d chrome
```

### Analyse for errors
```bash
flutter analyze
```

### Run tests
```bash
flutter test
```

---

## How It Works

### State Management
`PeriodService` extends `ChangeNotifier` and is exposed via a `ChangeNotifierProvider`. Every mutation (`startPeriod`, `editPeriodStart`, `deletePeriod`, etc.) calls `notifyListeners()` so the UI reactively updates. Derived values (next predicted date, averages) are computed as Riverpod `Provider`s that watch `periodServiceProvider`.

### Storage
Hive boxes are opened in `main()` before `runApp`:
- `periods` — stores `Period` objects via `PeriodAdapter`
- `profile` — stores `UserProfile` via `UserProfileAdapter`

Manual `TypeAdapter` classes are used instead of code generation, so **no `build_runner` step is required**.

### Predictions (E3)
1. Collect all completed periods sorted by start date.
2. Compute gap (in days) between consecutive start dates — that is the cycle length.
3. Average the last 6 cycle lengths → average cycle length.
4. Add the average to the last period's start date → predicted next start.

### Regularity (E4-S4)
Regularity is based on the variance of cycle lengths. If the variance is <= 49 (std-dev <= 7 days), cycles are considered regular.

---

## Docker (Web build)

Flutter is a UI framework — it does not run as a server. For the **web target** you can containerise the static output:

```dockerfile
# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY . .
COPY ../mobile-platform /mobile-platform
RUN flutter pub get && flutter build web --release

# Serve stage
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
```

Build and run:
```bash
docker build -t period-tracker-web .
docker run -p 8080:80 period-tracker-web
# open http://localhost:8080
```

---

## GitHub Issues Implemented

All open issues at https://github.com/kiwinovas/mobile-apps/issues are addressed in this codebase:

`#21 E1-S1` · `#20 E1-S2` · `#19 E1-S3` · `#18 E2-S1` · `#17 E2-S2` · `#23 E2-S3` · `#16 E2-S4` · `#25 E3-S1` · `#15 E3-S2` · `#14 E3-S3` · `#13 E3-S4` · `#12 E4-S1` · `#11 E4-S2` · `#10 E4-S3` · `#27 E4-S4` · `#9 E5-S1` · `#3 E5-S2` · `#29 E5-S3` · `#30 E5-S4`
