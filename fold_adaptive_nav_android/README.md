# fold_adaptive_nav_android

The Android implementation of [`fold_adaptive_nav`](https://pub.dev/packages/fold_adaptive_nav).
It is endorsed, so you don't add it to your app yourself: `fold_adaptive_nav`
pulls it in.

- Foldable detection: `FEATURE_SENSOR_HINGE_ANGLE`, or a `FoldingFeature` seen
  at least once.
- Posture and fold bounds (converted to logical pixels): Jetpack WindowManager
  1.3.
- Closed vs. open on the outer display: the hinge angle sensor (API 30+),
  registered only while the activity is started.

minSdk 24. Fold features need API 30+ hardware and degrade quietly below it.
