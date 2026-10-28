package dev.foldadaptivenav.fold_adaptive_nav_android

/**
 * Builds the maps sent to Dart, kept free of Android types for unit tests.
 * The Dart side reads them with `FoldStateCodec.decode`.
 */
object WireState {
  /** The wire format's version; `FoldStateCodec.version` on the Dart side. */
  const val VERSION = 1

  /**
   * A fold region. WindowManager reports physical pixels; Flutter wants
   * logical ones, so every edge is divided by [density].
   */
  fun fold(
    left: Int,
    top: Int,
    width: Int,
    height: Int,
    density: Float,
    halfOpened: Boolean,
    separating: Boolean,
    fullOcclusion: Boolean,
    vertical: Boolean,
  ): Map<String, Any?> {
    val d = if (density > 0f) density else 1f
    return mapOf(
      "kind" to "fold",
      "left" to (left / d).toDouble(),
      "top" to (top / d).toDouble(),
      "width" to (width / d).toDouble(),
      "height" to (height / d).toDouble(),
      "isActive" to halfOpened,
      "isSeparating" to separating,
      "occlusionType" to if (fullOcclusion) "full" else "none",
      "orientation" to if (vertical) "vertical" else "horizontal",
    )
  }

  /** The whole state but the hinge angle, which changes every frame. */
  fun state(
    isFoldable: Boolean,
    posture: String,
    regions: List<Map<String, Any?>>,
  ): Map<String, Any?> = mapOf(
    "v" to VERSION,
    "isFoldable" to isFoldable,
    "posture" to posture,
    "regions" to regions,
    // UIKit's size classes; Android has none.
    "horizontalSizeClass" to "unspecified",
    "verticalSizeClass" to "unspecified",
  )
}
