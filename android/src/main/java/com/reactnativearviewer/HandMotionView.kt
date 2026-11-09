package com.reactnativearviewer

import android.animation.ValueAnimator
import android.content.Context
import android.view.animation.LinearInterpolator
import androidx.appcompat.widget.AppCompatImageView
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/** Animated phone illustration inviting the user to move the device to detect planes. */
class HandMotionView(context: Context) : AppCompatImageView(context) {
  private val radius = 25f * resources.displayMetrics.density

  private val animator = ValueAnimator.ofFloat(0f, (2 * PI).toFloat()).apply {
    duration = ANIMATION_DURATION_MS
    repeatCount = ValueAnimator.INFINITE
    interpolator = LinearInterpolator()
    addUpdateListener {
      val angle = it.animatedValue as Float
      translationX = radius * cos(angle)
      translationY = radius * sin(angle)
    }
  }

  init {
    setImageResource(R.drawable.sceneform_hand_phone)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    updateAnimation()
  }

  override fun onDetachedFromWindow() {
    animator.cancel()
    super.onDetachedFromWindow()
  }

  override fun setVisibility(visibility: Int) {
    super.setVisibility(visibility)
    updateAnimation()
  }

  private fun updateAnimation() {
    if (visibility == VISIBLE && isAttachedToWindow) {
      if (!animator.isStarted) animator.start()
    } else {
      animator.cancel()
    }
  }

  companion object {
    private const val ANIMATION_DURATION_MS = 2500L
  }
}
