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

#import "EnrollmentConfirmViewController.h"
#import "EnrollmentPINViewController.h"
#import "ServiceContainer.h"
#import "External/MBProgressHUD.h"
#import "ErrorViewController.h"
#import "EnrollmentSummaryViewController.h"
@import TiqrCore;

@interface EnrollmentConfirmViewController ()

@property (nonatomic, strong) EnrollmentChallenge *challenge;
@property (nonatomic, strong) IBOutlet UILabel *confirmAccountLabel;
@property (nonatomic, strong) IBOutlet UILabel *activateAccountLabel;
@property (nonatomic, strong) IBOutlet UILabel *enrollDomainLabel;
@property (nonatomic, strong) IBOutlet UIButton *okButton;
@property (nonatomic, strong) IBOutlet UILabel *fullNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountIDLabel;
@property (nonatomic, strong) IBOutlet UILabel *accountDetailsLabel;

@property (nonatomic, strong) IBOutlet UILabel *identityDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityIdentifierLabel;
@property (nonatomic, strong) IBOutlet UILabel *enrollmentURLDomainLabel;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;

@end

@implementation EnrollmentConfirmViewController

- (instancetype)initWithEnrollmentChallenge:(EnrollmentChallenge *)challenge {
    self = [super initWithNibName:@"EnrollmentConfirmView" bundle:SWIFTPM_MODULE_BUNDLE];
    if (self != nil) {
        self.challenge = challenge;
    }
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.confirmAccountLabel.text = NSLocalizedStringFromTableInBundle(@"confirm_account_activation", nil, SWIFTPM_MODULE_BUNDLE, @"Confirm account activation");
    self.activateAccountLabel.text = NSLocalizedStringFromTableInBundle(@"activate_following_account", nil, SWIFTPM_MODULE_BUNDLE, @"Do you want to activate the following account");
    self.enrollDomainLabel.text = NSLocalizedStringFromTableInBundle(@"enroll_following_domain", nil, SWIFTPM_MODULE_BUNDLE, @"You will enroll to the following domain");
    self.fullNameLabel.text = NSLocalizedStringFromTableInBundle(@"full_name", nil, SWIFTPM_MODULE_BUNDLE, @"Full name");
    self.accountIDLabel.text = NSLocalizedStringFromTableInBundle(@"id", nil, SWIFTPM_MODULE_BUNDLE, @"Tiqr account ID");
    self.accountDetailsLabel.text = NSLocalizedStringFromTableInBundle(@"account_details_title", nil, SWIFTPM_MODULE_BUNDLE, "Account details");
    
    [self.okButton setTitle:NSLocalizedStringFromTableInBundle(@"ok_button", nil, SWIFTPM_MODULE_BUNDLE, @"OK") forState:UIControlStateNormal];
    self.okButton.layer.cornerRadius = 5;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.identityDisplayNameLabel.text = self.challenge.identityDisplayName;
    self.identityIdentifierLabel.text = self.challenge.identityIdentifier;
    self.enrollmentURLDomainLabel.text = [[NSURL URLWithString:self.challenge.enrollmentUrl] host];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [self.cancelButton setFont:[ThemeService shared].theme.bodyFont];

    self.okButton.backgroundColor = [ThemeService shared].theme.buttonBackgroundColor;
    [self.okButton.titleLabel setFont:[ThemeService shared].theme.buttonFont];
    [self.okButton setTitleColor:[ThemeService shared].theme.buttonTitleColor forState:UIControlStateNormal];

    self.confirmAccountLabel.font = [ThemeService shared].theme.headerFont;

    self.activateAccountLabel.font = [ThemeService shared].theme.bodyFont;
    self.accountDetailsLabel.font = [ThemeService shared].theme.bodyFont;
    self.identityDisplayNameLabel.font = [ThemeService shared].theme.bodyFont;
    self.identityIdentifierLabel.font = [ThemeService shared].theme.bodyFont;
    self.enrollDomainLabel.font = [ThemeService shared].theme.bodyFont;

    self.fullNameLabel.font = [ThemeService shared].theme.bodyBoldFont;
    self.accountIDLabel.font = [ThemeService shared].theme.bodyBoldFont;
    self.enrollmentURLDomainLabel.font = [ThemeService shared].theme.bodyBoldFont;
}


- (IBAction)ok {
    EnrollmentPINViewController *viewController = [[EnrollmentPINViewController alloc] initWithEnrollmentChallenge:self.challenge];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
