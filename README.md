# Score Tap Counter

Score Tap Counter is a Flutter app for fast sport score tracking with gesture controls.

Repository target:

- https://github.com/mluckypradana/score_tap_counter

## Download APK

- Latest APK in repository: [assets/apk/score_tap_counter-release.apk](assets/apk/score_tap_counter-release.apk)

## Features

- Dual-side versus mode and solo mode
- Gesture-based score interactions
- Match timer with live display
- Save to history and favorites
- Continue match from saved/history records
- CSV export and CSV import
- Layout switch: horizontal or vertical
- Custom player names, score colors, and reusable name suggestions

## Tech Stack

- Flutter
- Dart
- SharedPreferences (local persistence)
- File Picker and Path Provider (CSV import/export)

## Getting Started

### Prerequisites

- Flutter SDK installed
- Android SDK / emulator or real device

### Install Dependencies

```bash
flutter pub get
```

### Run (Debug)

```bash
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

Output file:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To refresh the APK stored in the repository asset folder:

```bash
mkdir -p assets/apk
cp build/app/outputs/flutter-apk/app-release.apk assets/apk/score_tap_counter-release.apk
```

## Project Structure

```text
lib/
	models/
	pages/
	widgets/
	main.dart
```

## Notes

- Release build uses minify + resource shrinking to reduce APK size.
- For Play Store distribution, use a proper release signing key.

## License

Private project.
