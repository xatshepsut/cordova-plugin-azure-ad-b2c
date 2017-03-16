//
//  NXOAuth2AccountStore+Extension.m
//
//  Created by Aidela Karamyan on 3/13/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "NXOAuth2AccountStore+Extension.h"
#import "NXOAuth2Client.h"
#import <objc/runtime.h>

static void *NXOAuth2AccountStoreExtendedKey;

@implementation NXOAuth2AccountStore (Extension)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];
    
    SEL originalSelector = @selector(oauthClientDidGetAccessToken:);
    SEL swizzledSelector = @selector(xxx_oauthClientDidGetAccessToken:);
    
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

#pragma mark - Delegate

- (id <NXOAuth2AccountStoreDelegate>)delegate {
  id result = objc_getAssociatedObject(self, &NXOAuth2AccountStoreExtendedKey);
  return result;
}

- (void)setDelegate:(id <NXOAuth2AccountStoreDelegate>)object {
  objc_setAssociatedObject(self, &NXOAuth2AccountStoreExtendedKey, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Method Swizzling

- (void)xxx_oauthClientDidGetAccessToken:(NXOAuth2Client *)client {
  if ([client accessToken] && [[self delegate] respondsToSelector:@selector(didGetAccessToken:)]) {
    [[self delegate] didGetAccessToken:[client accessToken]];
  }
  
  [self xxx_oauthClientDidGetAccessToken:client];
}

@end
