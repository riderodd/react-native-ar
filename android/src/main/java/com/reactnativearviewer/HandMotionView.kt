package com.reactnativearviewer

import android.content.Context
import android.util.AttributeSet
import android.view.animation.Animation
import android.widget.FrameLayout
import androidx.appcompat.widget.AppCompatImageView
import com.google.ar.sceneform.ux.HandMotionAnimation

class HandMotionView : AppCompatImageView {
  private var animation: HandMotionAnimation? = null
  private var container: FrameLayout? = null

  constructor(context: Context?, container: FrameLayout?) : super(context!!) {
    setupHandMotionAnimation(container)
  }

  constructor(context: Context?, container: FrameLayout?, attrs: AttributeSet?) : super(
    context!!, attrs
  ) {
    setupHandMotionAnimation(container)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    clearAnimation()
    startAnimation(animation)
  }

  override fun setVisibility(visibility: Int) {
    super.setVisibility(visibility)
    updateVisibility()
  }

  private fun updateVisibility() {
    if (visibility == VISIBLE) {
      startAnimation(animation)
    } else {
      clearAnimation()
    }
  }

  private fun setupHandMotionAnimation(container: FrameLayout?) {
    this.container = container

    // Setup image that will be animated
    this.setImageResource(R.drawable.sceneform_hand_phone)

    // Setup animation parameters
    animation = HandMotionAnimation(container, this)
    animation!!.repeatCount = Animation.INFINITE
    animation!!.duration = ANIMATION_SPEED_MS
    animation!!.startOffset = 1000
  }

  companion object {
    private const val ANIMATION_SPEED_MS: Long = 2500
  }
}
