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
  
  @objc(createNotificationWithTitle:message:)
  func createNotification(title: String, message: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
  }
  
  // React Native will use this to determine whether to run on the main thread
  @objc static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
