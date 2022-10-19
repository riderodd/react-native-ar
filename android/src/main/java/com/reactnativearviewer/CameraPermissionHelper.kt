package com.reactnativearviewer

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/*
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/** Helper to ask camera permission.  */
object CameraPermissionHelper {
  private const val CAMERA_PERMISSION_CODE = 0
  private const val CAMERA_PERMISSION = Manifest.permission.CAMERA

  /** Check to see we have the necessary permissions for this app.  */
  fun hasCameraPermission(activity: Activity?): Boolean {
    return (ContextCompat.checkSelfPermission(activity!!, CAMERA_PERMISSION)
      == PackageManager.PERMISSION_GRANTED)
  }

  /** Check to see we have the necessary permissions for this app, and ask for them if we don't.  */
  fun requestCameraPermission(activity: Activity?) {
    ActivityCompat.requestPermissions(
      activity!!,
      arrayOf(CAMERA_PERMISSION),
      CAMERA_PERMISSION_CODE
    )
  }
}
