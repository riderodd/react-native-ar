package com.reactnativearviewer

import android.util.Log
import androidx.annotation.Nullable
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

class ArViewerViewManager : SimpleViewManager<ArViewerView>() {
  /**
   * Assign an identifier to each command supported
   */
  companion object {
    const val COMMAND_SNAPSHOT = 1
    const val COMMAND_RESET = 2
    const val COMMAND_ROTATE_MODEL = 3
  }

  /**
   * Name the view
   */
  override fun getName() = "ArViewerView"

  /**
   * Create the view
   */
  override fun createViewInstance(reactContext: ThemedReactContext): ArViewerView {
    Log.d("ARview createViewInstance", "Create view")
    return ArViewerView(reactContext)
  }

  /**
   * Pause the AR session when the view gets removed
   */
  override fun onDropViewInstance(view: ArViewerView) {
    Log.d("ARview onDropViewInstance", "Stopping session")
    super.onDropViewInstance(view)
    view.onDrop()
  }

  /**
   * Map the commands to an integer
   */
  override fun getCommandsMap(): Map<String, Int>? {
    return MapBuilder.of(
      "takeScreenshot", COMMAND_SNAPSHOT,
      "reset", COMMAND_RESET,
      "rotateModel", COMMAND_ROTATE_MODEL
    )
  }

  /**
   * Map methods calls to view methods
   */
  override fun receiveCommand(view: ArViewerView, commandId: Int, @Nullable args: ReadableArray?) {
    super.receiveCommand(view, commandId, args)
    Log.d("ARview receiveCommand", commandId.toString())
    when (commandId) {
      COMMAND_SNAPSHOT -> {
        if (args != null) {
          val requestId = args.getInt(0)
          view.takeScreenshot(requestId)
        }
      }
      COMMAND_RESET -> {
        view.resetModel()
      }
      COMMAND_ROTATE_MODEL -> {
        if (args != null) {
          val pitch = args.getInt(0)
          val yaw = args.getInt(1)
          val roll = args.getInt(2)
          view.rotateModel(pitch, yaw, roll)
        }
      }
    }
  }

  /**
   * Register the view events
   */
  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
    return MapBuilder.of(
      "onDataReturned", MapBuilder.of("registrationName","onDataReturned"),
      "onError", MapBuilder.of("registrationName","onError"),
      "onStarted", MapBuilder.of("registrationName","onStarted"),
      "onEnded", MapBuilder.of("registrationName","onEnded"),
      "onModelPlaced", MapBuilder.of("registrationName","onModelPlaced"),
      "onModelRemoved", MapBuilder.of("registrationName","onModelRemoved")
    )
  }

  /**
   * Required prop: the model src (URI)
   */
  @ReactProp(name = "model")
  fun setModel(view: ArViewerView, model: String) {
    Log.d("ARview model", model)
    view.loadModel(model)
  }

  /**
   * Optional: the plane orientation detection (can be: horizontal, vertical, both, none)
   */
  @ReactProp(name = "planeOrientation")
  fun setPlaneOrientation(view: ArViewerView, planeOrientation: String) {
    Log.d("ARview planeOrientation", planeOrientation)
    view.setPlaneDetection(planeOrientation)
  }

  /**
   * Optional: enable ARCode light estimation
   */
  @ReactProp(name = "lightEstimation")
  fun setLightEstimation(view: ArViewerView, lightEstimation: Boolean) {
    Log.d("ARview lightEstimation", lightEstimation.toString())
    view.setLightEstimationEnabled(lightEstimation)
  }


  /**
   * Optional: enable SceneView depth management
   */
  @ReactProp(name = "manageDepth")
  fun setManageDepth(view: ArViewerView, manageDepth: Boolean) {
    Log.d("ARview manageDepth", manageDepth.toString())
    view.setDepthManagementEnabled(manageDepth)
  }


  /**
   * Optional: allow user to pinch the model to zoom it
   */
  @ReactProp(name = "allowScale")
  fun setAllowScale(view: ArViewerView, allowScale: Boolean) {
    Log.d("ARview allowScale", allowScale.toString())
    if (allowScale) {
      view.addAllowTransform("scale")
    } else {
      view.removeAllowTransform("scale")
    }
  }

  /**
   * Optional: allow user to translate the model
   */
  @ReactProp(name = "allowTranslate")
  fun setAllowTranslate(view: ArViewerView, allowTranslate: Boolean) {
    Log.d("ARview allowTranslate", allowTranslate.toString())
    if(allowTranslate) {
      view.addAllowTransform("translate")
    } else {
      view.removeAllowTransform("translate")
    }
  }

  /**
   * Optional: allow the user to rotate the model
   */
  @ReactProp(name = "allowRotate")
  fun setAllowRotate(view: ArViewerView, allowRotate: Boolean) {
    Log.d("ARview allowRotate", allowRotate.toString())
    if(allowRotate) {
      view.addAllowTransform("rotate")
    } else {
      view.removeAllowTransform("rotate")
    }
  }

  /**
   * Optional: disable the text instructions
   */
  @ReactProp(name = "disableInstructions")
  fun disableInstructions(view: ArViewerView, isDisabled: Boolean) {
    Log.d("ARview setInstructions", isDisabled.toString())
    view.setInstructionsEnabled(!isDisabled)
  }

  /**
   * Optional: disable instant placement
   */
  @ReactProp(name = "disableInstantPlacement")
  fun disableInstantPlacement(view: ArViewerView, isDisabled: Boolean) {
    Log.d("ARview disableInstantPlacement", isDisabled.toString())
    view.setInstantPlacementEnabled(!isDisabled)
  }
}
