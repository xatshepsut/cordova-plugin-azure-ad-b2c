//
//  AADB2CLoginViewController.m
//
//  Created by Aidela Karamyan on 3/2/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "AADB2CLoginViewController.h"
#import "AADB2CSettings.h"
#import "NXOAuth2.h"

@interface AADB2CLoginViewController () <UIWebViewDelegate, UIScrollViewDelegate>

@property(strong, nonatomic) IBOutlet UIWebView *loginView;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


@implementation AADB2CLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
  
  NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:(4 * 1024 * 1024) diskCapacity:(20 * 1024 * 1024) diskPath:nil];
  [NSURLCache setSharedURLCache:URLCache];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChange:) name:NXOAuth2AccountStoreAccountsDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedToRequestAccess:) name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:nil];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)setupUI {
  [self.view setBackgroundColor:[UIColor whiteColor]];
  
  _loginView = [[UIWebView alloc] initWithFrame:self.view.frame];
  [_loginView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_loginView setDelegate:self];
  [_loginView.scrollView setScrollEnabled:NO];
  [_loginView.scrollView setBounces:NO];
  [_loginView.scrollView setDelegate:self];
  [self.view addSubview:_loginView];
  
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loginView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loginView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loginView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loginView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
  
  _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [_activityIndicator setColor:[UIColor grayColor]];
  [_activityIndicator setCenter:self.view.center];
  [self.view addSubview:_activityIndicator];
  
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
  
  [_activityIndicator startAnimating];
}

- (void)authenticate {
  AADB2CSettings *settings = [AADB2CSettings sharedInstance];
  
  [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:settings.accountIdentifier withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
    [_loginView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
  }];
}

- (void)reauthenticate {
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
