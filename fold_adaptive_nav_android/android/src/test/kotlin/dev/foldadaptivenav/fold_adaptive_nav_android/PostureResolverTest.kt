package dev.foldadaptivenav.fold_adaptive_nav_android

import kotlin.test.Test
import kotlin.test.assertEquals

class PostureResolverTest {
  @Test
  fun foldFeatureWins() {
    assertEquals("partiallyOpen", PostureResolver.resolve(true, FoldFeatureState.HALF_OPENED, 10f))
    assertEquals("fullyOpen", PostureResolver.resolve(true, FoldFeatureState.FLAT, null))
  }

  @Test
  fun plainPhoneIsUnknown() {
    assertEquals("unknown", PostureResolver.resolve(false, null, null))
  }

  @Test
  fun foldableWithoutFeatureUsesSensor() {
    assertEquals("closed", PostureResolver.resolve(true, null, 5f))
    assertEquals("partiallyOpen", PostureResolver.resolve(true, null, 90f))
    assertEquals("fullyOpen", PostureResolver.resolve(true, null, 175f))
  }

  @Test
  fun sensorThresholdsAreInclusiveAtTheTop() {
    val below = PostureResolver.CLOSED_BELOW_DEGREES
    val flat = PostureResolver.FLAT_FROM_DEGREES
    assertEquals("closed", PostureResolver.resolve(true, null, below - 0.1f))
    assertEquals("partiallyOpen", PostureResolver.resolve(true, null, below))
    assertEquals("partiallyOpen", PostureResolver.resolve(true, null, flat - 0.1f))
    assertEquals("fullyOpen", PostureResolver.resolve(true, null, flat))
  }

  @Test
  fun foldFeatureWinsOverTheSensor() {
    // The window spans the fold, flat, while the sensor still lags at 20°.
    assertEquals("fullyOpen", PostureResolver.resolve(true, FoldFeatureState.FLAT, 20f))
  }

  @Test
  fun aFoldFeatureOnAPhoneStillCounts() {
    assertEquals("partiallyOpen", PostureResolver.resolve(false, FoldFeatureState.HALF_OPENED, null))
  }

  @Test
  fun foldableWithoutSensorOrFeatureIsClosed() {
    assertEquals("closed", PostureResolver.resolve(true, null, null))
  }
}
