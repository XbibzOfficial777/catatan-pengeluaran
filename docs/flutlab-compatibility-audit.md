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
