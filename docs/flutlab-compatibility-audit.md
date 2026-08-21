# FlutLab Compatibility Audit

Date: 2026-08-21 (user timezone)

FlutLab reported Dart SDK 3.8.1. The project therefore uses an SDK constraint of `>=3.8.0 <4.0.0` and must avoid package releases requiring Dart 3.9+.

The Dart 3.8.1 toolchain was verified locally with Flutter 3.32.1. `flutter pub get` succeeds after selecting compatible dependency releases, but source compatibility still requires Flutter 3.32 API adjustments and an older fl_chart release.

Relevant package metadata was checked through the pub.dev package APIs:

- [shared_preferences API](https://pub.dev/api/packages/shared_preferences): 2.5.3 supports Dart ^3.5.0; 2.5.5 requires Dart ^3.9.0.
- [path_provider API](https://pub.dev/api/packages/path_provider): 2.1.5 supports Dart ^3.4.0; 2.1.6 requires Dart ^3.10.0.
- [package_info_plus API](https://pub.dev/api/packages/package_info_plus): 9.0.1 supports Dart >=3.3.0; 10.2.1 requires Dart >=3.10.0.
- [file_picker API](https://pub.dev/api/packages/file_picker): 11.0.3 supports Dart >=3.4.0; 12.0.0 requires Dart >=3.10.0.
- [excel_plus API](https://pub.dev/api/packages/excel_plus): all published 0.0.x versions require Dart ^3.11.4, so it was replaced with [excel 4.0.6](https://pub.dev/api/packages/excel), which supports Dart >=3.0.0.
- [pdf API](https://pub.dev/api/packages/pdf): pdf 3.12.0 requires vector_math ^2.2.0, which conflicts with Flutter 3.32.1 pinning vector_math 2.1.4; pdf is therefore pinned to 3.11.3.
- [fl_chart API](https://pub.dev/api/packages/fl_chart): fl_chart 1.1.0 still calls Matrix4.translateByDouble, unavailable with Flutter 3.32.1's vector_math 2.1.4; a still older compatible chart release is required.

The first FlutLab-style compile exposed additional Flutter 3.32 API differences: `DropdownButtonFormField` uses `value` rather than `initialValue`, and `RadioGroup` is not available. These source usages must be made compatible with Flutter 3.32 while remaining valid on newer Flutter 3.x releases.

## Android toolchain fix for Flutter 3.32 / FlutLab

The Android project now uses Kotlin DSL throughout the application and the vendored `file_picker` plugin. The FlutLab-facing toolchain is pinned to AGP `8.11.1`, Kotlin Gradle Plugin `2.1.21`, and Gradle wrapper `8.14.1`. This avoids the old Gradle Copy-task API mismatch behind the `FlutterPlugin.kt:... Unresolved reference 'fileMode'` failure while keeping the project on the Flutter 3.x Kotlin DSL layout. The application and vendor plugin compile targets are Java 17, and the app explicitly compiles and targets Android API 36.

The application-level Kotlin configuration uses `tasks.withType<KotlinCompile>().configureEach { compilerOptions.jvmTarget.set(JvmTarget.JVM_17) }`, rather than the newer `kotlin { compilerOptions { ... } }` block that is not recognized consistently by the Flutter 3.32 toolchain. The vendor `file_picker` Android module has matching Kotlin DSL build and settings files, with an explicit `RepositoriesMode` import.

Validation results on 2026-08-21:

| Validation | Result |
|---|---|
| Flutter 3.32.1 / Dart 3.8.1 `:gradle:compileKotlin` | Passed with Gradle 8.14.1 and Kotlin 2.1.21 |
| Flutter 3.32.1 debug APK | Passed locally with the Flutter 3.32.1 default KGP 2.1.0 after removing an unrelated untracked `VersionFetcher.kt` file from the local SDK checkout; final KGP 2.1.21 `:gradle:compileKotlin` also passed |
| Flutter 3.47.0 debug APK | Passed locally with `--android-skip-build-dependency-validation`; this flag is required only because the project is intentionally pinned to the FlutLab-compatible older toolchain |
| API level | `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24` |

FlutLab should use the repository's Kotlin DSL files as committed. After pulling the update, run `flutter clean`, `flutter pub get`, and then build the required Android target. If FlutLab exposes a dependency-validation warning for its newer Flutter channel, the Android build can be run with `--android-skip-build-dependency-validation`; Flutter 3.32/Dart 3.8.1 does not require that bypass.

The Flutter Gradle Plugin was converted to Kotlin source in the Flutter 3.32 release line, so the project must use a Gradle version that supports the APIs used by that plugin. See the [Flutter 3.32 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.32.0), the [Flutter 3.32.1 Gradle source](https://github.com/flutter/flutter/tree/3.32.1/packages/flutter_tools/gradle), and the [Gradle compatibility documentation](https://docs.gradle.org/current/userguide/compatibility.html).

## Reproducible local checks

```bash
export ANDROID_HOME=/home/ubuntu/android-sdk
export ANDROID_SDK_ROOT=/home/ubuntu/android-sdk

# FlutLab-equivalent toolchain
/home/ubuntu/flutter_3.32.1/bin/flutter clean
/home/ubuntu/flutter_3.32.1/bin/flutter pub get
/home/ubuntu/flutter_3.32.1/bin/flutter build apk --debug --no-tree-shake-icons

# Newer Flutter 3.x local toolchain, if dependency validation is stricter
/home/ubuntu/flutter_3.47.0/bin/flutter build apk --debug \
  --no-tree-shake-icons --android-skip-build-dependency-validation
```

The Android build output directories are intentionally not committed.

## References

1. [Flutter 3.32.0 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.32.0)
2. [Flutter 3.32.1 Gradle plugin source](https://github.com/flutter/flutter/tree/3.32.1/packages/flutter_tools/gradle)
3. [Gradle compatibility documentation](https://docs.gradle.org/current/userguide/compatibility.html)
4. [Android Gradle Plugin release notes](https://developer.android.com/build/releases/gradle-plugin)

[1]: https://docs.flutter.dev/release/release-notes/release-notes-3.32.0
[2]: https://github.com/flutter/flutter/tree/3.32.1/packages/flutter_tools/gradle
[3]: https://docs.gradle.org/current/userguide/compatibility.html
[4]: https://developer.android.com/build/releases/gradle-plugin

## Comprehensive audit follow-up: pasted_content.txt

The supplied codebase audit was reviewed against the current repository instead of applying every recommendation blindly. The following table records the disposition of each finding.

| Audit finding | Repository evidence | Action |
|---|---|---|
| Numeric/string/date/enum deserialization can crash | Several models previously used strict string casts and case-sensitive enum matching | Fixed with `lib/models/json_helpers.dart`; all finance, reminder, task, and updater models now use tolerant numeric, boolean, date, string, enum, and list parsing with safe fallbacks |
| JSON file writes can race or create zero-byte files | `FinanceStorage` uses SharedPreferences, not direct JSON files; backup creation stages files in a temporary directory | Added a serialized write queue to `FinanceStorage`; no unnecessary JSON atomic-write abstraction was introduced |
| Hash false positives from XML formatting | Backup manifests are canonicalized by stripping formatting whitespace before HMAC verification | Existing canonicalization was retained; malformed device HMAC keys now regenerate safely. The manifest still intentionally uses a device-keystore HMAC scope, so a backup made on another device or after keystore loss is expected to require a deliberate trust/recovery policy rather than silently bypassing integrity checks |
| Missing receipt/goal image can crash UI or consume excessive memory | Local `Image.file` consumers lacked cache bounds in `main.dart` and `savings_sheet.dart` | Added file fallback/errorBuilder handling and cache dimensions for goal thumbnails, receipt previews, and savings photos. Input images were already downscaled by `ImageAttachmentService` |
| Budget progress can divide by zero or exceed indicator bounds | Budget service guarded zero limits and analytics UI already applied a clamp | Added finite/rounded budget aggregation and bounded `SavingsGoal.progress`; existing analytics clamp remains in place |
| Floating-point drift in financial totals | Several aggregate totals used raw `double` folds | Added `roundMoney` at model deserialization, budget aggregation, widget totals, pocket-money calculations, debt totals, and widget sync values |
| Async context/state use after an await | Most sheets already checked `mounted`; savings photo deletion and account transition flow lacked a post-await guard | Added mounted guards in `savings_sheet.dart` and `advanced_finance_sheets.dart`; existing guarded flows were left unchanged |
| Lexical SemVer comparison in updater | Updater compares numeric `versionCode`; no string `.compareTo` version decision exists | No SemVer patch was necessary. Metadata parsing was hardened, and downloaded APK filenames now sanitize the version string |
| Android widget does not refresh after Flutter changes | `main.dart` already calls `HomeWidget.updateWidget`, and the native provider refreshes widget IDs | No duplicate MethodChannel was added; widget sync was retained and total values now use rounded aggregates |
| Missing global error catcher | `main()` previously only initialized bindings and called `runApp` | Added `FlutterError.onError` and `PlatformDispatcher.instance.onError` handlers |

Regression coverage was added in `test/model_parsing_test.dart` for legacy numeric/string values, invalid dates, unknown enums, bounded progress, rounding, reminder weekdays, and task parsing. The audit's generic recommendations were therefore converted into targeted fixes only where the repository contained a real defect.

## Audit validation status

`flutter test` passes all 8 tests under Flutter 3.32.1/Dart 3.8.1. `flutter analyze` reports no compile errors; it still exits non-zero because the repository contains pre-existing warnings/info such as unused legacy methods, curly-brace style notices, report API deprecations, and vendor Windows API notices. The new audit code itself is formatted and covered by tests.
