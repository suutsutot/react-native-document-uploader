package com.documentuploader

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class DocumentUploaderPackage : BaseReactPackage() {

  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return if (name == DocumentUploaderModule.NAME) {
      DocumentUploaderModule(reactContext)
    } else {
      null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      mapOf(
        DocumentUploaderModule.NAME to ReactModuleInfo(
          /* name */ DocumentUploaderModule.NAME,
          /* className */ DocumentUploaderModule::class.java.name,
          /* canOverrideExistingModule */ false,
          /* needsEagerInit */ false,
          /* hasConstants */ false,
          /* isCxxModule */ false,
          /* isTurboModule */ true
        )
      )
    }
  }
}
