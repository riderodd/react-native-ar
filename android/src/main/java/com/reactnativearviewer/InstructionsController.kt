package com.reactnativearviewer

import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.RelativeLayout
import com.facebook.react.uimanager.ThemedReactContext

class InstructionsController constructor(
  context: ThemedReactContext, container: FrameLayout
) {
  private var context: ThemedReactContext? = null
  private var container: FrameLayout? = null
  private var view: HandMotionView? = null

  private var isVisible = true
  private var isEnabled = true

  init {
    this.context = context
    this.container = container
    updateVisibility()
  }

  private fun onCreateView(): HandMotionView? {
    view = HandMotionView(context, container)

    // Create layout parameters for HandMotionView
    val lp = RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT)

    // Add layout parameters to HandMotionView
    view!!.layoutParams = lp
    view!!.foregroundGravity = Gravity.CENTER
    view!!.scaleType = ImageView.ScaleType.CENTER

    // Add the HandMotionView to main container
    container!!.addView(view)
    return view
  }

  /**
   * Check if the instruction view is enabled.
   *
   * @return false = never show the instructions view
   */
  private fun isEnabled(): Boolean {
    return isEnabled
  }

  /**
   * Enable/disable the instruction view for all types.
   *
   * @param enabled false = never show the instructions view
   */
  fun setEnabled(enabled: Boolean) {
    if (isEnabled != enabled) {
      isEnabled = enabled
      updateVisibility()
    }
  }

  /**
   * Get the instructions view visibility for all types.
   * You should not use this function for global visibility purposes since it's called internally
   * but call [.isEnabled] instead.
   *
   * @return the visibility
   */
  fun isVisible(): Boolean {
    return isVisible
  }

  /**
   * Set the instructions view visibility for all types.
   * You should not use this function for global visibility purposes since it's called internally
   * but call [.setEnabled] instead
   *
   * @param visible the visibility
   */
  fun setVisible(visible: Boolean) {
    if (isVisible != visible) {
      isVisible = visible
      updateVisibility()
    }
  }

  private fun updateVisibility() {
      val isVisible = (isEnabled() && isVisible())
      if (isVisible && view == null) {
        view = onCreateView()
      }
      if (view != null) {
        view!!.visibility = if (isVisible) View.VISIBLE else View.GONE
      }
    }
}
