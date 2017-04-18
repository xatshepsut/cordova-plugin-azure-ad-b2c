//
//  AADB2CLoginViewController.m
//
//  Created by Aidela Karamyan on 3/2/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "AADB2CLoginViewController.h"
#import "AADB2CSettings.h"
#import "NXOAuth2.h"

#import <SystemConfiguration/SystemConfiguration.h>


@interface AADB2CLoginViewController () <UIWebViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *loginView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIView *noConnectionView;
@property (strong, nonatomic) IBOutlet UIButton *retryButton;
@property (assign, nonatomic) SCNetworkReachabilityRef reachability;

@end


@implementation AADB2CLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];

  _reachability = SCNetworkReachabilityCreateWithName(NULL, [@"google.com" UTF8String]);
  
  NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:(4 * 1024 * 1024) diskCapacity:(20 * 1024 * 1024) diskPath:nil];
  [NSURLCache setSharedURLCache:URLCache];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChange:) name:NXOAuth2AccountStoreAccountsDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedToRequestAccess:) name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:nil];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (BOOL)hasNetworkConnection {
  BOOL hasConneciton = NO;
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(_reachability, &flags) &&
      (flags & kSCNetworkReachabilityFlagsReachable) != 0) {
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
      hasConneciton = YES;
    }

    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
         ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) &&
        ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)) {
      hasConneciton = YES;
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
      hasConneciton = YES;
    }
  }

  return hasConneciton;
}

#pragma mark - UI

- (void)setupUI {
  [self.view setBackgroundColor:[UIColor whiteColor]];

  NSArray *sideAttributes = @[@(NSLayoutAttributeTop), @(NSLayoutAttributeRight), @(NSLayoutAttributeBottom), @(NSLayoutAttributeLeft)];


  // Login web view

  _loginView = [[UIWebView alloc] initWithFrame:self.view.frame];
  [_loginView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_loginView setDelegate:self];
  [_loginView.scrollView setScrollEnabled:NO];
  [_loginView.scrollView setBounces:NO];
  [_loginView.scrollView setDelegate:self];
  [self.view addSubview:_loginView];

  for (NSNumber *attr in sideAttributes) {
    [self addConstraintTo:self.view relativeTo:_loginView withAttribute:[attr integerValue] andConstant:0.0f];
  }


  // Activity indicator

  _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [_activityIndicator setColor:[UIColor grayColor]];
  [_activityIndicator setCenter:self.view.center];
  [self.view addSubview:_activityIndicator];

  [self addConstraintTo:self.view relativeTo:_activityIndicator withAttribute:NSLayoutAttributeCenterX andConstant:0.0f];
  [self addConstraintTo:self.view relativeTo:_activityIndicator withAttribute:NSLayoutAttributeCenterY andConstant:0.0f];

  [_activityIndicator startAnimating];


  // No connection view

  _noConnectionView = [[UIView alloc] initWithFrame:self.view.frame];
  [_noConnectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_noConnectionView setBackgroundColor:[UIColor whiteColor]];
  [_noConnectionView setHidden:YES];
  [self.view addSubview:_noConnectionView];

  for (NSNumber *attr in sideAttributes) {
    [self addConstraintTo:self.view relativeTo:_noConnectionView withAttribute:[attr integerValue] andConstant:0.0f];
  }

  UILabel *noConnectionLabel = [[UILabel alloc] init];
  [noConnectionLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [noConnectionLabel setNumberOfLines:0];
  [noConnectionLabel setText:@"You do not have an internet connection right now.\nPlease connect and then try again."];
  [noConnectionLabel setFont:[UIFont fontWithName:noConnectionLabel.font.fontName size:18]];
  [noConnectionLabel setTextAlignment:NSTextAlignmentCenter];
  [_noConnectionView addSubview:noConnectionLabel];

  [self addConstraintTo:_noConnectionView relativeTo:noConnectionLabel withAttribute:NSLayoutAttributeLeft andConstant:20.0f];
  [self addConstraintTo:_noConnectionView relativeTo:noConnectionLabel withAttribute:NSLayoutAttributeRight andConstant:-20.0f];
  [self addConstraintTo:_noConnectionView relativeTo:noConnectionLabel withAttribute:NSLayoutAttributeCenterY andConstant:-100.0f];

  _retryButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [_retryButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_retryButton setBackgroundColor:[UIColor grayColor]];
  [_retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [_retryButton setTitle:@"Retry" forState:UIControlStateNormal];
  [_retryButton.titleLabel setFont:[UIFont fontWithName:_retryButton.titleLabel.font.fontName size:18]];
  [_retryButton.layer setCornerRadius:5.0f];
  [_retryButton.layer setMasksToBounds:YES];
  [_noConnectionView addSubview:_retryButton];

  [self addConstraintTo:_noConnectionView relativeTo:_retryButton withAttribute:NSLayoutAttributeCenterX andConstant:0.0f];
  [self addConstraintTo:_noConnectionView relativeTo:_retryButton withAttribute:NSLayoutAttributeCenterY andConstant:0.0f];
  [_retryButton addConstraint:[NSLayoutConstraint constraintWithItem:_retryButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:80.0f]];
}

- (void)setupNoConnectionViewWithSelector:(SEL)selector {
  [_noConnectionView setHidden:NO];
  [_retryButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
  [_retryButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
}

- (void)addConstraintTo:(UIView *)view relativeTo:(UIView *)secondView withAttribute:(NSLayoutAttribute)attr andConstant:(CGFloat)constant {
  [view addConstraint:[NSLayoutConstraint constraintWithItem:secondView attribute:attr relatedBy:NSLayoutRelationEqual toItem:view attribute:attr multiplier:1.0f constant:constant]];
}

#pragma mark - Public

- (void)authenticate {
  if (![self hasNetworkConnection]) {
    [self setupNoConnectionViewWithSelector:@selector(authenticate)];
    return;
  }

  [_noConnectionView setHidden:YES];

  AADB2CSettings *settings = [AADB2CSettings sharedInstance];
  
  [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:settings.accountIdentifier withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
    [_loginView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
  }];
}

- (void)reauthenticate {
  if (![self hasNetworkConnection]) {
    [self setupNoConnectionViewWithSelector:@selector(reauthenticate)];
    return;
  }

  [_noConnectionView setHidden:YES];

  NSURL *url = [NSURL URLWithString:[[AADB2CSettings sharedInstance] deauthUrl]];

  [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];

    if (statusCode / 100 != 2) {
      if ([_delegate respondsToSelector:@selector(authenticationFailedWithErrorMessage:)]) {
        [_delegate authenticationFailedWithErrorMessage:@"Failed to revoke user's access."];
      }
      return;
    }

    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    NXOAuth2Account *account = [[AADB2CSettings sharedInstance] account];
    if (account) {
      [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }

    [self authenticate];
  }] resume];
}

#pragma mark - Notifications

- (void)accountDidChange:(NSNotification *)notification {
  if (notification.userInfo) {
    NXOAuth2Account *account = [notification.userInfo objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
    [[AADB2CSettings sharedInstance] setAccount:account];

    if ([_delegate respondsToSelector:@selector(authenticationCompletedWithResult:)]) {
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

      NSDictionary *dictionary = @{
        @"tokenType": account.accessToken.tokenType,
        @"accessToken": account.accessToken.accessToken,
        @"refreshToken": account.accessToken.refreshToken,
        @"expiresAt": [dateFormatter stringFromDate:account.accessToken.expiresAt]
      };

      [_delegate authenticationCompletedWithResult:dictionary];
    }
  } else {
    [[AADB2CSettings sharedInstance] setAccount:nil];
  }
}

- (void)failedToRequestAccess:(NSNotification *)notification {
  NSError *error = [notification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];

  if ([_delegate respondsToSelector:@selector(authenticationFailedWithErrorMessage:)]) {
    [_delegate authenticationFailedWithErrorMessage:error.description];
  }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  AADB2CSettings *settings = [AADB2CSettings sharedInstance];
  NSString *urlString = [request.URL absoluteString];
  
  if ([urlString rangeOfString:settings.bhh options:NSCaseInsensitiveSearch].location != NSNotFound) {
    [_loginView setHidden:YES];
    [_activityIndicator startAnimating];
    
    [[NXOAuth2AccountStore sharedStore] handleRedirectURL:request.URL];
  }
  
  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  AADB2CSettings *settings = [AADB2CSettings sharedInstance];
  NSString *urlString = [_loginView.request.URL absoluteString];
  
  if ([urlString rangeOfString:settings.authUrl options:NSCaseInsensitiveSearch].location != NSNotFound ||
      [urlString rangeOfString:settings.loginUrl options:NSCaseInsensitiveSearch].location != NSNotFound) {
    [_activityIndicator stopAnimating];
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  scrollView.bounds = _loginView.bounds;
}

@end
