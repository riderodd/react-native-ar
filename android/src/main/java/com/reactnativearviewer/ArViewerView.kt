package com.reactnativearviewer

import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import android.view.MotionEvent
import android.view.PixelCopy
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.core.view.children
import androidx.core.net.toUri
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.google.ar.core.Anchor
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.Pose
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import dev.romainguy.kotlin.math.Quaternion
import io.github.sceneview.ar.ARSceneView
import io.github.sceneview.ar.node.AnchorNode
import io.github.sceneview.gesture.GestureDetector
import io.github.sceneview.math.Position
import io.github.sceneview.math.Rotation
import io.github.sceneview.math.Scale
import io.github.sceneview.math.toQuaternion
import io.github.sceneview.node.ModelNode
import io.github.sceneview.node.Node
import io.github.sceneview.utils.FileLoader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File

class ArViewerView(private val reactContext: ThemedReactContext) : FrameLayout(reactContext) {
  private var sceneView: ARSceneView? = null
  private var anchorNode: AnchorNode? = null
  private var modelNode: ModelNode? = null
  private val instructions = InstructionsController(this)
  private val scope: CoroutineScope = MainScope()
  private var modelJob: Job? = null

  private var modelSource = ""
  private var planeOrientation = "both"
  private var isLightEstimationEnabled = false
  private var isDepthManagementEnabled = false
  private var isInstantPlacementEnabled = true
  private var isInstructionsEnabled = true
  private var allowScale = false
  private var allowRotate = false
  private var allowTranslate = false
  private var isStarted = false
  private var hasTrackedPlane = false
  private var isLayoutRequested = false

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    if (sceneView == null) {
      createSceneView()
    }
  }

  override fun onDetachedFromWindow() {
    // ARSceneView destroys its renderer and ARCore session when detached
    releaseScene()
    super.onDetachedFromWindow()
  }

  fun destroy() {
    releaseScene()
    scope.cancel()
  }

  // React Native does not lay out native children, so it has to be done manually
  override fun requestLayout() {
    super.requestLayout()
    if (!isLayoutRequested) {
      isLayoutRequested = true
      post {
        isLayoutRequested = false
        measure(
          MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
          MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
        )
        layout(left, top, right, bottom)
      }
    }
  }

  private fun createSceneView() {
    val activity = reactContext.currentActivity as? ComponentActivity
    if (activity == null) {
      emitError("The AR view requires a ComponentActivity")
      return
    }
    if (!isOpenGlEs3Supported(activity)) {
      emitError("This feature requires OpenGL ES 3.0 or later")
      return
    }

    val view = ARSceneView(
      context = activity,
      sharedActivity = activity,
      sharedLifecycle = activity.lifecycle,
      sessionConfiguration = ::configureSession,
      onSessionResumed = { onSessionResumed() },
      onSessionFailed = { emitError(it.message ?: "Cannot start the AR session") },
      onSessionUpdated = ::onSessionUpdated,
      onGestureListener = object : GestureDetector.SimpleOnGestureListener() {
        override fun onSingleTapConfirmed(e: MotionEvent, node: Node?) {
          onSingleTap(e)
        }
      }
    ).apply {
      layoutParams = LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
    }
    // A detached ARSceneView has destroyed itself and cannot be resumed
    children.filterIsInstance<ARSceneView>().toList().forEach(::removeView)
    sceneView = view
    addView(view, 0)
    instructions.isVisible = true

    if (modelSource.isNotEmpty()) {
      loadModel()
    }
  }

  private fun releaseScene() {
    val view = sceneView ?: return
    modelJob?.cancel()
    anchorNode = null
    modelNode = null
    sceneView = null
    hasTrackedPlane = false
    view.destroy()
    if (isStarted) {
      isStarted = false
      emit(ArViewerEvent.ENDED)
    }
  }

  private fun onSessionResumed() {
    if (!isStarted) {
      isStarted = true
      emit(ArViewerEvent.STARTED)
    }
  }

  private fun configureSession(session: Session, config: Config) {
    config.planeFindingMode = when (planeOrientation) {
      "horizontal" -> Config.PlaneFindingMode.HORIZONTAL
      "vertical" -> Config.PlaneFindingMode.VERTICAL
      "none" -> Config.PlaneFindingMode.DISABLED
      else -> Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
    }
    config.lightEstimationMode = if (isLightEstimationEnabled) {
      Config.LightEstimationMode.ENVIRONMENTAL_HDR
    } else {
      Config.LightEstimationMode.DISABLED
    }
    config.depthMode = if (isDepthManagementEnabled && session.isDepthModeSupported(Config.DepthMode.AUTOMATIC)) {
      Config.DepthMode.AUTOMATIC
    } else {
      Config.DepthMode.DISABLED
    }
    sceneView?.cameraStream?.isDepthOcclusionEnabled = config.depthMode == Config.DepthMode.AUTOMATIC
  }

  private fun updateSessionConfig() {
    val session = sceneView?.session ?: return
    session.configure(session.config.apply { configureSession(session, this) })
  }

  private fun onSessionUpdated(session: Session, frame: Frame) {
    if (!hasTrackedPlane) {
      hasTrackedPlane = session.getAllTrackables(Plane::class.java)
        .any { it.trackingState == TrackingState.TRACKING }
      instructions.isVisible = !hasTrackedPlane
    }

    if (isInstantPlacementEnabled && anchorNode == null && modelNode != null &&
      frame.camera.trackingState == TrackingState.TRACKING
    ) {
      runCatching { session.createAnchor(Pose.makeTranslation(0f, 0f, -1f)) }
        .onSuccess(::placeModel)
    }
  }

  private fun onSingleTap(event: MotionEvent) {
    val view = sceneView ?: return
    if (modelNode == null) return
    val hitResult = view.hitTestAR(event.x, event.y, planeTypes = allowedPlaneTypes()) ?: return
    runCatching { hitResult.createAnchor() }.onSuccess(::placeModel)
  }

  private fun allowedPlaneTypes(): Set<Plane.Type> = when (planeOrientation) {
    "horizontal" -> setOf(Plane.Type.HORIZONTAL_UPWARD_FACING, Plane.Type.HORIZONTAL_DOWNWARD_FACING)
    "vertical" -> setOf(Plane.Type.VERTICAL)
    "none" -> emptySet()
    else -> Plane.Type.entries.toSet()
  }

  private fun placeModel(anchor: Anchor) {
    val view = sceneView
    val model = modelNode
    if (view == null || model == null) {
      anchor.detach()
      return
    }
    val wasPlaced = anchorNode != null
    detachModel()
    anchorNode = AnchorNode(view.engine, anchor).apply {
      isPositionEditable = allowTranslate
      addChildNode(model)
      view.addChildNode(this)
    }
    if (!wasPlaced) {
      emit(ArViewerEvent.MODEL_PLACED)
    }
  }

  /** Removes the anchor from the scene but keeps the model loaded. */
  private fun detachModel(): Boolean {
    val node = anchorNode ?: return false
    modelNode?.let { node.removeChildNode(it) }
    sceneView?.removeChildNode(node)
    node.destroy()
    anchorNode = null
    return true
  }

  private fun removeModel() {
    if (detachModel()) {
      emit(ArViewerEvent.MODEL_REMOVED)
    }
  }

  private fun loadModel() {
    val view = sceneView ?: return
    val location = modelSource.toModelLocation()
    modelJob?.cancel()
    removeModel()
    modelNode?.destroy()
    modelNode = null

    modelJob = scope.launch {
      val buffer = runCatching { FileLoader.loadFileBuffer(context, location) }.getOrNull()
      if (buffer == null) {
        emitError("Cannot load the model: $modelSource")
        return@launch
      }
      val instance = runCatching {
        view.modelLoader.createModelInstance(buffer) { resource ->
          FileLoader.readFileBuffer(context, location.substringBeforeLast('/') + "/" + resource)
        }
      }.getOrElse {
        emitError("Cannot load the model: ${it.message}")
        return@launch
      }
      modelNode = ModelNode(
        modelInstance = instance,
        autoAnimate = true,
        centerOrigin = Position(0f, -1f, 0f)
      ).apply { isEditable = true }
      updateTransforms()
    }
  }

  private fun String.toModelLocation(): String =
    if (startsWith("/")) File(this).toUri().toString() else this

  private fun updateTransforms() {
    modelNode?.apply {
      isPositionEditable = false
      isRotationEditable = allowRotate
      isScaleEditable = allowScale
    }
    anchorNode?.isPositionEditable = allowTranslate
  }

  fun setModel(source: String) {
    if (source == modelSource) return
    modelSource = source
    if (source.isEmpty()) {
      removeModel()
    } else {
      loadModel()
    }
  }

  fun setPlaneOrientation(orientation: String) {
    planeOrientation = orientation
    updateInstructions()
    updateSessionConfig()
  }

  fun setLightEstimation(enabled: Boolean) {
    isLightEstimationEnabled = enabled
    updateSessionConfig()
  }

  fun setManageDepth(enabled: Boolean) {
    isDepthManagementEnabled = enabled
    updateSessionConfig()
  }

  fun setInstructionsEnabled(enabled: Boolean) {
    isInstructionsEnabled = enabled
    updateInstructions()
  }

  private fun updateInstructions() {
    instructions.isEnabled = isInstructionsEnabled && planeOrientation != "none"
  }

  fun setInstantPlacementEnabled(enabled: Boolean) {
    isInstantPlacementEnabled = enabled
  }

  fun setAllowScale(allowed: Boolean) {
    allowScale = allowed
    updateTransforms()
  }

  fun setAllowRotate(allowed: Boolean) {
    allowRotate = allowed
    updateTransforms()
  }

  fun setAllowTranslate(allowed: Boolean) {
    allowTranslate = allowed
    updateTransforms()
  }

  fun reset() {
    removeModel()
    modelNode?.apply {
      quaternion = Quaternion()
      scale = Scale(1f)
    }
  }

  fun rotateModel(pitch: Float, yaw: Float, roll: Float) {
    modelNode?.apply {
      quaternion *= Rotation(pitch, yaw, roll).toQuaternion()
    }
  }

  fun takeScreenshot(requestId: Int) {
    val view = sceneView
    if (view == null || view.width == 0 || view.height == 0) {
      returnData(requestId, null, "The AR view is not ready")
      return
    }
    val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
    PixelCopy.request(view, bitmap, { result ->
      if (result != PixelCopy.SUCCESS) {
        returnData(requestId, null, "Cannot capture the AR view (PixelCopy error $result)")
        return@request
      }
      scope.launch {
        val encoded = withContext(Dispatchers.Default) {
          runCatching {
            ByteArrayOutputStream().use { stream ->
              bitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
              Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
            }
          }.also { bitmap.recycle() }
        }
        encoded.fold(
          onSuccess = { returnData(requestId, it, null) },
          onFailure = { returnData(requestId, null, "The image cannot be saved: ${it.message}") }
        )
      }
    }, Handler(Looper.getMainLooper()))
  }

  private fun returnData(requestId: Int, result: String?, error: String?) {
    emit(ArViewerEvent.DATA_RETURNED, Arguments.createMap().apply {
      putInt("requestId", requestId)
      putString("result", result.orEmpty())
      putString("error", error.orEmpty())
    })
  }

  private fun emitError(message: String) {
    Log.w(TAG, message)
    emit(ArViewerEvent.ERROR, Arguments.createMap().apply { putString("message", message) })
  }

  // The non-deprecated getEventDispatcher(context) only exists since React Native 0.82
  @Suppress("DEPRECATION")
  private fun emit(name: String, payload: WritableMap = Arguments.createMap()) {
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
    UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
      ?.dispatchEvent(ArViewerEvent(surfaceId, id, name, payload))
  }

  private fun isOpenGlEs3Supported(context: Context): Boolean {
    val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    return activityManager.deviceConfigurationInfo.reqGlEsVersion >= 0x30000
  }

  companion object {
    private const val TAG = "ArViewerView"
  }
}
