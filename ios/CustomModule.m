//
//  CustomModule.m
//  MyNativeModule
//
//  Created by Kumar Aman on 30/01/24.
//

#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(CustomModule, NSObject)

//RCT_EXTERN_METHOD(exampleMethod)
RCT_EXTERN_METHOD(exampleMethod:(NSString *)param resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
// This macro exposes the createNotification method to JavaScript
RCT_EXTERN_METHOD(createNotificationWithTitle:(NSString *)title message:(NSString *)message)
@end
