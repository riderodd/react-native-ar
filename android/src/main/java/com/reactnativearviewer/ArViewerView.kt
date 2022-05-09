package com.reactnativearviewer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Handler
import android.os.HandlerThread
import android.util.AttributeSet
import android.util.Base64
import android.util.Log
import android.view.MotionEvent
import android.view.PixelCopy
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.google.ar.core.HitResult
import io.github.sceneview.ar.ArSceneView
import io.github.sceneview.ar.arcore.ArSession
import io.github.sceneview.ar.node.ArModelNode
import io.github.sceneview.ar.node.EditableTransform
import io.github.sceneview.math.Position
import io.github.sceneview.node.Node
import io.github.sceneview.utils.FrameTime
import java.io.ByteArrayOutputStream
import java.lang.Thread.sleep


open class ArViewerView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null,
  defStyleAttr: Int = 0,
  defStyleRes: Int = 0
) : ArSceneView(context, attrs, defStyleAttr, defStyleRes) {
  /**
   * We show only one model, let's store the ref here
   */
  private lateinit var modelNode: ArModelNode

  /**
   * Reminder to keep track of model loading state
   */
  private var isLoading = false
  /**
   * Reminder to keep source of model loading
   */
  private var modelSrc: String = ""

  /**
   * Set of allowed model transformations (rotate, scale, translate...)
   */
  private var allowTransform = mutableSetOf<EditableTransform>()



  /**
   * Start the loading of a GLB model URI
   */
  fun loadModel(src: String) {
    if (this::modelNode.isInitialized && modelNode.isAttached) {
      Log.d("ARview model", "detaching")
      modelNode.detachAnchor()
      modelNode.destroy()
    }
    Log.d("ARview model", "loading")
    modelSrc = src
    isLoading = true
    modelNode = ArModelNode()
    modelNode.loadModelAsync(context = context,
      lifecycle = lifecycle,
      glbFileLocation = src,
      centerOrigin = Position(y = -1.0f),
      autoAnimate = true,
      onLoaded = {
        // add node to the scene
        Log.d("ARview model", "loaded")
        isLoading = false
      },
      onError = {
        Log.e("ARview model", "cannot load")
        returnErrorEvent("Cannot load the model: " + it.message)
      }
    )
    modelNode.editableTransforms = allowTransform


    context.checkSelfPermission("CAMERA")
  }

  /**
   * Remove the model from the view and reset plane detection
   */
  fun resetModel() {
    Log.d("ARview model", "Resetting model")
    if (this::modelNode.isInitialized) {
      loadModel(modelSrc)
    }
  }

  /**
   * Add a transformation to the allowed list
   */
  fun addAllowTransform(transform: EditableTransform) {
    allowTransform.add(transform)
    if (this::modelNode.isInitialized) {
      modelNode.editableTransforms = allowTransform
    }
  }

  /**
   * Remove a transformation to the allowed list
   */
  fun removeAllowTransform(transform: EditableTransform) {
    allowTransform.remove(transform)
    if (allowTransform.size == 0) allowTransform = EditableTransform.NONE as MutableSet<EditableTransform>
    if (this::modelNode.isInitialized) {
      modelNode.editableTransforms = allowTransform
    }
  }

  /**
   * When the session can't start (camera permission refused for example)
   */
  override fun onArSessionFailed(exception: Exception) {
    super.onArSessionFailed(exception)
    Log.d("ARview session", "failed")
    returnErrorEvent(exception.message)
  }


  /**
   * When the session has started, launch an event to JS
   */
  override fun onArSessionCreated(session: ArSession) {
    super.onArSessionCreated(session)
    Log.d("ARview session", "started")
    val event = Arguments.createMap()
    val reactContext = context as ReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "onStarted",
      event
    )
    sleep(500)
    arSession?.resume()
  }

  /**
   * Hide the planeRenderer when a model is added to the scene
   */
  override fun onChildAdded(child: Node) {
    super.onChildAdded(child)
    try {
      if (this::modelNode.isInitialized && modelNode.isAttached) {
        planeRenderer.isVisible = false
      }
    } catch (e: Exception) {
      Log.w("ARview planeRenderer", "failed turning invisible")
    }
  }

  /**
   * how the planeRenderer when there is no model shown on the scene
   */
  override fun onChildRemoved(child: Node) {
    super.onChildRemoved(child)
    try {
      if (this::modelNode.isInitialized && !modelNode.isAttached) {
        planeRenderer.isVisible = true
      }
    } catch (e: Exception) {
      Log.w("ARview planeRenderer", "failed turning visible")
    }
  }

  /**
   * Detect touch and add the model to the scene on the selected plane
   */
  override fun onTouchAr(hitResult: HitResult, motionEvent: MotionEvent) {
    Log.d("ARview touch", "received")
    super.onTouchAr(hitResult, motionEvent)
    if (!this::modelNode.isInitialized) {
      return
    }
    if (this.children.contains(modelNode)) {
      return
    }

    Log.d("ARview model", "attached")
    addChild(modelNode)
    val anchor = hitResult.createAnchor()
    modelNode.anchor = anchor
  }

  /**
   * Prevent parent from treating a frame when the session was paused before unmount
   */
  override fun doFrame(frameTime: FrameTime) {
    if(arSession == null || arSession!!.isResumed) super.doFrame(frameTime)
  }

  /**
   * Enable/Disable instructions
   */
  fun setInstructionsEnabled(isEnabled: Boolean) {
    instructions.enabled = isEnabled
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
    val handlerThread = HandlerThread("PixelCopier")
    var encodedImage: String? = null
    var encodedImageError: String? = null
    handlerThread.start()
    PixelCopy.request(this, bitmap, { copyResult ->
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
      handlerThread.quitSafely()
    }, Handler(handlerThread.looper))
  }

  /**
   * Send back an event to JS
   */
  private fun returnDataEvent(requestId: Int, result: String?, error: String?) {
    val event = Arguments.createMap()
    event.putString("requestId", requestId.toString())
    event.putString("result", result)
    event.putString("error", error)
    val reactContext = context as ReactContext
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
    val reactContext = context as ReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
      id,
      "onError",
      event
    )
  }

}
