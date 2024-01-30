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

@end
