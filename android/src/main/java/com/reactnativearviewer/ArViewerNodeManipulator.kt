package com.reactnativearviewer

import com.google.ar.core.*
import com.google.ar.sceneform.math.MathHelper
import com.google.ar.sceneform.math.Vector3
import dev.romainguy.kotlin.math.Quaternion
import dev.romainguy.kotlin.math.dot
import dev.romainguy.kotlin.math.slerp
import io.github.sceneview.ar.ArSceneView
import io.github.sceneview.ar.arcore.ArFrame
import io.github.sceneview.ar.interaction.ArNodeManipulator
import io.github.sceneview.ar.node.ArNode
import io.github.sceneview.ar.node.EditableTransform
import io.github.sceneview.math.*
import io.github.sceneview.utils.FrameTime
import java.util.*
import kotlin.math.abs


class ArViewerNodeManipulator(sceneView: ArSceneView) : ArNodeManipulator(sceneView) {

  private var lastArHitResult: HitResult? = null
  private var desiredLocalPosition: Vector3? = null
    set(value) {
      field = value
      updatePosition(sceneView.currentFrameTime)
    }

  private var desiredLocalRotation: Quaternion? = null
    set(value) {
      field = value
      updateRotation(sceneView.currentFrameTime)
    }

  private val initialForwardInLocal = Vector3()
  private var allowedPlaneTypes: EnumSet<Plane.Type> = EnumSet.allOf(Plane.Type::class.java)

  private val LERP_SPEED = 12.0f
  private val POSITION_LENGTH_THRESHOLD = 0.01f
  private val ROTATION_DOT_THRESHOLD = 0.99f

  /** Sets which types of ArCore Planes this TranslationController is allowed to translate on.  */
  fun setAllowedPlaneTypes(allowedPlaneTypes: EnumSet<Plane.Type>) {
    this.allowedPlaneTypes = allowedPlaneTypes
  }

  private var isTranslating = false

  override fun beginTransform(): Boolean =
    selectedNode?.takeIf {
      !isTranslating && it.positionEditable
    }?.let { node ->
      isTranslating = true
      node.detachAnchor()
      val initialForwardInWorld: Vector3 = node.localToWorldPosition(getForward())
      initialForwardInLocal.set(initialForwardInWorld)
    } != null

  override fun continueTransform(x: Float, y: Float): Boolean {
    val frame: ArFrame = this.sceneView.currentFrame ?: return false
    val arCamera: Camera = frame.camera

    return selectedNode?.takeIf {
      isTranslating && it.positionEditable && arCamera.trackingState == TrackingState.TRACKING
    }?.let {
      val hitResultList: List<HitResult> = frame.hitTests(x, y)
      for (i in hitResultList.indices) {
        val hit: HitResult = hitResultList[i]
        val trackable: Trackable = hit.trackable
        val pose = hit.hitPose
        if (trackable is Plane) {
          if (trackable.isPoseInPolygon(pose) && allowedPlaneTypes.contains(trackable.type)) {
            desiredLocalPosition = Vector3(pose.tx(), pose.ty(), pose.tz())
            val desiredLocalRotation = Quaternion(pose.qx(), pose.qy(), pose.qz(), pose.qw())
            this.desiredLocalRotation = calculateFinalDesiredLocalRotation(desiredLocalRotation)
            lastArHitResult = hit
            break
          }
        }
      }
    } != null
  }

  override fun endTransform(): Boolean {
    val hitResult = lastArHitResult ?: return false
    return selectedNode?.takeIf {
      isTranslating && it.positionEditable && hitResult.trackable.trackingState == TrackingState.TRACKING
    }?.let { node ->
      node.anchor?.detach()
      val newAnchor = hitResult.createAnchor()

      // Since we change the anchor, we need to update the initialForwardInLocal into the new
      // coordinate space. Local variable for nullness analysis.
      val desiredLocalRotation = desiredLocalRotation
      if (desiredLocalRotation != null) {
        node.rotation = desiredLocalRotation.toRotation()
      }
      node.anchor = newAnchor

      isTranslating = false
    } != null
  }

  /**
   * When translating, the up direction of the node must match the up direction of the plane from
   * the hit result. However, we also need to make sure that the original forward direction of the
   * node is respected.
   */
  private fun calculateFinalDesiredLocalRotation(desiredLocalRotationP: Quaternion): Quaternion {
    // Get a rotation just to the up direction.
    // Otherwise, the node will spin around as you rotate.
    var desiredLocalRotation = desiredLocalRotationP.toOldQuaternion()
    val rotatedUp: Vector3 = com.google.ar.sceneform.math.Quaternion.rotateVector(desiredLocalRotation, Vector3.up())
    desiredLocalRotation = com.google.ar.sceneform.math.Quaternion.rotationBetweenVectors(Vector3.up(), rotatedUp)

    // Adjust the rotation to make sure the node maintains the same forward direction.
    val forwardInLocal =
      com.google.ar.sceneform.math.Quaternion.rotationBetweenVectors(Vector3.forward(), initialForwardInLocal)
    desiredLocalRotation = com.google.ar.sceneform.math.Quaternion.multiply(desiredLocalRotation, forwardInLocal)
    return desiredLocalRotation.normalized().toNewQuaternion()
  }

  private fun updatePosition(frameTime: FrameTime) {
    // Store in local variable for nullness static analysis.
    val desiredLocalPosition = desiredLocalPosition ?: return
    var localPosition: Vector3? = selectedNode?.position?.toVector3()
    val lerpFactor = MathHelper.clamp((frameTime.intervalSeconds * LERP_SPEED).toFloat(), 0f, 1f)
    localPosition = Vector3.lerp(localPosition, desiredLocalPosition, lerpFactor)
    val lengthDiff = abs(Vector3.subtract(desiredLocalPosition, localPosition).length())
    if (lengthDiff <= POSITION_LENGTH_THRESHOLD) {
      localPosition = desiredLocalPosition
      this.desiredLocalPosition = null
    }
    if (localPosition != null) {
      selectedNode?.position = Position(localPosition.toFloat3())
    }
  }

  private fun getForward(): Vector3 {
    val forward = Vector3()
    forward.set(0f,0f,-1f)
    return forward
  }

  private fun updateRotation(frameTime: FrameTime) {
    // Store in local variable for nullness static analysis.
    val desiredLocalRotation = desiredLocalRotation ?: return
    if (selectedNode != null) {
      var localRotation: Quaternion = selectedNode!!.rotation.toQuaternion()
      val lerpFactor = MathHelper.clamp((frameTime.intervalSeconds * LERP_SPEED).toFloat(), 0f, 1f)
      localRotation = slerp(localRotation, desiredLocalRotation, lerpFactor)
      val dot: Float = abs(dot(localRotation, desiredLocalRotation))
      if (dot >= ROTATION_DOT_THRESHOLD) {
        localRotation = desiredLocalRotation
        this.desiredLocalRotation = null
      }
      selectedNode?.rotation = localRotation.toRotation()
    }
  }

}

internal val ArNode.positionEditable: Boolean
  get() = editableTransforms.contains(EditableTransform.POSITION)
