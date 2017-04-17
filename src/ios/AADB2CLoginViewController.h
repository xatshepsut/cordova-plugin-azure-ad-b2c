//
//  AADB2CLoginViewController.h
//
//  Created by Aidela Karamyan on 3/2/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AADB2CLoginViewControllerDelegate <NSObject>

- (void)authenticationCompletedWithResult:(NSDictionary *_Nonnull)result;
- (void)authenticationFailedWithErrorMessage:(NSString *_Nullable)errorMessage;

@end


@interface AADB2CLoginViewController : UIViewController

@property(nonatomic, weak, nullable) id <AADB2CLoginViewControllerDelegate> delegate;

- (void)authenticate;
- (void)reauthenticate;

@end

