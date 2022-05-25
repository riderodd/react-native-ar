package com.reactnativearviewer

import com.google.ar.sceneform.ux.*

/**
 * Node that can be selected, translated, rotated, and scaled using gestures from [ ].
 */
class CustomTransformableNode(transformationSystem: TransformationSystem) :
  BaseTransformableNode(transformationSystem) {
  /** Returns the controller that translates this node using a drag gesture.  */
  val translationController: TranslationController

  /** Returns the controller that scales this node using a pinch gesture.  */
  val scaleController: ScaleController

  /** Returns the controller that rotates this node using a twist gesture.  */
  val rotationController: RotationController

  init {
    translationController = CustomTranslationController(this, transformationSystem.dragRecognizer)
    addTransformationController(translationController)
    scaleController = ScaleController(this, transformationSystem.pinchRecognizer)
    addTransformationController(scaleController)
    rotationController = RotationController(this, transformationSystem.twistRecognizer)
    addTransformationController(rotationController)
  }
}
