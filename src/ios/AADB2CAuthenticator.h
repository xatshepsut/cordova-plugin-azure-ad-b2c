//
//  AADB2CAuthenticator.h
//
//  Created by Aidela Karamyan on 3/13/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Cordova/CDVPlugin.h>

@interface AADB2CAuthenticator : CDVPlugin

- (void)authenticate:(CDVInvokedUrlCommand *)command;

@end
