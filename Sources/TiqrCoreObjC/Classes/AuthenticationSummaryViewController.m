/*
 * Copyright (c) 2010-2011 SURFnet bv
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of SURFnet bv nor the names of its contributors 
 *    may be used to endorse or promote products derived from this 
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AuthenticationSummaryViewController.h"
#import "TiqrCoreManager.h"
#import "ServiceContainer.h"
#import "NSString+LocalizedBiometricString.h"
#import "TiqrConfig.h"
@import TiqrCore;

@interface AuthenticationSummaryViewController ()

@property (nonatomic, strong) AuthenticationChallenge *challenge;

@property (nonatomic, strong) IBOutlet UILabel *loginConfirmLabel;
@property (nonatomic, strong) IBOutlet UILabel *loginInformationLabel;
@property (nonatomic, strong) IBOutlet UILabel *toLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountIDLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityIdentifierLabel;
@property (nonatomic, strong) IBOutlet UILabel *serviceProviderDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *serviceProviderIdentifierLabel;
@property (nonatomic, strong) IBOutlet UIButton *returnButton;
@property (nonatomic, copy) NSString *PIN;

@end

@implementation AuthenticationSummaryViewController

- (instancetype)initWithAuthenticationChallenge:(AuthenticationChallenge *)challenge usedPIN:(NSString *)PIN {
    self = [super initWithNibName:@"AuthenticationSummaryView" bundle:SWIFTPM_MODULE_BUNDLE];
	if (self != nil) {
		self.challenge = challenge;
        self.PIN = PIN;
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginConfirmLabel.text = [Localization localize:@"successfully_logged_in" comment:@"Login succes confirmation message"];
    self.loginInformationLabel.text = [Localization localize:@"loggedin_with_account" comment:@"Login information message"];
    self.toLabel.text = [Localization localize:@"to_service_provider" comment:@"to:"];
    self.accountLabel.text = [Localization localize:@"full_name" comment:@"Account"];
    self.accountIDLabel.text = [NSString stringWithFormat:[Localization localize:@"id" comment:@"Tiqr account ID"], TiqrConfig.appName];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.leftBarButtonItem = backButton;
    
	self.identityDisplayNameLabel.text = self.challenge.identity.displayName;
	self.identityIdentifierLabel.text = self.challenge.identity.identifier;
	self.serviceProviderDisplayNameLabel.text = self.challenge.serviceProviderDisplayName;
	self.serviceProviderIdentifierLabel.text = self.challenge.serviceProviderIdentifier;
    
    if (self.challenge.returnUrl != nil) {
        [self.returnButton setTitle:[Localization localize:@"return_button" comment:@"Return to button title"] forState:UIControlStateNormal];
        self.returnButton.hidden = NO;
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.returnButton.backgroundColor = [ThemeService shared].theme.buttonBackgroundColor;
    [self.returnButton.titleLabel setFont:[ThemeService shared].theme.buttonFont];
    [self.returnButton setTitleColor:[ThemeService shared].theme.buttonTintColor forState:UIControlStateNormal];

    self.loginConfirmLabel.font = [ThemeService shared].theme.headerFont;

    self.loginInformationLabel.font = [ThemeService shared].theme.bodyFont;
    self.identityIdentifierLabel.font = [ThemeService shared].theme.bodyFont;
    self.identityDisplayNameLabel.font = [ThemeService shared].theme.bodyFont;
    self.toLabel.font = [ThemeService shared].theme.bodyFont;
    self.serviceProviderDisplayNameLabel.font = [ThemeService shared].theme.bodyFont;
    self.serviceProviderIdentifierLabel.font = [ThemeService shared].theme.bodyFont;

    self.accountLabel.font = [ThemeService shared].theme.bodyBoldFont;
    self.accountIDLabel.font = [ThemeService shared].theme.bodyBoldFont;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (ServiceContainer.sharedInstance.secretService.biometricIDAvailable &&
        !self.challenge.identity.usesBiometrics &&
        ![self.challenge.identity.biometricIDAvailable boolValue] &&
        [self.challenge.identity.shouldAskToEnrollInBiometricID boolValue] &&
        self.PIN) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[Localization localize:@"upgrade_to_biometric_id" comment:@"Upgrade account to TouchID alert title"] message:LocalizedBiometricString(@"upgrade_to_touch_id_message", @"upgrade_to_face_id_message") preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:[Localization localize:@"upgrade" comment:@"Upgrade (to TouchID)"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [ServiceContainer.sharedInstance.identityService upgradeIdentityToTouchID:self.challenge.identity withPIN:self.PIN];
            self.PIN = nil;
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:[Localization localize:@"cancel" comment:@"Cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            self.challenge.identity.shouldAskToEnrollInBiometricID = @NO;
            [ServiceContainer.sharedInstance.identityService saveIdentities];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)done {
    [TiqrCoreManager.sharedInstance popToStartViewControllerAnimated:YES];
}

- (IBAction)returnToCaller {
    [TiqrCoreManager.sharedInstance popToStartViewControllerAnimated:NO];
    NSString *returnURL = [NSString stringWithFormat:@"%@?successful=1", self.challenge.returnUrl];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:returnURL]];
}

@end
