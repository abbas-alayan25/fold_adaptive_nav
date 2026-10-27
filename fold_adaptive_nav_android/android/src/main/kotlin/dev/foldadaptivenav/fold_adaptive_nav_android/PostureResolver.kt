package dev.foldadaptivenav.fold_adaptive_nav_android

/** The two `FoldingFeature.State`s, kept free of Android types for unit tests. */
enum class FoldFeatureState { HALF_OPENED, FLAT }

/** Maps WindowManager and hinge-sensor readings to the wire posture strings. */
object PostureResolver {
  /** Below this hinge angle a foldable without a fold feature counts as closed. */
  const val CLOSED_BELOW_DEGREES = 30f

  /** At or above this angle a foldable without a fold feature counts as flat. */
  const val FLAT_FROM_DEGREES = 150f

  /**
   * @param isFoldable the device has a hinge sensor or once reported a fold.
   * @param fold the current fold feature's state, or null when none is reported.
   * @param hingeAngle the hinge sensor's last reading, or null without a sensor.
   */
  fun resolve(isFoldable: Boolean, fold: FoldFeatureState?, hingeAngle: Float?): String =
    when {
      fold == FoldFeatureState.HALF_OPENED -> "partiallyOpen"
      fold == FoldFeatureState.FLAT -> "fullyOpen"
      !isFoldable -> "unknown"
      // No fold feature: the app is on the outer display, or the window
      // doesn't span the fold. Without a sensor, trust the missing feature.
      hingeAngle == null || hingeAngle < CLOSED_BELOW_DEGREES -> "closed"
      hingeAngle >= FLAT_FROM_DEGREES -> "fullyOpen"
      else -> "partiallyOpen"
    }
}
