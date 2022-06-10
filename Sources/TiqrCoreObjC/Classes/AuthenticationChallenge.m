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

#import "AuthenticationChallenge.h"
#import "NSString+DecodeURL.h"
#import "ServiceContainer.h"
#import "TiqrConfig.h"
@import TiqrCore;

NSString *const TIQRACErrorDomain = @"org.tiqr.ac";

@interface AuthenticationChallenge ()

@property (nonatomic, strong) IdentityProvider *identityProvider;
@property (nonatomic, strong) NSArray *identities;
@property (nonatomic, copy) NSString *serviceProviderIdentifier;
@property (nonatomic, copy) NSString *serviceProviderDisplayName;
@property (nonatomic, copy) NSString *sessionKey;
@property (nonatomic, copy) NSString *challenge;
@property (nonatomic, copy) NSString *returnUrl;
@property (nonatomic, copy) NSString *protocolVersion;

@end

@implementation AuthenticationChallenge

+ (BOOL)applyError:(NSError *)error toError:(NSError **)otherError {
    if (otherError != NULL) {
        *otherError = error;
    }
    
    return YES;
}

+ (void)generateInvalidQRCodeError:(NSError **)error {
    NSString *errorTitle = [Localization localize:@"error_auth_invalid_qr_code" comment:@"Invalid QR tag title"];
    NSString *errorMessage = [Localization localize:@"error_auth_invalid_challenge_message" comment:@"Invalid QR tag message"];
    NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
    [NSError errorWithDomain:TIQRACErrorDomain code:TIQRACInvalidQRTagError userInfo:details];
    [self applyError:[NSError errorWithDomain:TIQRACErrorDomain code:TIQRACInvalidQRTagError userInfo:details] toError:error];
}

+ (void)generateUnknownIdentityError:(NSError **)error {
    NSString *errorTitle = [Localization localize:@"error_auth_unknown_identity" comment:@"No account title"];
    NSString *errorMessage = [Localization localize:@"error_auth_no_identities_for_identity_provider" comment:@"No account message"];
    NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
    [self applyError:[NSError errorWithDomain:TIQRACErrorDomain code:TIQRACUnknownIdentityProviderError userInfo:details] toError:error];
}

+ (void)generateInvalidAccountError:(NSError **)error {
    NSString *errorTitle = [Localization localize:@"error_auth_invalid_account" comment:@"No account title"];
    NSString *errorMessage = [Localization localize:@"error_auth_invalid_account_message" comment:@"No account message"];
    NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
    [self applyError:[NSError errorWithDomain:TIQRACErrorDomain code:TIQRACZeroIdentitiesForIdentityProviderError userInfo:details] toError:error];
}

+ (void)generateAccountBlockedError:(NSError **)error {
    NSString *errorTitle = [Localization localize:@"error_auth_account_blocked_title" comment:@"Account blocked title"];
    NSString *errorMessage = [Localization localize:@"error_auth_account_blocked_message" comment:@"Account blocked message"];
    NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
    [self applyError:[NSError errorWithDomain:TIQRACErrorDomain code:TIQRACIdentityBlockedError userInfo:details] toError:error];
}


+ (AuthenticationChallenge * _Nullable)challengeWithChallengeString:(NSString *)challengeString error:(NSError **)error {

	NSURL *url = [NSURL URLWithString:challengeString];
    
	if (url == nil || ![TiqrConfig isValidAuthenticationURL:url.absoluteString]) {
        [self generateInvalidQRCodeError: error];
        return nil;
	}
    
    NSString *authenticationSchemeKey = @"TIQRAuthenticationURLScheme";
    NSString *appScheme = [[[NSBundle mainBundle] infoDictionary] objectForKey:authenticationSchemeKey];

    if ([[url scheme] isEqualToString: appScheme]) {
        // Old format URL
        return [self challengeFromOldFormatURL:url error:error];
    } else {
        // New format URL
        return [self challengeFromNewFormatURL:url error:error];
    }
}


+ (AuthenticationChallenge * _Nullable)challengeFromOldFormatURL:(NSURL * _Nonnull)url error:(NSError **)error {
    
    AuthenticationChallenge *challenge = [[AuthenticationChallenge alloc] init];
    if(![self findIdentityForServerIdentifier: url.host andUser:url.user forChallenge:challenge error: error]) {
        return nil;
    }
    challenge.sessionKey = url.pathComponents[1];
    challenge.challenge = url.pathComponents[2];
    if ([url.pathComponents count] > 3) {
        challenge.serviceProviderDisplayName = url.pathComponents[3];
    } else {
        challenge.serviceProviderDisplayName = [Localization localize:@"error_auth_unknown_identity_provider" comment:@"Unknown"];
    }
    challenge.serviceProviderIdentifier = @"";
    
    if ([url.pathComponents count] > 4) {
        challenge.protocolVersion = url.pathComponents[4];
    } else {
        challenge.protocolVersion = @"1";
    }

    NSString *regex = @"^http(s)?://.*";
    NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    if (url.query != nil && [url.query length] > 0 && [protocolPredicate evaluateWithObject:url.query.decodedURL] == YES) {
        challenge.returnUrl = url.query.decodedURL;
    } else {
        challenge.returnUrl = nil;
    }
    
    return challenge;
}

+ (AuthenticationChallenge * _Nullable)challengeFromNewFormatURL:(NSURL *)url error:(NSError **)error {
    
    AuthenticationChallenge *challenge = [[AuthenticationChallenge alloc] init];
    IdentityService *identityService = ServiceContainer.sharedInstance.identityService;
    
    NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    // Parse the parameters
    NSString *serverIdentifier = [self getQueryParameter:@"i" fromComponents:components];
    // User is optional
    NSString *user = [self getQueryParameter:@"u" fromComponents:components];

    if (!serverIdentifier) {
        NSLog(@"Required parameter 'i' missing from the authentication URL!");
        [self generateInvalidQRCodeError: error];
        return nil;
    }
    
    if(![self findIdentityForServerIdentifier: serverIdentifier andUser:user forChallenge:challenge error: error]) {
        return nil;
    }
    
    NSString *sessionKey = [self getQueryParameter:@"s" fromComponents:components];
    if (!sessionKey) {
        NSLog(@"Required parameter 's' missing from the authentication URL!");
        [self generateInvalidQRCodeError: error];
        return nil;
    }
    NSString *challengeParam = [self getQueryParameter:@"c" fromComponents:components];
    if (!challengeParam) {
        NSLog(@"Required parameter 'c' missing from the authentication URL!");
        [self generateInvalidQRCodeError: error];
        return nil;
    }
    
    challenge.sessionKey = sessionKey;
    challenge.challenge = challengeParam;
    challenge.serviceProviderDisplayName = challenge.identityProvider.displayName;
    challenge.serviceProviderIdentifier = @"";
    
    NSString *protocolVersion = [self getQueryParameter:@"v" fromComponents:components];
    if (!protocolVersion) {
        protocolVersion = @"1";
    }
    challenge.protocolVersion = protocolVersion;
    challenge.returnUrl = nil;
    return challenge;

}

+(BOOL) findIdentityForServerIdentifier:(NSString * _Nonnull)serverIdentifier andUser:(NSString * _Nullable)user forChallenge:(AuthenticationChallenge *)challenge error:(NSError **)error {
    IdentityService *identityService = ServiceContainer.sharedInstance.identityService;
    IdentityProvider *identityProvider = [identityService findIdentityProviderWithIdentifier:serverIdentifier];
    if (identityProvider == nil) {
        [self generateUnknownIdentityError:error];
        return NO;
    }
    if (user) {
        Identity *identity = [identityService findIdentityWithIdentifier:user forIdentityProvider:identityProvider];
        if (identity == nil) {
            [self generateInvalidAccountError:error];
            return NO;
        }
        
        challenge.identities = @[identity];
        challenge.identity = identity;
    } else {
        NSArray *identities = [identityService findIdentitiesForIdentityProvider:identityProvider];
        if (identities == nil || [identities count] == 0) {
            [self generateInvalidAccountError:error];
            return NO;
        }
        
        challenge.identities = identities;
        challenge.identity = [identities count] == 1 ? identities[0] : nil;
    }
    
    if (challenge.identity != nil && [challenge.identity.blocked boolValue]) {
        [self generateAccountBlockedError:error];
        return NO;
    }
    challenge.identityProvider = identityProvider;
    return YES;
}

+ (NSString * _Nullable) getQueryParameter:(NSString * _Nonnull)parameter fromComponents:(NSURLComponents * _Nonnull)components {
    NSPredicate *paramPredicate = [NSPredicate predicateWithFormat:@"name == %@", parameter];
    NSArray<NSURLQueryItem *>* paramItem = [[components queryItems] filteredArrayUsingPredicate: paramPredicate];
    if ([paramItem count] != 1) {
        return nil;
    }
    return [[paramItem objectAtIndex:0] value];
}





@end
