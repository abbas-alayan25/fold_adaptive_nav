# Contributing

Thanks for helping. The most useful contributions, in order:

1. **A device report** from a foldable the package isn't tested on yet
   ([template](https://github.com/abbas-alayan25/fold_adaptive_nav/issues/new?template=device_report.yml)).
2. **A bug report** with the device, its posture and a `FoldDebugOverlay`
   label.
3. **A pull request** with a test.

## The repository

A pub workspace of four packages, plus examples:

| Folder | What |
|---|---|
| `fold_adaptive_nav` | Widgets and the Dart API; what apps depend on |
| `fold_adaptive_nav/example` | The example app, its tests and the Android integration test |
| `fold_adaptive_nav_platform_interface` | `FoldState`, the wire codec, `FoldPlatform` |
| `fold_adaptive_nav_android` | Kotlin: Jetpack WindowManager, the hinge sensor |
| `fold_adaptive_nav_ios` | Swift: `UIHingeInteraction`, reserved regions, size classes |
| `examples/go_router_example` | go_router with a back stack per tab |
| `docs` | Migration guide and longer write-ups |

```sh
flutter pub get                  # once, at the root: resolves every package
cd fold_adaptive_nav && flutter test
```

## Before a pull request

- `dart format .` and `flutter analyze` in the packages you touched.
- `flutter test` in `fold_adaptive_nav`, its example, and
  `fold_adaptive_nav_platform_interface`.
- A layout change comes with a test on the presets it affects:

  ```dart
  await tester.pumpWidget(FoldPreview(
    preset: FoldDevicePreset.galaxyZFoldCover,
    child: MaterialApp(home: ...),
  ));
  ```

- Native changes: the Kotlin unit tests run with
  `./gradlew :fold_adaptive_nav_android:testDebugUnitTest` from
  `fold_adaptive_nav/example/android` (after one `flutter build apk`), the
  Swift ones from Xcode's `RunnerTests` in `fold_adaptive_nav/example/ios`.
  CI runs both, and the example on an Android foldable emulator.
- An entry in the package's `CHANGELOG.md` under the next version.

## Style

- Match the code around you; public members get a `///` comment.
- Defaults don't change in a minor version unless they fix a bug; say so in
  the CHANGELOG when they do.

## Versions

The packages follow [semantic versioning](https://semver.org): no breaking
change outside a major version, and anything removed is deprecated for at
least one minor version first.
