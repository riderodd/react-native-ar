package com.reactnativearviewer

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.util.Base64
import android.util.Log
import android.view.*
import android.view.GestureDetector.SimpleOnGestureListener
import android.view.ViewTreeObserver.OnWindowFocusChangeListener
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.google.android.filament.utils.Float3
import com.google.ar.core.*
import com.google.ar.core.ArCoreApk.InstallStatus
import com.google.ar.core.exceptions.UnavailableException
import com.google.ar.sceneform.*
import com.google.ar.sceneform.math.Quaternion
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.rendering.CameraStream
import com.google.ar.sceneform.rendering.ModelRenderable
import com.google.ar.sceneform.ux.BaseArFragment.OnSessionConfigurationListener
import com.google.ar.sceneform.ux.FootprintSelectionVisualizer
import com.google.ar.sceneform.ux.TransformableNode
import com.google.ar.sceneform.ux.TransformationSystem
import java.io.ByteArrayOutputStream


class ArViewerView @JvmOverloads constructor(
  context: ThemedReactContext, attrs: AttributeSet? = null, defStyleAttr: Int = 0
): FrameLayout(context, attrs, defStyleAttr), Scene.OnPeekTouchListener, Scene.OnUpdateListener {
  /**
   * We show only one model, let's store the ref here
   */
  private var modelNode: TransformableNode? = null
  /**
   * Our main view that integrates with ARCore and renders a scene
   */
  private var arView: ArSceneView? = null
  /**
   * Event listener that triggers on focus
   */
  private val onFocusListener = OnWindowFocusChangeListener { onWindowFocusChanged(it) }
  /**
   * Event listener that triggers when the ARCore Session is to be configured
   */
  private val onSessionConfigurationListener: OnSessionConfigurationListener? = null

  /**
   * Main view state
   */
  private var isStarted = false
  /**
   * ARCore installation requirement state
   */
  private var installRequested = false
  /**
   * Failed session initialization state
   */
  private var sessionInitializationFailed = false
  /**
   * Depth management enabled state
   */
  private var isDepthManagementEnabled = false
  /**
   * Light estimation enabled state
   */
  private var isLightEstimationEnabled = false
  /**
   * Instant placement enabled state
   */
  private var isInstantPlacementEnabled = true
  /**
   * Plane orientation mode
   */
  private var planeOrientationMode: String = "both"
  /**
   * Instructions enabled state
   */
  private var isInstructionsEnabled = true
  /**
   * Device supported state
   */
  private var isDeviceSupported = true
  /**
   * Reminder to keep track of model loading state
   */
  private var isLoading = false

  /**
   * Config of the main session initialization
   */
  private var sessionConfig: Config? = null
  /**
   * AR session initialization
   */
  private var arSession: Session? = null
  /**
   * Instructions controller initialization
   */
  private var instructionsController: InstructionsController? = null
  /**
   * Transformation system initialization
   */
  private var transformationSystem: TransformationSystem? = null
  /**
   * Gesture detector initialization
   */
  private var gestureDetector: GestureDetector? = null

  /**
   * Reminder to keep source of model loading
   */
  private var modelSrc: String = ""
  /**
   * Set of allowed model transformations (rotate, scale, translate...)
   */
  private var allowTransform = mutableSetOf<String>()

  init {
    if (checkIsSupportedDevice(context.currentActivity!!)) {
      // let's create sceneform view
      arView = ArSceneView(context, attrs)
      arView!!.layoutParams = LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
      this.addView(arView)

      transformationSystem = makeTransformationSystem()

      gestureDetector = GestureDetector(
        context,
        object : SimpleOnGestureListener() {
          override fun onSingleTapUp(e: MotionEvent): Boolean {
            onSingleTap(e)
            return true
          }

          override fun onDown(e: MotionEvent): Boolean {
            return true
          }
        })

      arView!!.scene.addOnPeekTouchListener(this)
      arView!!.scene.addOnUpdateListener(this)
      arView!!.viewTreeObserver.addOnWindowFocusChangeListener(onFocusListener)
      arView!!.setOnSessionConfigChangeListener(this::onSessionConfigChanged)

      val session = Session(context)
      val config = Config(session)

      // Set plane orientation mode
      updatePlaneDetection(config)
      // Enable or not light estimation
      updateLightEstimation(config)
      // Enable or not depth management
      updateDepthManagement(config)

      // Sets the desired focus mode
      config.focusMode = Config.FocusMode.AUTO
      // Force the non-blocking mode for the session.
      config.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE

      sessionConfig = config
      arSession = session
      arView!!.session?.configure(sessionConfig)
      arView!!.session = arSession

      initializeSession()
      resume()



      // Setup the instructions view.
      instructionsController = InstructionsController(context, this);
      instructionsController!!.setEnabled(isInstructionsEnabled);
    } else {
      isDeviceSupported = false
    }
  }

  private fun resume() {
    if (isStarted) {
      return
    }
    if ((context as ThemedReactContext).currentActivity != null) {
      isStarted = true
      try {
        arView!!.resume()
      } catch (ex: java.lang.Exception) {
        sessionInitializationFailed = true
        returnErrorEvent("Could not resume session")
      }
      if (!sessionInitializationFailed) {
        instructionsController?.setVisible(true)
      }
    }
  }

  /**
   * Initializes the ARCore session. The CAMERA permission is checked before checking the
   * installation state of ARCore. Once the permissions and installation are OK, the method
   * #getSessionConfiguration(Session session) is called to get the session configuration to use.
   * Sceneform requires that the ARCore session be updated using LATEST_CAMERA_IMAGE to avoid
   * blocking while drawing. This mode is set on the configuration object returned from the
   * subclass.
   */
  private fun initializeSession() {
    // Only try once
    if (sessionInitializationFailed) {
      return
    }
    // if we have the camera permission, create the session
    if (CameraPermissionHelper.hasCameraPermission((context as ThemedReactContext).currentActivity)) {
      val sessionException: UnavailableException?
      try {
        if (requestInstall()) {
          returnErrorEvent("ARCore installation required")
          return
        }
        onSessionConfigurationListener?.onSessionConfiguration(arSession, sessionConfig)

        // run a JS event
        Log.d("ARview session", "started")
        val event = Arguments.createMap()
        val reactContext = context as ThemedReactContext
        reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
          id,
          "onStarted",
          event
        )

        return
      } catch (e: UnavailableException) {
        sessionException = e
      } catch (e: java.lang.Exception) {
        sessionException = UnavailableException()
        sessionException.initCause(e)
      }
      sessionInitializationFailed = true
      returnErrorEvent(sessionException?.message)
    } else {
      returnErrorEvent("Missing camera permissions")
    }
  }

  /**
   * Removed the focus listener
   */
  fun onDrop() {
    if(arView != null) {
      arView!!.pause()
      arView!!.session?.close()
      arView!!.destroy()
      arView!!.viewTreeObserver.removeOnWindowFocusChangeListener(onFocusListener)
    }
  }

  /**
   * Occurs when a session configuration has changed.
   */
  private fun onSessionConfigChanged(config: Config) {
    instructionsController?.setEnabled(
      config.planeFindingMode !== Config.PlaneFindingMode.DISABLED
    )
  }

  /**
   * Creates the transformation system used by this view.
   */
  private fun makeTransformationSystem(): TransformationSystem {
    val selectionVisualizer = FootprintSelectionVisualizer()
    return TransformationSystem(resources.displayMetrics, selectionVisualizer)
  }

  /**
   * Makes the transformation system responding to touches
   */
  override fun onPeekTouch(hitTestResult: HitTestResult, motionEvent: MotionEvent?) {
    transformationSystem!!.onTouch(hitTestResult, motionEvent)
    if (hitTestResult.node == null) {
      gestureDetector!!.onTouchEvent(motionEvent)
    }
  }

  /**
   * On each frame
   */
  override fun onUpdate(frameTime: FrameTime?) {
    if (arView!!.session == null || arView!!.arFrame == null) return
    if (instructionsController != null) {
      // Instructions for the Plane finding mode.
      val showPlaneInstructions: Boolean = !arView!!.hasTrackedPlane()
      if (instructionsController?.isVisible() != showPlaneInstructions) {
        instructionsController?.setVisible(
          showPlaneInstructions
        )
      }
    }

    if (isInstantPlacementEnabled && arView!!.arFrame?.camera?.trackingState == TrackingState.TRACKING) {
      // Check if there is already an anchor
      if (modelNode?.parent is AnchorNode) {
        return
      }

      // Create the Anchor.
      val pos = floatArrayOf(0f, 0f, -1f)
      val rotation = floatArrayOf(0f, 0f, 0f, 1f)
      val anchor: Anchor = arView!!.session!!.createAnchor(Pose(pos, rotation))
      initAnchorNode(anchor)

      // tells JS that the model is visible
      onModelPlaced()
    }
  }

  fun onSingleTap(motionEvent: MotionEvent?) {
    if (arView != null) {
      val frame: Frame? = arView!!.arFrame
      transformationSystem?.selectNode(null)

      if (frame != null) {
        if (motionEvent != null && frame.camera.trackingState === TrackingState.TRACKING) {
          for (hitResult in frame.hitTest(motionEvent)) {
            val trackable = hitResult.trackable
            if (trackable is Plane && trackable.isPoseInPolygon(hitResult.hitPose) && modelNode != null) {
              // Remove old anchor (if any)
              var modelAlreadyAttached = false
              if (modelNode?.parent is AnchorNode) {
                (modelNode!!.parent as AnchorNode).anchor?.detach()
                modelAlreadyAttached = true
              }

              // Create the Anchor
              val anchor: Anchor = arView!!.session!!.createAnchor(hitResult.hitPose)
              initAnchorNode(anchor)

              // tells JS that the model is visible
              if (!modelAlreadyAttached) {
                onModelPlaced()
              }
              break
            }
          }
        }
      }
    }
  }

  private fun initAnchorNode(anchor: Anchor) {
    val anchorNode = AnchorNode(anchor)
    anchorNode.parent = arView!!.scene
    modelNode!!.parent = anchorNode

    // Attach the model to the new anchor
    arView!!.scene.addChild(anchorNode)

    // Animate if has animation
    val renderableInstance = modelNode?.renderableInstance
    if (renderableInstance != null && renderableInstance.hasAnimations()) {
      renderableInstance.animate(true).start()
    }
  }

  private fun onModelPlaced() {
    val event = Arguments.createMap()
    val reactContext = context as ThemedReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "onModelPlaced",
      event
    )
  }

  /**
   * Request ARCore installation
   */
  private fun requestInstall(): Boolean {
    when (ArCoreApk.getInstance().requestInstall((context as ThemedReactContext).currentActivity, !installRequested)) {
      InstallStatus.INSTALL_REQUESTED -> {
        installRequested = true
        return true
      }
      InstallStatus.INSTALLED -> {}
    }
    return false
  }

  /**
   * Set plane detection orientation
   */
  fun setPlaneDetection(planeOrientation: String) {
    planeOrientationMode = planeOrientation
    sessionConfig.let {
      updatePlaneDetection(sessionConfig)
      updateConfig()
    }
  }

  private fun updatePlaneDetection(config: Config?) {
    when (planeOrientationMode) {
      "horizontal" -> {
        config?.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
      }
      "vertical" -> {
        config?.planeFindingMode = Config.PlaneFindingMode.VERTICAL
      }
      "both" -> {
        config?.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
      }
      "none" -> {
        config?.planeFindingMode = Config.PlaneFindingMode.DISABLED
      }
    }
  }

  /**
   * Set whether instant placement is enabled
   */
  fun setInstantPlacementEnabled(isEnabled: Boolean) {
    isInstantPlacementEnabled = isEnabled
  }

  /**
   * Set whether light estimation is enabled
   */
  fun setLightEstimationEnabled(isEnabled: Boolean) {
    isLightEstimationEnabled = isEnabled
    sessionConfig.let {
      updateLightEstimation(sessionConfig)
      updateConfig()
    }
  }

  private fun updateLightEstimation(config: Config?) {
    if(!isLightEstimationEnabled) {
      config?.lightEstimationMode = Config.LightEstimationMode.DISABLED
    } else {
      config?.lightEstimationMode = Config.LightEstimationMode.AMBIENT_INTENSITY
    }
  }

  /**
   * Set whether depth management is enabled
   */
  fun setDepthManagementEnabled(isEnabled: Boolean) {
    isDepthManagementEnabled = isEnabled
    sessionConfig.let {
      updateDepthManagement(sessionConfig)
      updateConfig()
    }
  }

  private fun updateDepthManagement(config: Config?) {
    if (!isDepthManagementEnabled) {
      sessionConfig?.depthMode = Config.DepthMode.DISABLED
      arView?.cameraStream?.depthOcclusionMode = CameraStream.DepthOcclusionMode.DEPTH_OCCLUSION_DISABLED
    } else {
      if(arSession?.isDepthModeSupported(Config.DepthMode.AUTOMATIC) == true) {
        sessionConfig?.depthMode = Config.DepthMode.AUTOMATIC
      }
      arView?.cameraStream?.depthOcclusionMode = CameraStream.DepthOcclusionMode.DEPTH_OCCLUSION_ENABLED
    }
  }

  private fun updateConfig() {
    if (isStarted) {
      arSession?.configure(sessionConfig)
    }
  }

  /**
   * Start the loading of a GLB model URI
   */
  fun loadModel(src: String) {
    if (isDeviceSupported) {
      if (modelNode?.parent is AnchorNode) {
        Log.d("ARview model", "detaching")
        (modelNode!!.parent as AnchorNode).anchor?.detach() // free up memory of anchor
        arView?.scene?.removeChild(modelNode)
        modelNode = null
        val event = Arguments.createMap()
        val reactContext = context as ThemedReactContext
        reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
          id,
          "onModelRemoved",
          event
        )
      }
      Log.d("ARview model", "loading")
      modelSrc = src
      isLoading = true

      ModelRenderable.builder()
        .setSource(context, Uri.parse(src))
        .setIsFilamentGltf(true)
        .build()
        .thenAccept {
          modelNode = TransformableNode(transformationSystem)
          modelNode!!.select()

          // to set local position in front of touch, let's create a node inside the anchor
          val containerModel = Node()
          containerModel.parent = modelNode
          containerModel.renderable = it
          containerModel.renderableInstance.filamentAsset?.let { asset ->
            // center the model origin
            val center = asset.boundingBox.center.let { v -> Float3(v[0], v[1], v[2]) }
            val halfExtent = asset.boundingBox.halfExtent.let { v -> Float3(v[0], v[1], v[2]) }
            val origin = Float3(0f, -1f, 1f)
            val fCenter = -(center + halfExtent * origin) * Float3(1f, 1f, 1f)
            containerModel.localPosition = Vector3(fCenter.x, fCenter.y, fCenter.z)
          }

          Log.d("ARview model", "loaded")
          isLoading = false
        }
        .exceptionally {
          Log.e("ARview model", "cannot load")
          returnErrorEvent("Cannot load the model: " + it.message)
          return@exceptionally null
        }
    } else {
      Log.e("ARview model", "This device is not supported")
      returnErrorEvent("This device is not supported")
    }
  }

  /**
   * Rotate the model with the requested angle
   */
  fun rotateModel(pitch: Number, yaw: Number, roll:Number) {
    Log.d("ARview rotateModel", "pitch: $pitch deg / yaw: $yaw deg / roll: $roll deg")
    modelNode?.localRotation = Quaternion.multiply(modelNode?.localRotation, Quaternion.eulerAngles(Vector3(pitch.toFloat(), yaw.toFloat(), roll.toFloat())))
  }

  /**
   * Remove the model from the view and reset plane detection
   */
  fun resetModel() {
    Log.d("ARview model", "Resetting model")
    if (modelNode != null) {
      loadModel(modelSrc)
    }
  }

  /**
   * Add a transformation to the allowed list
   */
  fun addAllowTransform(transform: String) {
    allowTransform.add(transform)
    onTransformChanged()
  }

  /**
   * Remove a transformation to the allowed list
   */
  fun removeAllowTransform(transform: String) {
    allowTransform.remove(transform)
    onTransformChanged()
  }

  private fun onTransformChanged() {
    if (modelNode == null) return
    modelNode!!.scaleController.isEnabled = allowTransform.contains("scale")
    modelNode!!.rotationController.isEnabled = allowTransform.contains("rotate")
    modelNode!!.translationController.isEnabled = allowTransform.contains("translate")
  }

  /**
   * Enable/Disable instructions
   */
  fun setInstructionsEnabled(isEnabled: Boolean) {
    isInstructionsEnabled = isEnabled
    instructionsController?.setEnabled(isInstructionsEnabled)
  }

  /**
   * Takes a screenshot of the view and send it to JS through event
   */
  fun takeScreenshot(requestId: Int) {
    Log.d("ARview takeScreenshot", requestId.toString())

    val bitmap = Bitmap.createBitmap(
      width, height,
      Bitmap.Config.ARGB_8888
    )
    var encodedImage: String? = null
    var encodedImageError: String? = null
    PixelCopy.request(arView!!, bitmap, { copyResult ->
      if (copyResult == PixelCopy.SUCCESS) {
        try {
          val byteArrayOutputStream = ByteArrayOutputStream()
          bitmap.compress(Bitmap.CompressFormat.JPEG, 70, byteArrayOutputStream)
          val byteArray = byteArrayOutputStream.toByteArray()
          val encoded = Base64.encodeToString(byteArray, Base64.DEFAULT)
          encodedImage = encoded
          Log.d("ARview takeScreenshot", "success")
        } catch (e: Exception) {
          encodedImageError = "The image cannot be saved: " + e.localizedMessage
          Log.d("ARview takeScreenshot", "fail")
        }
        returnDataEvent(requestId, encodedImage, encodedImageError)
      }
    }, Handler(Looper.getMainLooper()))
  }

  /**
   * Send back an event to JS
   */
  private fun returnDataEvent(requestId: Int, result: String?, error: String?) {
    val event = Arguments.createMap()
    event.putString("requestId", requestId.toString())
    event.putString("result", result)
    event.putString("error", error)
    val reactContext = context as ThemedReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "onDataReturned",
      event
    )
  }

  /**
   * Send back an error event to JS
   */
  private fun returnErrorEvent(message: String?) {
    val event = Arguments.createMap()
    event.putString("message", message)
    val reactContext = context as ThemedReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "onError",
      event
    )
  }

  /**
   * Returns false and displays an error message if Sceneform can not run, true if Sceneform can run
   * on this device.
   *
   *
   * Sceneform requires Android N on the device as well as OpenGL 3.0 capabilities.
   *
   *
   * Finishes the activity if Sceneform can not run
   */
  private fun checkIsSupportedDevice(activity: Activity): Boolean {
    val openGlVersionString =
      (activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
        .deviceConfigurationInfo
        .glEsVersion
    if (openGlVersionString.toDouble() < 3.0) {
      returnErrorEvent("This feature requires OpenGL ES 3.0 later")
      return false
    }
    return true
  }
}
