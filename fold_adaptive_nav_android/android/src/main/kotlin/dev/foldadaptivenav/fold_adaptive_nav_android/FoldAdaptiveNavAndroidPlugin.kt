package dev.foldadaptivenav.fold_adaptive_nav_android

import android.app.Activity
import android.app.Application
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Choreographer
import androidx.core.util.Consumer
import androidx.window.java.layout.WindowInfoTrackerCallbackAdapter
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import androidx.window.layout.WindowLayoutInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

class FoldAdaptiveNavAndroidPlugin :
  FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

  private var methods: MethodChannel? = null
  private var stateChannel: EventChannel? = null
  private var angleChannel: EventChannel? = null
  private var stateSink: EventChannel.EventSink? = null
  private var angleSink: EventChannel.EventSink? = null

  private var activity: Activity? = null
  private var tracker: WindowInfoTrackerCallbackAdapter? = null
  private var sensorManager: SensorManager? = null
  private var hingeSensor: Sensor? = null
  private var started = false

  private val mainHandler = Handler(Looper.getMainLooper())
  private val mainExecutor = Executor { mainHandler.post(it) }

  private var fold: FoldingFeature? = null
  private var hasSeenFold = false
  private var hingeAngle: Float? = null
  private var lastPublished: Map<String, Any?>? = null

  private var angleFrameScheduled = false
  private var lastSentAngle: Float? = null

  // region FlutterPlugin

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val messenger = binding.binaryMessenger
    methods = MethodChannel(messenger, "fold_adaptive_nav/methods").also {
      it.setMethodCallHandler(this)
    }
    stateChannel = EventChannel(messenger, "fold_adaptive_nav/state").also {
      it.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
          stateSink = events
          events.success(snapshot())
        }

        override fun onCancel(arguments: Any?) {
          stateSink = null
        }
      })
    }
    angleChannel = EventChannel(messenger, "fold_adaptive_nav/angle").also {
      it.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
          angleSink = events
          lastSentAngle = null
          scheduleAngleFrame()
        }

        override fun onCancel(arguments: Any?) {
          angleSink = null
        }
      })
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methods?.setMethodCallHandler(null)
    stateChannel?.setStreamHandler(null)
    angleChannel?.setStreamHandler(null)
    methods = null
    stateChannel = null
    angleChannel = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "snapshot" -> result.success(snapshot())
      // The vertical system bar is an iOS concept.
      "setVerticalSystemBarDisabled" -> result.success(null)
      else -> result.notImplemented()
    }
  }

  // endregion

  // region ActivityAware

  override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding.activity)

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
    attach(binding.activity)

  override fun onDetachedFromActivityForConfigChanges() = detach()

  override fun onDetachedFromActivity() = detach()

  private fun attach(activity: Activity) {
    this.activity = activity
    tracker = WindowInfoTrackerCallbackAdapter(WindowInfoTracker.getOrCreate(activity))
    if (Build.VERSION.SDK_INT >= 30) {
      sensorManager = activity.getSystemService(SensorManager::class.java)
      hingeSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE)
    }
    activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    // Plugins attach while the activity is being created; it is about to start.
    start()
  }

  private fun detach() {
    stop()
    activity?.application?.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
    activity = null
    tracker = null
    sensorManager = null
    hingeSensor = null
  }

  /** Listens only while the activity is started; the hinge sensor costs battery. */
  private fun start() {
    val activity = activity ?: return
    if (started) return
    started = true
    tracker?.addWindowLayoutInfoListener(activity, mainExecutor, layoutListener)
    hingeSensor?.let {
      sensorManager?.registerListener(sensorListener, it, SensorManager.SENSOR_DELAY_UI)
    }
  }

  private fun stop() {
    if (!started) return
    started = false
    tracker?.removeWindowLayoutInfoListener(layoutListener)
    sensorManager?.unregisterListener(sensorListener)
  }

  private val lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
    override fun onActivityStarted(a: Activity) {
      if (a === activity) start()
    }

    override fun onActivityStopped(a: Activity) {
      if (a === activity) stop()
    }

    override fun onActivityCreated(a: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityResumed(a: Activity) {}
    override fun onActivityPaused(a: Activity) {}
    override fun onActivitySaveInstanceState(a: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(a: Activity) {}
  }

  // endregion

  // region Readings

  private val layoutListener = Consumer<WindowLayoutInfo> { info ->
    fold = info.displayFeatures.filterIsInstance<FoldingFeature>().firstOrNull()
    // A closed foldable reports no fold, so remember having seen one.
    if (fold != null) hasSeenFold = true
    publishIfChanged()
  }

  private val sensorListener = object : SensorEventListener {
    override fun onSensorChanged(event: SensorEvent) {
      hingeAngle = event.values.firstOrNull()
      scheduleAngleFrame()
      publishIfChanged()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
  }

  private val isFoldable: Boolean
    get() {
      val pm = activity?.packageManager
      val hasHingeSensor = Build.VERSION.SDK_INT >= 30 &&
        pm?.hasSystemFeature(PackageManager.FEATURE_SENSOR_HINGE_ANGLE) == true
      return hasHingeSensor || hasSeenFold
    }

  private fun posture(): String {
    val state = when (fold?.state) {
      FoldingFeature.State.HALF_OPENED -> FoldFeatureState.HALF_OPENED
      FoldingFeature.State.FLAT -> FoldFeatureState.FLAT
      else -> null
    }
    return PostureResolver.resolve(isFoldable, state, hingeSensor?.let { hingeAngle })
  }

  private fun stateWithoutAngle(): Map<String, Any?> {
    val density = activity?.resources?.displayMetrics?.density ?: 1f
    val regions = fold?.let {
      // WindowManager reports physical pixels; Flutter wants logical ones.
      val b = it.bounds
      listOf(
        mapOf(
          "kind" to "fold",
          "left" to (b.left / density).toDouble(),
          "top" to (b.top / density).toDouble(),
          "width" to (b.width() / density).toDouble(),
          "height" to (b.height() / density).toDouble(),
          "isActive" to (it.state == FoldingFeature.State.HALF_OPENED),
          "isSeparating" to it.isSeparating,
          "occlusionType" to if (it.occlusionType == FoldingFeature.OcclusionType.FULL) "full" else "none",
          "orientation" to if (it.orientation == FoldingFeature.Orientation.VERTICAL) "vertical" else "horizontal",
        ),
      )
    } ?: emptyList()
    return mapOf(
      "v" to 1,
      "isFoldable" to isFoldable,
      "posture" to posture(),
      "regions" to regions,
      "horizontalSizeClass" to "unspecified",
      "verticalSizeClass" to "unspecified",
    )
  }

  private fun snapshot(): Map<String, Any?> =
    stateWithoutAngle() + ("hingeAngle" to hingeAngle?.toDouble())

  private fun publishIfChanged() {
    // The angle moves every frame while folding; it isn't a reason to publish.
    val comparable = stateWithoutAngle()
    if (comparable == lastPublished) return
    lastPublished = comparable
    stateSink?.success(snapshot())
  }

  /** At most one angle per display frame, and only when it changed. */
  private fun scheduleAngleFrame() {
    if (angleSink == null || angleFrameScheduled) return
    angleFrameScheduled = true
    Choreographer.getInstance().postFrameCallback {
      angleFrameScheduled = false
      val angle = hingeAngle ?: return@postFrameCallback
      if (angle == lastSentAngle) return@postFrameCallback
      lastSentAngle = angle
      angleSink?.success(angle.toDouble())
    }
  }

  // endregion
}
