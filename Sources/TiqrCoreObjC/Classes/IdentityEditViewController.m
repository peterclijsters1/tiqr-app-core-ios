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

#import "IdentityEditViewController.h"
#import "Identity.h"
#import "IdentityProvider.h"
#import "ServiceContainer.h"
#import "NSString+LocalizedBiometricString.h"
#import "TiqrConfig.h"
@import TiqrCore;

@interface IdentityEditViewController ()

@property (nonatomic, strong) Identity *identity;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;
@property (nonatomic, strong) IBOutlet UIImageView *identityProviderLogoImageView;
@property (nonatomic, strong) IBOutlet UILabel *identityProviderIdentifierLabel;
@property (nonatomic, strong) IBOutlet UILabel *identityProviderDisplayNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *blockedWarningLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation IdentityEditViewController

- (instancetype)initWithIdentity:(Identity *)identity {
    self = [super initWithNibName:@"IdentityEditView" bundle:SWIFTPM_MODULE_BUNDLE];
    if (self != nil) {
        self.identity = identity;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.deleteButton setTitle:NSLocalizedStringFromTableInBundle(@"delete_button", nil, SWIFTPM_MODULE_BUNDLE, @"Delete") forState:UIControlStateNormal];
    self.deleteButton.layer.cornerRadius = 5;
    
    self.blockedWarningLabel.text = NSLocalizedStringFromTableInBundle(@"identity_blocked_message", nil, SWIFTPM_MODULE_BUNDLE, @"Warning this account is blocked and needs to be reactivated.");
    
    self.identityProviderLogoImageView.image = [UIImage imageWithData:self.identity.identityProvider.logo];
    self.identityProviderIdentifierLabel.text = self.identity.identityProvider.identifier;
    self.identityProviderDisplayNameLabel.text = self.identity.identityProvider.displayName;    
    
    if ([self.identity.blocked boolValue]) {
        self.blockedWarningLabel.hidden = NO;
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.tableView.tableFooterView = [UIView new];
    
    self.deleteButton.backgroundColor = [ThemeService shared].theme.buttonBackgroundColor;
    [self.deleteButton.titleLabel setFont:[ThemeService shared].theme.buttonFont];
    [self.deleteButton setTitleColor:[ThemeService shared].theme.buttonTintColor forState:UIControlStateNormal];
    
    self.blockedWarningLabel.font = [ThemeService shared].theme.bodyBoldFont;
    self.identityProviderDisplayNameLabel.font = [ThemeService shared].theme.headerFont;
    self.identityProviderIdentifierLabel.font = [ThemeService shared].theme.bodyFont;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.identity.usesOldBiometricFlow boolValue] || !ServiceContainer.sharedInstance.secretService.biometricIDAvailable) {
        return 3;
    } else {
        return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.minimumScaleFactor = 0.75;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.textLabel.font = [ThemeService shared].theme.bodyFont;
    cell.detailTextLabel.font = [ThemeService shared].theme.bodyFont;
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.accessoryView = nil;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"full_name", nil, SWIFTPM_MODULE_BUNDLE, @"Username label");
        cell.detailTextLabel.text = self.identity.displayName;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"id", nil, SWIFTPM_MODULE_BUNDLE, @"Tiqr account ID"), TiqrConfig.appName];
        cell.detailTextLabel.text = self.identity.identifier;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"information", nil, SWIFTPM_MODULE_BUNDLE, @"Info label");
        cell.detailTextLabel.text = self.identity.identityProvider.infoUrl;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 3) {
        cell.detailTextLabel.text = nil;
        
        UISwitch *biometricIDSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = biometricIDSwitch;
        
        if ([self.identity.biometricIDAvailable boolValue]) {
            cell.textLabel.text = LocalizedBiometricString(@"identity_uses_touch_id", @"identity_uses_face_id");
            biometricIDSwitch.on = [self.identity.biometricIDEnabled boolValue];
            
            [biometricIDSwitch addTarget:self action:@selector(toggleBiometricID:) forControlEvents:UIControlEventValueChanged];
        } else {
            cell.textLabel.text = LocalizedBiometricString(@"identity_upgrade_to_touch_id", @"identity_upgrade_to_face_id");
            biometricIDSwitch.on = [self.identity.shouldAskToEnrollInBiometricID boolValue];
            
            [biometricIDSwitch addTarget:self action:@selector(toggleBiometricEnrollment:) forControlEvents:UIControlEventValueChanged];
        }
    }
    
    return cell;    
}

- (void)toggleBiometricID:(UISwitch *)sender {
    self.identity.biometricIDEnabled = @(sender.on);
    [ServiceContainer.sharedInstance.identityService saveIdentities];
}

- (void)toggleBiometricEnrollment:(UISwitch *)sender {
    self.identity.shouldAskToEnrollInBiometricID = @(sender.on);
    [ServiceContainer.sharedInstance.identityService saveIdentities];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.identity.identityProvider.infoUrl]];
    }
}

- (IBAction)deleteIdentity {
    NSString *title = NSLocalizedStringFromTableInBundle(@"confirm_delete_title", nil, SWIFTPM_MODULE_BUNDLE, @"Sure?");
    NSString *message = NSLocalizedStringFromTableInBundle(@"confirm_delete", nil, SWIFTPM_MODULE_BUNDLE, @"Are you sure you want to delete this identity?");
    NSString *yesTitle = NSLocalizedStringFromTableInBundle(@"yes_button", nil, SWIFTPM_MODULE_BUNDLE, @"Yes button title");
    NSString *noTitle = NSLocalizedStringFromTableInBundle(@"no_button", nil, SWIFTPM_MODULE_BUNDLE, @"No button title");

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesButton = [UIAlertAction actionWithTitle:yesTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [self performDeleteIdentity];
    }];
    
    UIAlertAction *noButton = [UIAlertAction actionWithTitle:noTitle style:UIAlertActionStyleCancel handler:nil];

    [alertController addAction:yesButton];
    [alertController addAction:noButton];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)performDeleteIdentity{
    IdentityService *identityService = ServiceContainer.sharedInstance.identityService;
    IdentityProvider *identityProvider = self.identity.identityProvider;
    
    NSString *identityIdentifier = self.identity.identifier;
    NSString *providerIdentifier = identityProvider.identifier;
    
    if (identityProvider != nil) {
		
        [identityProvider removeIdentitiesObject:self.identity];
        [identityService deleteIdentity:self.identity];
        if ([identityProvider.identities count] == 0) {
            [identityService deleteIdentityProvider:identityProvider];
        }
    } else {
        [identityService deleteIdentity:self.identity];
    }
    if ([identityService saveIdentities]) {
        [ServiceContainer.sharedInstance.secretService deleteSecretForIdentityIdentifier:identityIdentifier
                                                                      providerIdentifier:providerIdentifier];
        
        [self.navigationController popViewControllerAnimated:YES];
    } else {
		NSString *title = NSLocalizedStringFromTableInBundle(@"error", nil, SWIFTPM_MODULE_BUNDLE, @"Alert title for error");
        NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"error_auth_unknown_error", nil, SWIFTPM_MODULE_BUNDLE, @"Unknown error message"), TiqrConfig.appName];
		NSString *okTitle = NSLocalizedStringFromTableInBundle(@"ok_button", nil, SWIFTPM_MODULE_BUNDLE, @"OK button title");

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction: okButton];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end
