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

#import "AboutViewController.h"
#import "TiqrConfig.h"
@import TiqrCore;

@interface AboutViewController ()

@property (nonatomic, strong) IBOutlet UILabel *tiqrProvidedByLabel;
@property (nonatomic, strong) IBOutlet UILabel *developedByLabel;
@property (nonatomic, strong) IBOutlet UILabel *interactionDesignLabel;
@property (nonatomic, strong) IBOutlet UIButton *okButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *okButtonBottomConstraint;
@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UIButton *appLogo;
@property (weak, nonatomic) IBOutlet UIButton *surfLogo;

@end

@implementation AboutViewController

- (instancetype)init {
    self = [super initWithNibName:@"AboutView" bundle:SWIFTPM_MODULE_BUNDLE];
    if (self != nil) {
        self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;    
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.appLogo setImage:[ThemeService shared].theme.aboutIcon forState:UIControlStateNormal];
    self.tiqrProvidedByLabel.text = [NSString stringWithFormat:[Localization localize:@"provided_by_title" comment:@"tiqr is provided by:"], TiqrConfig.appName];

    self.developedByLabel.text = [Localization localize:@"developed_by_title" comment:@"Developed by:"];
    self.interactionDesignLabel.text = [Localization localize:@"interaction_by_title" comment:@"Interaction design:"];
    
    [self.okButton.titleLabel setFont:[ThemeService shared].theme.buttonFont];
    [self.okButton setTitle:[Localization localize:@"ok_button" comment:@"OK"] forState:UIControlStateNormal];
    self.okButton.layer.cornerRadius = 5;

    self.versionLabel.text = [NSString stringWithFormat:[Localization localize:@"app_version" comment:@"App version: %@"], TiqrConfig.appVersion];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.okButton.backgroundColor = [ThemeService shared].theme.buttonBackgroundColor;
    [self.okButton.titleLabel setFont:[ThemeService shared].theme.buttonFont];
    [self.okButton setTitleColor:[ThemeService shared].theme.buttonTintColor forState:UIControlStateNormal];

    self.versionLabel.font = [ThemeService shared].theme.bodyFont;
    self.tiqrProvidedByLabel.font = [ThemeService shared].theme.bodyFont;
    self.developedByLabel.font = [ThemeService shared].theme.bodyFont;
    self.interactionDesignLabel.font = [ThemeService shared].theme.bodyFont;
    
    self.surfLogo.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (IBAction)tiqr {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://tiqr.org/"]];    
}

- (IBAction)surfnet {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.surf.nl/en/"]];    
}

- (IBAction)egeniq {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.egeniq.com/?utm_source=tiqr&utm_medium=referral&utm_campaign=about"]];    
}

- (IBAction)keenDesign {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.keen.design"]];
}

- (IBAction)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];

    self.okButtonBottomConstraint.constant = self.view.safeAreaInsets.bottom + 44.0;
}

@end
