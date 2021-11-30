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

#import "EnrollmentSummaryViewController.h"
#import "TiqrCoreManager.h"
#import "ServiceContainer.h"
@import TiqrCore;

@interface EnrollmentSummaryViewController ()

@property (nonatomic, strong) EnrollmentChallenge *challenge;
@property (nonatomic, strong) IBOutlet UILabel *accountActivatedLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountReadyLabel;
@property (nonatomic, strong) IBOutlet UILabel *fullNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountIDLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountDetailsLabel;
@property (nonatomic, strong) IBOutlet UILabel *enrolledLabel;
@property (nonatomic, strong) IBOutlet UILabel *enrollmentDomainLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityIdentifierLabel;
@property (nonatomic, strong) IBOutlet UIButton *returnButton;

@end

@implementation EnrollmentSummaryViewController

- (instancetype)initWithEnrollmentChallenge:(EnrollmentChallenge *)challenge {
    self = [super initWithNibName:@"EnrollmentSummaryView" bundle:SWIFTPM_MODULE_BUNDLE];
    if (self != nil) {
        self.challenge = challenge;
    }
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accountReadyLabel.text = NSLocalizedStringFromTableInBundle(@"account_ready", nil, SWIFTPM_MODULE_BUNDLE, @"Your account is ready to be used.");
    self.accountActivatedLabel.text = NSLocalizedStringFromTableInBundle(@"account_activated", nil, SWIFTPM_MODULE_BUNDLE, @"Your account is activated!");
    self.fullNameLabel.text = NSLocalizedStringFromTableInBundle(@"full_name", nil, SWIFTPM_MODULE_BUNDLE, @"Full name");
    self.accountIDLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"id", nil, SWIFTPM_MODULE_BUNDLE, @"Tiqr account ID"), TiqrConfig.appName];
    self.accountDetailsLabel.text = NSLocalizedStringFromTableInBundle(@"account_details_title", nil, SWIFTPM_MODULE_BUNDLE, @"Account details");
    
    self.enrolledLabel.text = NSLocalizedStringFromTableInBundle(@"enrolled_following_domain", nil, SWIFTPM_MODULE_BUNDLE, @"You are enrolled for the following domain:");
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    self.identityDisplayNameLabel.text = self.challenge.identityDisplayName;
    self.identityIdentifierLabel.text = self.challenge.identityIdentifier;
    self.enrollmentDomainLabel.text = [[NSURL URLWithString:self.challenge.enrollmentUrl] host];

    [self.returnButton.titleLabel setFont:[ThemeService shared].theme.buttonFont];
    self.returnButton.backgroundColor = [ThemeService shared].theme.buttonBackgroundColor;
    [self.returnButton setTitleColor:[ThemeService shared].theme.buttonTitleColor forState:UIControlStateNormal];

    if (self.challenge.returnUrl != nil) {
        [self.returnButton setTitle:NSLocalizedStringFromTableInBundle(@"return_button", nil, SWIFTPM_MODULE_BUNDLE, @"Return to button title") forState:UIControlStateNormal];
        self.returnButton.hidden = NO;
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.accountActivatedLabel.font = [ThemeService shared].theme.headerFont;

    self.enrolledLabel.font = [ThemeService shared].theme.bodyFont;
    self.identityIdentifierLabel.font = [ThemeService shared].theme.bodyFont;
    self.identityDisplayNameLabel.font = [ThemeService shared].theme.bodyFont;
    self.accountDetailsLabel.font = [ThemeService shared].theme.bodyFont;
    self.accountReadyLabel.font = [ThemeService shared].theme.bodyFont;

    self.fullNameLabel.font = [ThemeService shared].theme.bodyBoldFont;
    self.accountIDLabel.font = [ThemeService shared].theme.bodyBoldFont;
    self.enrollmentDomainLabel.font = [ThemeService shared].theme.bodyBoldFont;
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
