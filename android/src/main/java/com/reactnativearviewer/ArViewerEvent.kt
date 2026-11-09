package com.reactnativearviewer

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class ArViewerEvent(
  surfaceId: Int,
  viewId: Int,
  private val name: String,
  private val payload: WritableMap
) : Event<ArViewerEvent>(surfaceId, viewId) {
  override fun getEventName() = name

  override fun getEventData() = payload

  companion object {
    const val DATA_RETURNED = "onDataReturned"
    const val ERROR = "onError"
    const val STARTED = "onStarted"
    const val ENDED = "onEnded"
    const val MODEL_PLACED = "onModelPlaced"
    const val MODEL_REMOVED = "onModelRemoved"

    val NAMES = listOf(DATA_RETURNED, ERROR, STARTED, ENDED, MODEL_PLACED, MODEL_REMOVED)
  }
}
