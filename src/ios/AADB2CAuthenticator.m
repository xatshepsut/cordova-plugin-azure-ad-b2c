//
//  AADB2CAuthenticator.m
//
//  Created by Aidela Karamyan on 3/13/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "AADB2CAuthenticator.h"
#import "AADB2CLoginViewController.h"
#import "AADB2CSettings.h"
#import "NXOAuth2.h"

@interface AADB2CAuthenticator () <AADB2CLoginViewControllerDelegate>

@property (copy) NSString *callbackId;

@end


@implementation AADB2CAuthenticator

- (void)authenticate:(CDVInvokedUrlCommand *)command {
  _callbackId = command.callbackId;
  
  NSDictionary *params = [command.arguments objectAtIndex: 0];
  [[AADB2CSettings sharedInstance] setupWithDictionary:params];
  
  if ([[AADB2CSettings sharedInstance] isSetup]) {
    [self setupOAuth2AccountStore];

    AADB2CLoginViewController *loginViewController = [[AADB2CLoginViewController alloc] init];
    [loginViewController setDelegate:self];
    [self.viewController presentViewController:loginViewController animated:YES completion:nil];
    [loginViewController authenticate];
  } else {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Required parameters are missing."];
    [self returnWithResult:result];
  }
}

- (void)reauthenticate:(CDVInvokedUrlCommand *)command {
  _callbackId = command.callbackId;

  if ([[AADB2CSettings sharedInstance] isSetup]) {
    AADB2CLoginViewController *loginViewController = [[AADB2CLoginViewController alloc] init];
    [loginViewController setDelegate:self];
    [self.viewController presentViewController:loginViewController animated:YES completion:nil];
    [loginViewController reauthenticate];
  } else {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@""];
    [self returnWithResult:result];
  }
}

- (void)setupOAuth2AccountStore {
  AADB2CSettings *settings = [AADB2CSettings sharedInstance];

  NSDictionary *customHeaders = [NSDictionary dictionaryWithObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
  NSDictionary *B2cConfigDict = @{
    kNXOAuth2AccountStoreConfigurationClientID: settings.clientId,
    kNXOAuth2AccountStoreConfigurationSecret: settings.clientSecret,
    kNXOAuth2AccountStoreConfigurationScope: [NSSet setWithObjects:@"offline_access", settings.clientId, nil],
    kNXOAuth2AccountStoreConfigurationAuthorizeURL: [NSURL URLWithString:settings.authUrl],
    kNXOAuth2AccountStoreConfigurationTokenURL: [NSURL URLWithString:settings.tokenUrl],
    kNXOAuth2AccountStoreConfigurationRedirectURL: [NSURL URLWithString:settings.bhh],
    kNXOAuth2AccountStoreConfigurationCustomHeaderFields: customHeaders
  };

  [[NXOAuth2AccountStore sharedStore] setConfiguration:B2cConfigDict forAccountType:settings.accountIdentifier];
}

- (void)returnWithResult:(CDVPluginResult *)result {
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
  [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
  _callbackId = nil;
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
