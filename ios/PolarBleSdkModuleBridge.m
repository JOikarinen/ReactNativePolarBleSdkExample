//
//  PolarBleSdkModuleBridge.m
//  ReactNativePolarBleSDK

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PolarBleSdkModule, NSObject)

RCT_EXTERN_METHOD(searchForDevice)
RCT_EXTERN_METHOD(connectToDevice: (NSString *)deviceId)
RCT_EXTERN_METHOD(startEcgStream: (NSString *)deviceId)
@end
