package com.documentuploader

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = DocumentUploaderModule.NAME)
class DocumentUploaderModule(reactContext: ReactApplicationContext) :
  NativeDocumentUploaderSpec(reactContext), ActivityEventListener {

  companion object {
    const val NAME = "DocumentUploader"
    private const val REQUEST_CODE = 4721
  }

  private var pickerPromise: Promise? = null

  init {
    reactContext.addActivityEventListener(this)
  }

  override fun getName(): String {
    return NAME
  }

  override fun pick(promise: Promise) {
    val activity = currentActivity
    if (activity == null) {
      promise.reject("NO_ACTIVITY", "No current activity")
      return
    }

    pickerPromise = promise

    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
      type = "*/*"
      addCategory(Intent.CATEGORY_OPENABLE)
    }

    activity.startActivityForResult(Intent.createChooser(intent, "Select File"), REQUEST_CODE)
  }

  override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
    if (requestCode != REQUEST_CODE || pickerPromise == null) return

    if (resultCode != Activity.RESULT_OK || data?.data == null) {
      pickerPromise?.resolve(null)
      pickerPromise = null
      return
    }

    val uri: Uri = data.data!!
    val contentResolver = reactApplicationContext.contentResolver

    var name = "unknown"
    var size = 0L

    val cursor: Cursor? = contentResolver.query(uri, null, null, null, null)
    cursor?.use {
      val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
      val sizeIndex = it.getColumnIndex(OpenableColumns.SIZE)
      if (it.moveToFirst()) {
        name = it.getString(nameIndex)
        size = it.getLong(sizeIndex)
      }
    }

    val mimeType = contentResolver.getType(uri) ?: "application/octet-stream"

    val result = Arguments.createMap().apply {
      putString("uri", uri.toString())
      putString("name", name)
      putString("type", mimeType)
      putDouble("size", size.toDouble())
    }

    pickerPromise?.resolve(result)
    pickerPromise = null
  }

  override fun onNewIntent(intent: Intent?) {
    // not used
  }
}
