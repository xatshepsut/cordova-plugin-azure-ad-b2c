//
//  AADB2CSettings.m
//
//  Created by Aidela Karamyan on 3/3/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "AADB2CSettings.h"

@implementation AADB2CSettings

+ (id)sharedInstance {
  static AADB2CSettings *instance = nil;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
    
    instance.clientId = @"";
    instance.tenantName = @"";
    instance.policyName = @"";
    
    instance.accountIdentifier = @"B2C_Acccount";
    instance.clientSecret = @"";
    instance.bhh = @"urn:ietf:wg:oauth:2.0:oob";
    instance.keychain = @"com.microsoft.azureactivedirectory.samples.graph.QuickStart";
    instance.contentType = @"application/x-www-form-urlencoded";
  });
  
  return instance;
}

- (void)setupWithDictionary:(NSDictionary *)dictionary {
  _clientId = [dictionary objectForKey:@"clientId"];
  _tenantName = [dictionary objectForKey:@"tenantName"];
  _policyName = [dictionary objectForKey:@"policyName"];
}

- (BOOL)isSetup {
  return (_clientId && _tenantName && _policyName);
}

- (NSString *)authUrl {
  return [NSString stringWithFormat:@"https://login.microsoftonline.com/%@/oauth2/v2.0/authorize?p=%@", _tenantName, _policyName];
}

- (NSString *)deauthUrl {
  return [NSString stringWithFormat:@"https://login.microsoftonline.com/%@/oauth2/v2.0/logout?p=%@", _tenantName, _policyName];
  // &post_logout_redirect_uri=https%3A%2F%2Faadb2cplayground.azurewebsites.net%2F
}
- (NSString *)loginUrl {
  return [NSString stringWithFormat:@"https://login.microsoftonline.com/%@/login", _tenantName];
}

- (NSString *)tokenUrl {
  return [NSString stringWithFormat:@"https://login.microsoftonline.com/%@/oauth2/v2.0/token?p=%@", _tenantName, _policyName];
}

@end
