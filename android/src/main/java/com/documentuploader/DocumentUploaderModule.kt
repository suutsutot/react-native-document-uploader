package com.documentuploader

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule
import java.io.File
import java.io.FileOutputStream

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
    val mimeType = contentResolver.getType(uri) ?: "application/octet-stream"

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

    var finalUri = uri
    var finalName = name
    var finalMime = mimeType
    var finalSize = size

    if (mimeType == "image/heic" || mimeType == "image/heif" || name.endsWith(".heic", true)) {
      try {
        val inputStream = contentResolver.openInputStream(uri)
        val bitmap = BitmapFactory.decodeStream(inputStream)
        inputStream?.close()

        if (bitmap != null) {
          val jpgFile = File(reactApplicationContext.cacheDir, "${System.currentTimeMillis()}.jpg")
          val outputStream = FileOutputStream(jpgFile)
          bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
          outputStream.flush()
          outputStream.close()

          finalUri = Uri.fromFile(jpgFile)
          finalName = jpgFile.name
          finalMime = "image/jpeg"
          finalSize = jpgFile.length()
        } else {
          pickerPromise?.reject("CONVERT_ERROR", "Failed to decode HEIC image")
          pickerPromise = null
          return
        }
      } catch (e: Exception) {
        pickerPromise?.reject("CONVERT_EXCEPTION", "HEIC to JPG conversion failed", e)
        pickerPromise = null
        return
      }
    }

    val result = Arguments.createMap().apply {
      putString("uri", finalUri.toString())
      putString("name", finalName)
      putString("type", finalMime)
      putDouble("size", finalSize.toDouble())
    }

    pickerPromise?.resolve(result)
    pickerPromise = null
  }

  override fun onNewIntent(intent: Intent?) {
    // Not needed
  }
}
