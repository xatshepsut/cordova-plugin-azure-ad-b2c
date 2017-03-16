//
//  NXOAuth2Connection+Extension.m
//
//  Created by Aidela Karamyan on 3/3/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "NXOAuth2Connection+Extension.h"
#import <objc/runtime.h>

@implementation NXOAuth2Connection (Extension)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];
    
    SEL originalSelector = @selector(initWithRequest:requestParameters:oauthClient:delegate:);
    SEL swizzledSelector = @selector(xxx_initWithRequest:requestParameters:oauthClient:delegate:);
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
      class_replaceMethod(class,
                          swizzledSelector,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

#pragma mark - Method Swizzling

- (id)xxx_initWithRequest:(NSMutableURLRequest *)aRequest
    requestParameters:(NSDictionary *)someRequestParameters
          oauthClient:(NXOAuth2Client *)aClient
             delegate:(NSObject<NXOAuth2ConnectionDelegate> *)aDelegate {
  // TODO: check if there is need to remove client_secret
  NSMutableDictionary *updatedRequestParameters = [someRequestParameters mutableCopy];
  [updatedRequestParameters removeObjectForKey:@"client_secret"];
  
  return [self xxx_initWithRequest:aRequest requestParameters:updatedRequestParameters oauthClient:aClient delegate:aDelegate];
}

@end
