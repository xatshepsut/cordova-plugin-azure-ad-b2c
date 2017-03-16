//
//  NXOAuth2AccountStore+Extension.h
//
//  Created by Aidela Karamyan on 3/13/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "NXOAuth2AccountStore.h"
#import "NXOAuth2AccessToken.h"

@protocol NXOAuth2AccountStoreDelegate <NSObject>

- (void)didGetAccessToken:(NXOAuth2AccessToken *_Nonnull)token;

@end


@interface NXOAuth2AccountStore (Extension)

@property(nonatomic, weak, nullable) id <NXOAuth2AccountStoreDelegate> delegate;

@end
