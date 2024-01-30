//
//  CustomModule.swift
//  MyNativeModule
//
//  Created by Kumar Aman on 30/01/24.
//

import Foundation
import React

@objc(CustomModule)
class CustomModule: NSObject {

  // Example method that you will expose to React Native
  @objc
  func exampleMethod(_ name: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    // Your native module code goes here
    print("Hello, \(name)!")
    resolve("Native module says hi!")
  }
  // React Native will use this to determine whether to run on the main thread
  @objc static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

// Exposing the method to React Native
@objc
extension CustomModule {
  @objc(exampleMethod)
  static func exampleMethod() {
    // Forward the call to the instance method
    CustomModule.exampleMethod()
  }
}
