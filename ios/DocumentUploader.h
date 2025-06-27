#import <React/RCTBridgeModule.h>

@interface DocumentPicker : NSObject <RCTBridgeModule>

- (void)pick:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject;

@end