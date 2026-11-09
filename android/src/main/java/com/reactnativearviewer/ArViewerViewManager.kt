package com.reactnativearviewer

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ArViewerViewManagerDelegate
import com.facebook.react.viewmanagers.ArViewerViewManagerInterface

@ReactModule(name = ArViewerViewManager.NAME)
class ArViewerViewManager : SimpleViewManager<ArViewerView>(),
  ArViewerViewManagerInterface<ArViewerView> {
  private val delegate = ArViewerViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<ArViewerView> = delegate

  override fun getName() = NAME

  override fun createViewInstance(context: ThemedReactContext) = ArViewerView(context)

  override fun onDropViewInstance(view: ArViewerView) {
    super.onDropViewInstance(view)
    view.destroy()
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    ArViewerEvent.NAMES.associateWith { mapOf("registrationName" to it) }

  @ReactProp(name = "model")
  override fun setModel(view: ArViewerView, value: String?) {
    view.setModel(value.orEmpty())
  }

  @ReactProp(name = "planeOrientation")
  override fun setPlaneOrientation(view: ArViewerView, value: String?) {
    view.setPlaneOrientation(value ?: "both")
  }

  @ReactProp(name = "allowScale")
  override fun setAllowScale(view: ArViewerView, value: Boolean) {
    view.setAllowScale(value)
  }

  @ReactProp(name = "allowRotate")
  override fun setAllowRotate(view: ArViewerView, value: Boolean) {
    view.setAllowRotate(value)
  }

  @ReactProp(name = "allowTranslate")
  override fun setAllowTranslate(view: ArViewerView, value: Boolean) {
    view.setAllowTranslate(value)
  }

  @ReactProp(name = "lightEstimation")
  override fun setLightEstimation(view: ArViewerView, value: Boolean) {
    view.setLightEstimation(value)
  }

  @ReactProp(name = "manageDepth")
  override fun setManageDepth(view: ArViewerView, value: Boolean) {
    view.setManageDepth(value)
  }

  @ReactProp(name = "disableInstructions")
  override fun setDisableInstructions(view: ArViewerView, value: Boolean) {
    view.setInstructionsEnabled(!value)
  }

  @ReactProp(name = "disableInstantPlacement")
  override fun setDisableInstantPlacement(view: ArViewerView, value: Boolean) {
    view.setInstantPlacementEnabled(!value)
  }

  override fun takeScreenshot(view: ArViewerView, requestId: Int) {
    view.takeScreenshot(requestId)
  }

  override fun reset(view: ArViewerView) {
    view.reset()
  }

  override fun rotateModel(view: ArViewerView, pitch: Double, yaw: Double, roll: Double) {
    view.rotateModel(pitch.toFloat(), yaw.toFloat(), roll.toFloat())
  }

  companion object {
    const val NAME = "ArViewerView"
  }
}
