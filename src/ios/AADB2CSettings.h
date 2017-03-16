//
//  AADB2CSettings.h
//
//  Created by Aidela Karamyan on 3/3/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AADB2CSettings : NSObject

@property (strong, nonatomic) NSString *clientId;
@property (strong, nonatomic) NSString *tenantName;
@property (strong, nonatomic) NSString *policyName;

@property (strong, nonatomic) NSString *authUrl;
@property (strong, nonatomic) NSString *loginUrl;
@property (strong, nonatomic) NSString *tokenUrl;

@property (strong, nonatomic) NSString *accountIdentifier;
@property (strong, nonatomic) NSString *clientSecret;
@property (strong, nonatomic) NSString *bhh;
@property (strong, nonatomic) NSString *keychain;
@property (strong, nonatomic) NSString *contentType;


+ (id)sharedInstance;
- (BOOL)setupWithDictionary:(NSDictionary *)dictionary;

@end
