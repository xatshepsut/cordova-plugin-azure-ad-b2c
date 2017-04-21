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

    instance.baseUrl = @"https://login.microsoftonline.com";
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
  return [NSString stringWithFormat:@"%@/%@/oauth2/v2.0/authorize?p=%@", _baseUrl, _tenantName, _policyName];
}

- (NSString *)deauthUrl {
  return [NSString stringWithFormat:@"%@/%@/oauth2/v2.0/logout?p=%@", _baseUrl, _tenantName, _policyName];
}
- (NSString *)loginUrl {
  return [NSString stringWithFormat:@"%@/%@/login", _baseUrl, _tenantName];
}

- (NSString *)tokenUrl {
  return [NSString stringWithFormat:@"%@/%@/oauth2/v2.0/token?p=%@", _baseUrl, _tenantName, _policyName];
}

@end
