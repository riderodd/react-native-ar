package com.reactnativearviewer

import android.util.Log
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.google.ar.core.Config
import io.github.sceneview.ar.arcore.LightEstimationMode
import io.github.sceneview.ar.node.EditableTransform

class ArViewerViewManager : SimpleViewManager<ArViewerView>() {
  override fun getName() = "ArViewerView"

  override fun createViewInstance(reactContext: ThemedReactContext): ArViewerView {
    return ArViewerView(reactContext);
  }

  @ReactProp(name = "model")
  fun setModel(view: ArViewerView, model: String) {
    Log.d("ARview model", model);
    view.loadModel(model);
  }

  @ReactProp(name = "planeOrientation")
  fun setPlaneOrientation(view: ArViewerView, planeOrientation: String) {
    Log.d("ARview planeOrientation", planeOrientation);
    when(planeOrientation) {
      "horizontal" -> view.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
      "vertical" -> view.planeFindingMode = Config.PlaneFindingMode.VERTICAL
      "both" -> view.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL_AND_VERTICAL
      "none" -> view.planeFindingMode = Config.PlaneFindingMode.DISABLED
    }
  }

  @ReactProp(name = "lightEstimation")
  fun setPlaneOrientation(view: ArViewerView, lightEstimation: Boolean) {
    Log.d("ARview lightEstimation", lightEstimation.toString());
    if(lightEstimation) {
      view.lightEstimationMode = LightEstimationMode.AMBIENT_INTENSITY;
    } else {
      view.lightEstimationMode = LightEstimationMode.DISABLED
    }
  }

  @ReactProp(name = "manageDepth")
  fun setManageDepth(view: ArViewerView, manageDepth: Boolean) {
    Log.d("ARview manageDepth", manageDepth.toString());
    view.depthEnabled = manageDepth
  }

  @ReactProp(name = "allowScale")
  fun setAllowScale(view: ArViewerView, allowScale: Boolean) {
    Log.d("ARview allowScale", allowScale.toString());
    if(allowScale) {
      view.addAllowTransform(EditableTransform.SCALE)
    } else {
      view.removeAllowTransform(EditableTransform.SCALE)
    }
  }

  @ReactProp(name = "allowTranslate")
  fun setAllowTranslate(view: ArViewerView, allowTranslate: Boolean) {
    Log.d("ARview allowTranslate", allowTranslate.toString());
    if(allowTranslate) {
      view.addAllowTransform(EditableTransform.POSITION)
    } else {
      view.removeAllowTransform(EditableTransform.POSITION)
    }
  }

  @ReactProp(name = "allowRotate")
  fun setAllowRotate(view: ArViewerView, allowRotate: Boolean) {
    Log.d("ARview allowRotate", allowRotate.toString());
    if(allowRotate) {
      view.addAllowTransform(EditableTransform.ROTATION)
    } else {
      view.removeAllowTransform(EditableTransform.ROTATION)
    }
  }
}
