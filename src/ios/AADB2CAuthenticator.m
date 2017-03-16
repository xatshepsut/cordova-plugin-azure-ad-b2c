//
//  AADB2CAuthenticator.m
//
//  Created by Aidela Karamyan on 3/13/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "AADB2CAuthenticator.h"
#import "AADB2CLoginViewController.h"
#import "AADB2CSettings.h"

@interface AADB2CAuthenticator () <AADB2CLoginViewControllerDelegate>

@property(copy) NSString *callbackId;

@end


@implementation AADB2CAuthenticator

- (void)authenticate:(CDVInvokedUrlCommand *)command {
  _callbackId = command.callbackId;
  
  NSDictionary *params = [command.arguments objectAtIndex: 0];
  BOOL isSetup = [[AADB2CSettings sharedInstance] setupWithDictionary:params];
  
  if (isSetup) {
    AADB2CLoginViewController *loginViewController = [[AADB2CLoginViewController alloc] init];
    [loginViewController setDelegate:self];
    [self.viewController presentViewController:loginViewController animated:YES completion:nil];
  } else {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Required parameters are missing."];
    [self returnWithResult:result];
  }
}

- (void)returnWithResult:(CDVPluginResult *)result {
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
}

#pragma mark - AADB2CLoginViewControllerDelegate

- (void)authenticationCompletedWithResult:(NSDictionary *)token {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:token];
  [self returnWithResult:result];
}

- (void)authenticationFailedWithErrorMessage:(NSString *)errorMessage {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
  [self returnWithResult:result];
}

@end
