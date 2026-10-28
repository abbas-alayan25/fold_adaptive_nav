package dev.foldadaptivenav.fold_adaptive_nav_android

import kotlin.test.Test
import kotlin.test.assertEquals

class WireStateTest {
  @Test
  fun foldBoundsAreLogicalPixels() {
    // A Pixel Fold's hinge: zero width, down the middle, at density 2.625.
    val fold = WireState.fold(
      left = 1104, top = 0, width = 0, height = 1840, density = 2.625f,
      halfOpened = false, separating = false, fullOcclusion = false, vertical = true,
    )
    assertEquals("fold", fold["kind"])
    assertEquals(1104 / 2.625, fold["left"] as Double, 1e-3)
    assertEquals(0.0, fold["width"])
    assertEquals(1840 / 2.625, fold["height"] as Double, 1e-3)
    assertEquals("vertical", fold["orientation"])
    assertEquals(false, fold["isActive"])
  }

  @Test
  fun halfOpenedFoldIsActive() {
    val fold = WireState.fold(
      left = 0, top = 1320, width = 1080, height = 0, density = 2.625f,
      halfOpened = true, separating = true, fullOcclusion = true, vertical = false,
    )
    assertEquals(true, fold["isActive"])
    assertEquals(true, fold["isSeparating"])
    assertEquals("full", fold["occlusionType"])
    assertEquals("horizontal", fold["orientation"])
  }

  @Test
  fun zeroDensityFallsBackToOne() {
    val fold = WireState.fold(
      left = 10, top = 20, width = 30, height = 40, density = 0f,
      halfOpened = false, separating = false, fullOcclusion = false, vertical = true,
    )
    assertEquals(10.0, fold["left"])
    assertEquals(40.0, fold["height"])
  }

  /** The keys the Dart codec reads; see codec_test.dart's "Android map". */
  @Test
  fun stateHasTheWireKeys() {
    val state = WireState.state(isFoldable = true, posture = "fullyOpen", regions = emptyList())
    assertEquals(
      setOf("v", "isFoldable", "posture", "regions", "horizontalSizeClass", "verticalSizeClass"),
      state.keys,
    )
    assertEquals(1, state["v"])
    assertEquals("unspecified", state["horizontalSizeClass"])
  }
}
