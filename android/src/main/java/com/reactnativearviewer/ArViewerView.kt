package com.reactnativearviewer

import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import com.google.ar.core.HitResult
import io.github.sceneview.ar.ArSceneView
import io.github.sceneview.ar.node.ArModelNode
import io.github.sceneview.ar.node.EditableTransform
import io.github.sceneview.math.Position
import io.github.sceneview.node.Node

open class ArViewerView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null,
  defStyleAttr: Int = 0,
  defStyleRes: Int = 0
) : ArSceneView(context, attrs, defStyleAttr, defStyleRes) {
  private lateinit var modelNode: ArModelNode
  private var isLoading = false
  private var allowTransform: MutableSet<EditableTransform> = EditableTransform.NONE as MutableSet<EditableTransform>

  fun loadModel(src: String) {
    if (this::modelNode.isInitialized && modelNode.isAttached) {
      Log.d("ARview model", "detaching");
      modelNode.detachAnchor()
      modelNode.destroy()
    }
    Log.d("ARview model", "loading");
    isLoading = true
    modelNode = ArModelNode()
    modelNode.loadModelAsync(context = context,
      lifecycle = lifecycle,
      glbFileLocation = src,
      centerOrigin = Position(y = -1.0f),
      onLoaded = {
        // add node to the scene
        Log.d("ARview model", "loaded");
        isLoading = false
      },
      onError = {
        Log.e("ARview model", "cannot load");
      }
    )
    modelNode.editableTransforms = allowTransform
  }

  fun addAllowTransform(transform: EditableTransform) {
    allowTransform.add(transform)
    if (this::modelNode.isInitialized) {
      modelNode.editableTransforms = allowTransform
    }
  }

  fun removeAllowTransform(transform: EditableTransform) {
    allowTransform.remove(transform)
    if (allowTransform.size === 0) allowTransform = EditableTransform.NONE as MutableSet<EditableTransform>
    if (this::modelNode.isInitialized) {
      modelNode.editableTransforms = allowTransform
    }
  }

  override fun onArSessionFailed(exception: Exception) {
    Log.d("ARview session", "failed");
    super.onArSessionFailed(exception)
    if (this::modelNode.isInitialized) {
      modelNode.centerModel(origin = Position(x = 0.0f, y = 0.0f, z = 0.0f))
      modelNode.scaleModel(units = 1.0f)
      this.addChild(modelNode)
    }
  }

  override fun onChildAdded(child: Node) {
    super.onChildAdded(child)
    try {
      planeRenderer.isVisible = false
    } catch (e: Exception) {
      Log.w("ARview planeRenderer", "failed turning invisible");
    }
  }

  override fun onChildRemoved(child: Node) {
    super.onChildRemoved(child)
    try {
      planeRenderer.isVisible = true
    } catch (e: Exception) {
      Log.w("ARview planeRenderer", "failed turning visible");
    }
  }

  override fun onTouchAr(hitResult: HitResult, motionEvent: MotionEvent) {
    Log.d("ARview touch", "received");
    super.onTouchAr(hitResult, motionEvent)
    if (!this::modelNode.isInitialized) {
      return
    }
    if (this.children.contains(modelNode)) {
      return;
    }

    Log.d("ARview model", "attached");
    addChild(modelNode)
    var anchor = hitResult.createAnchor()
    modelNode.anchor = anchor
  }
}
