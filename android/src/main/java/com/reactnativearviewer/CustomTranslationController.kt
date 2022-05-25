package com.reactnativearviewer

import com.google.android.filament.utils.Float3
import com.google.ar.core.*
import com.google.ar.sceneform.*
import com.google.ar.sceneform.math.MathHelper
import com.google.ar.sceneform.math.Quaternion
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.utilities.Preconditions
import com.google.ar.sceneform.ux.BaseTransformableNode
import com.google.ar.sceneform.ux.DragGesture
import com.google.ar.sceneform.ux.DragGestureRecognizer
import com.google.ar.sceneform.ux.TranslationController
import java.util.*
import kotlin.math.abs

class CustomTranslationController(transformableNode: BaseTransformableNode?,
                                  gestureRecognizer: DragGestureRecognizer?
) : TranslationController(
  transformableNode, gestureRecognizer
) {

  private var lastArHitResult: HitResult? = null
  private var desiredLocalPosition: Vector3? = null
  private var desiredLocalRotation: Quaternion? = null

  private val initialForwardInLocal = Vector3()

  private var allowedPlaneTypes = EnumSet.allOf(
    Plane.Type::class.java
  )

  private val LERP_SPEED = 12.0f
  private val POSITION_LENGTH_THRESHOLD = 0.01f
  private val ROTATION_DOT_THRESHOLD = 0.99f
  private var fCenter: Float3? = null


  /** Sets which types of ArCore Planes this TranslationController is allowed to translate on.  */
  override fun setAllowedPlaneTypes(allowedPlaneTypes: EnumSet<Plane.Type>) {
    this.allowedPlaneTypes = allowedPlaneTypes
  }

  /**
   * Gets a reference to the EnumSet that determines which types of ArCore Planes this
   * TranslationController is allowed to translate on.
   */
  override fun getAllowedPlaneTypes(): EnumSet<Plane.Type>? {
    return allowedPlaneTypes
  }

  override fun onUpdated(node: Node?, frameTime: FrameTime) {
    updatePosition(frameTime)
    updateRotation(frameTime)
  }

  override fun isTransforming(): Boolean {
    // As long as the transformable node is still interpolating towards the final pose, this
    // controller is still transforming.
    return super.isTransforming() || desiredLocalRotation != null || desiredLocalPosition != null
  }

  override fun canStartTransformation(gesture: DragGesture): Boolean {
    val targetNode = gesture.targetNode ?: return false
    val transformableNode = transformableNode
    if (targetNode !== transformableNode && !targetNode.isDescendantOf(transformableNode)) {
      return false
    }
    if (!transformableNode.isSelected && !transformableNode.select()) {
      return false
    }
    val initialForwardInWorld = transformableNode.forward
    val parent = transformableNode.parentNode
    if (parent != null) {
      initialForwardInLocal.set(parent.worldToLocalDirection(initialForwardInWorld))
    } else {
      initialForwardInLocal.set(initialForwardInWorld)
    }

    transformableNode.renderableInstance.filamentAsset.let { asset ->
      val center = asset!!.boundingBox.center.let { v -> Float3(v[0], v[1], v[2]) }
      val halfExtent = asset.boundingBox.halfExtent.let { v -> Float3(v[0], v[1], v[2]) }
      fCenter = -(center + halfExtent * Float3(0f, -1f, 1f)) * Float3(1f, 1f, 1f)
    }

    return true
  }

  override fun onContinueTransformation(gesture: DragGesture) {
    val scene = transformableNode.scene ?: return
    val frame = (scene.view as ArSceneView).arFrame ?: return
    val arCamera = frame.camera
    if (arCamera.trackingState != TrackingState.TRACKING) {
      return
    }
    val position = gesture.position
    val hitResultList = frame.hitTest(position.x, position.y)
    for (i in hitResultList.indices) {
      val hit = hitResultList[i]
      val trackable = hit.trackable
      val pose = hit.hitPose
      if (trackable is Plane) {
        if (trackable.isPoseInPolygon(pose) && allowedPlaneTypes.contains(trackable.type)) {

          desiredLocalPosition = Vector3(pose.tx(), pose.ty() + fCenter!!.y, pose.tz())

          desiredLocalRotation = Quaternion(pose.qx(), pose.qy(), pose.qz(), pose.qw())
          val parent = transformableNode.parentNode
          if (parent != null && desiredLocalPosition != null && desiredLocalRotation != null) {
            desiredLocalPosition = parent.worldToLocalPoint(desiredLocalPosition)
            desiredLocalRotation = Quaternion.multiply(
              parent.worldRotation.inverted(),
              Preconditions.checkNotNull(desiredLocalRotation)
            )
          }
          desiredLocalRotation =
            calculateFinalDesiredLocalRotation(Preconditions.checkNotNull(desiredLocalRotation))
          lastArHitResult = hit
          break
        }
      }
    }
  }

  override fun onEndTransformation(gesture: DragGesture?) {
    val hitResult = lastArHitResult ?: return
    if (hitResult.trackable.trackingState == TrackingState.TRACKING) {
      val anchorNode = getAnchorNodeOrDie()
      val oldAnchor = anchorNode.anchor
      oldAnchor?.detach()
      val newAnchor = hitResult.createAnchor()
      val worldPosition = transformableNode.worldPosition
      val worldRotation = transformableNode.worldRotation
      var finalDesiredWorldRotation = worldRotation

      // Since we change the anchor, we need to update the initialForwardInLocal into the new
      // coordinate space. Local variable for nullness analysis.
      val desiredLocalRotation = this.desiredLocalRotation
      if (desiredLocalRotation != null) {
        transformableNode.localRotation = desiredLocalRotation
        finalDesiredWorldRotation = transformableNode.worldRotation
      }
      anchorNode.anchor = newAnchor

      // Temporarily set the node to the final world rotation so that we can accurately
      // determine the initialForwardInLocal in the new coordinate space.
      transformableNode.worldRotation = finalDesiredWorldRotation
      val initialForwardInWorld = transformableNode.forward
      initialForwardInLocal.set(anchorNode.worldToLocalDirection(initialForwardInWorld))
      transformableNode.worldRotation = worldRotation
      transformableNode.worldPosition = worldPosition
    }
    desiredLocalPosition = Vector3(0f, fCenter!!.y, 0f)
    desiredLocalRotation = calculateFinalDesiredLocalRotation(Quaternion.identity())
  }

  private fun getAnchorNodeOrDie(): AnchorNode {
    val parent = transformableNode.parent
    check(parent is AnchorNode) { "TransformableNode must have an AnchorNode as a parent." }
    return parent
  }

  private fun updatePosition(frameTime: FrameTime) {
    // Store in local variable for nullness static analysis.
    val desiredLocalPosition = this.desiredLocalPosition ?: return
    var localPosition = transformableNode.localPosition
    val lerpFactor = MathHelper.clamp(frameTime.deltaSeconds * LERP_SPEED, 0f, 1f)
    localPosition = Vector3.lerp(localPosition, desiredLocalPosition, lerpFactor)
    val lengthDiff = abs(Vector3.subtract(desiredLocalPosition, localPosition).length())
    if (lengthDiff <= POSITION_LENGTH_THRESHOLD) {
      localPosition = desiredLocalPosition
      this.desiredLocalPosition = null
    }
    transformableNode.localPosition = localPosition
  }

  private fun updateRotation(frameTime: FrameTime) {
    // Store in local variable for nullness static analysis.
    val desiredLocalRotation = this.desiredLocalRotation ?: return
    var localRotation = transformableNode.localRotation
    val lerpFactor = MathHelper.clamp(frameTime.deltaSeconds * LERP_SPEED, 0f, 1f)
    localRotation = Quaternion.slerp(localRotation, desiredLocalRotation, lerpFactor)
    val dot = abs(dotQuaternion(localRotation, desiredLocalRotation))
    if (dot >= ROTATION_DOT_THRESHOLD) {
      localRotation = desiredLocalRotation
      this.desiredLocalRotation = null
    }
    transformableNode.localRotation = localRotation
  }

  /**
   * When translating, the up direction of the node must match the up direction of the plane from
   * the hit result. However, we also need to make sure that the original forward direction of the
   * node is respected.
   */
  private fun calculateFinalDesiredLocalRotation(desiredLocalRotation: Quaternion): Quaternion? {
    // Get a rotation just to the up direction.
    // Otherwise, the node will spin around as you rotate.
    var desiredLocalRotation = desiredLocalRotation
    val rotatedUp = Quaternion.rotateVector(desiredLocalRotation, Vector3.up())
    desiredLocalRotation = Quaternion.rotationBetweenVectors(Vector3.up(), rotatedUp)

    // Adjust the rotation to make sure the node maintains the same forward direction.
    val forwardInLocal = Quaternion.rotationBetweenVectors(Vector3.forward(), initialForwardInLocal)
    desiredLocalRotation = Quaternion.multiply(desiredLocalRotation, forwardInLocal)
    return desiredLocalRotation.normalized()
  }

  private fun dotQuaternion(lhs: Quaternion, rhs: Quaternion): Float {
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w
  }
}
