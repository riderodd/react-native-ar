package com.reactnativearviewer

import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView

/** Shows the hand motion hint while it is both enabled and requested. */
class InstructionsController(private val container: FrameLayout) {
  private var view: HandMotionView? = null

  var isEnabled = true
    set(value) {
      field = value
      updateVisibility()
    }

  var isVisible = false
    set(value) {
      if (field != value) {
        field = value
        updateVisibility()
      }
    }

  private fun updateVisibility() {
    val shouldShow = isEnabled && isVisible
    if (shouldShow && view == null) {
      view = HandMotionView(container.context).apply {
        layoutParams = FrameLayout.LayoutParams(
          ViewGroup.LayoutParams.MATCH_PARENT,
          ViewGroup.LayoutParams.MATCH_PARENT,
          Gravity.CENTER
        )
        scaleType = ImageView.ScaleType.CENTER
      }
      container.addView(view)
    }
    view?.visibility = if (shouldShow) View.VISIBLE else View.GONE
  }
}
