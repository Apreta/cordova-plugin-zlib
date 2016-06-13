#import <Cordova/CDV.h>

@interface PZlib : CDVPlugin

- (void) inflate:(CDVInvokedUrlCommand*)command;
- (void) deflate:(CDVInvokedUrlCommand*)command;
- (void) reset:(CDVInvokedUrlCommand*)command;

@end
