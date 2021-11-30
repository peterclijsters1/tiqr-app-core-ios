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

#import "TiqrCoreManager.h"
#import "AuthenticationChallenge.h"
#import "EnrollmentChallenge.h"
#import "AuthenticationIdentityViewController.h"
#import "AuthenticationConfirmViewController.h"
#import "EnrollmentConfirmViewController.h"
#import "ScanViewController.h"
#import "NotificationRegistration.h"
#import "ScanViewController.h"
#import "StartViewController.h"
#import "ErrorViewController.h"
#import "ServiceContainer.h"
#import "TiqrToolbar.h"
#import "TiqrNavigationBar.h"
#import "TiqrConfig.h"
@import TiqrCore;

@interface TiqrCoreManager ()
    @property (nonatomic, strong) UINavigationController *navigationController;
@end

@implementation TiqrCoreManager

#pragma mark -
#pragma mark Application lifecycle

+ (instancetype)sharedInstance {
    static TiqrCoreManager *sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:SWIFTPM_MODULE_BUNDLE];
        sharedInstance.navigationController = [storyboard instantiateInitialViewController];

        if (@available(iOS 13.0, *)) {
            UIColor *color = [ThemeService shared].theme.primaryColor;

            UINavigationBarAppearance *navigationBarAppearance = [UINavigationBarAppearance new];
            [navigationBarAppearance configureWithOpaqueBackground];
            navigationBarAppearance.backgroundColor = color;
            sharedInstance.navigationController.navigationBar.standardAppearance = navigationBarAppearance;
            sharedInstance.navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance;

            UIToolbarAppearance *toolbarAppearance = [UIToolbarAppearance new];
            [toolbarAppearance configureWithOpaqueBackground];
            toolbarAppearance.backgroundColor = color;
            sharedInstance.navigationController.toolbar.standardAppearance = toolbarAppearance;
            if (@available(iOS 15.0, *)) {
                sharedInstance.navigationController.toolbar.scrollEdgeAppearance = toolbarAppearance;
            }
        }

    });
    return sharedInstance;
}

- (UINavigationController * _Nonnull)startWithOptions:(NSDictionary * _Nullable)launchOptions {

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	BOOL showInstructions = 
        [defaults objectForKey:@"show_instructions_preference"] == nil || 
        [defaults boolForKey:@"show_instructions_preference"];		

    BOOL allIdentitiesBlocked = ServiceContainer.sharedInstance.identityService.allIdentitiesBlocked;

	if (!allIdentitiesBlocked && !showInstructions) {
		ScanViewController *scanViewController = [[ScanViewController alloc] init];
        [self.navigationController pushViewController:scanViewController animated:NO];
    }

    if (launchOptions != nil) {
        NSDictionary *info = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

        if (info != nil) {
            [self startChallenge:[info valueForKey:@"challenge"]];
        }
    }

    return self.navigationController;
}

- (void)popToRootViewControllerAnimated:(BOOL)animated {
    [self.navigationController popToRootViewControllerAnimated:animated];
}

- (void)popToStartViewControllerAnimated:(BOOL)animated {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
    BOOL showInstructions = [defaults objectForKey:@"show_instructions_preference"] == nil || [defaults boolForKey:@"show_instructions_preference"];
    BOOL allIdentitiesBlocked = ServiceContainer.sharedInstance.identityService.allIdentitiesBlocked;

    if (allIdentitiesBlocked || showInstructions) {
        [self.navigationController popToRootViewControllerAnimated:animated];
    } else {
        UIViewController *scanViewController = self.navigationController.viewControllers[1];
        [self.navigationController popToViewController:scanViewController animated:animated];
    }
}

#pragma mark -
#pragma mark Authentication / enrollment challenge

- (void)startChallenge: (NSString *)rawChallenge  {
    UIViewController *firstViewController = self.navigationController.viewControllers[[self.navigationController.viewControllers count] > 1 ? 1 : 0];
    [self.navigationController popToViewController:firstViewController animated:NO];

    ChallengeService *challengeService = ServiceContainer.sharedInstance.challengeService;

    [challengeService startChallengeFromScanResult:rawChallenge completionHandler:^(TIQRChallengeType type, NSObject *challengeObject, NSError *error) {
        if (!error) {
            switch (type) {
                case TIQRChallengeTypeAuthentication: {
                    UIViewController *viewController = nil;
                    AuthenticationChallenge *authenticationChallenge = (AuthenticationChallenge *)challengeObject;
                    
                    if (authenticationChallenge.identity != nil) {
                        viewController = [[AuthenticationConfirmViewController alloc] initWithAuthenticationChallenge:authenticationChallenge];
                    } else {
                        viewController = [[AuthenticationIdentityViewController alloc] initWithAuthenticationChallenge:authenticationChallenge];
                    }
                    
                    [self.navigationController pushViewController:viewController animated:NO];
                } break;
                    
                case TIQRChallengeTypeEnrollment: {
                    EnrollmentConfirmViewController *enrollmentConfirmViewController = [[EnrollmentConfirmViewController alloc] initWithEnrollmentChallenge:(EnrollmentChallenge *)challengeObject];
                    [self.navigationController pushViewController:enrollmentConfirmViewController animated:NO];
                } break;
                    
                default: break;
            }
        } else {
            ErrorViewController *errorViewController = [[ErrorViewController alloc] initWithErrorTitle:[error localizedDescription] errorMessage:[error localizedFailureReason]];
            [self.navigationController pushViewController:errorViewController animated:NO];
        }
    }];
}

@end
