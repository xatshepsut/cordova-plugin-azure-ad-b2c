//
//  AADB2CLoginViewController.m
//
//  Created by Aidela Karamyan on 3/2/17.
//  Copyright © 2017 Macadamian. All rights reserved.
//

#import "AADB2CLoginViewController.h"
#import "AADB2CSettings.h"
#import "NXOAuth2.h"
#import "NXOAuth2AccountStore+Extension.h"

@interface AADB2CLoginViewController () <UIWebViewDelegate, UIScrollViewDelegate, NXOAuth2AccountStoreDelegate>

@property(strong, nonatomic) IBOutlet UIWebView *loginView;
@property(strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(strong, nonatomic) NXOAuth2AccessToken *token;

@end


@implementation AADB2CLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
  [self setupOAuth2AccountStore];
  [self requestOAuth2Access];
  
  NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:(4 * 1024 * 1024) diskCapacity:(20 * 1024 * 1024) diskPath:nil];
  [NSURLCache setSharedURLCache:URLCache];
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
  
  [[NXOAuth2AccountStore sharedStore] setDelegate:self];
  [[NXOAuth2AccountStore sharedStore] setConfiguration:B2cConfigDict forAccountType:settings.accountIdentifier];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *notification) {
    if (notification.userInfo && _token) {
      if ([_delegate respondsToSelector:@selector(authenticationCompletedWithResult:)]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        
        NSDictionary *dictionary = @{
          @"accessToken": _token.accessToken,
          @"tokenType": _token.tokenType,
          @"expiresASt": [dateFormatter stringFromDate:_token.expiresAt]
        };
        
        [_delegate authenticationCompletedWithResult:dictionary];
        _token = nil;
      }
    } else {
      if ([_delegate respondsToSelector:@selector(authenticationFailedWithErrorMessage:)]) {
        [_delegate authenticationFailedWithErrorMessage:@"Account is removed or access is lost."];
      }
    }
  }];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *notification) {
    NSError *error = [notification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
    if ([_delegate respondsToSelector:@selector(authenticationFailedWithErrorMessage:)]) {
      [_delegate authenticationFailedWithErrorMessage:error.description];
    }
  }];
}

- (void)requestOAuth2Access {
  AADB2CSettings *settings = [AADB2CSettings sharedInstance];
  
  [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:settings.accountIdentifier withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
    [_loginView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
  }];
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

#pragma mark - NXOAuth2AccountStoreDelegate

- (void)didGetAccessToken:(NXOAuth2AccessToken *)token {
  _token = token;
}

@end
