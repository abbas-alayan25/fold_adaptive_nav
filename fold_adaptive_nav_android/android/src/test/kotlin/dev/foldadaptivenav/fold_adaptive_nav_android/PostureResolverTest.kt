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
  fun foldableWithoutSensorOrFeatureIsClosed() {
    assertEquals("closed", PostureResolver.resolve(true, null, null))
  }
}
