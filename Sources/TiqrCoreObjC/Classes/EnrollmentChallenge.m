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

#import "EnrollmentChallenge.h"
#import "NSString+DecodeURL.h"
#import "ServiceContainer.h"
#import "TiqrConfig.h"
@import TiqrCore;

NSString *const TIQRECErrorDomain = @"org.tiqr.ec";

@interface EnrollmentChallenge ()

@property (nonatomic, copy) NSString *identityProviderIdentifier;
@property (nonatomic, copy) NSString *identityProviderDisplayName;
@property (nonatomic, copy) NSString *identityProviderAuthenticationUrl;
@property (nonatomic, copy) NSString *identityProviderInfoUrl;
@property (nonatomic, copy) NSString *identityProviderOcraSuite;
@property (nonatomic, copy) NSData *identityProviderLogo;

@property (nonatomic, copy) NSString *identityIdentifier;
@property (nonatomic, copy) NSString *identityDisplayName;

@property (nonatomic, copy) NSString *enrollmentUrl;
@property (nonatomic, copy) NSString *returnUrl;

@end

@implementation EnrollmentChallenge

+ (BOOL)applyError:(NSError *)error toError:(NSError **)otherError {
    if (otherError != NULL) {
        *otherError = error;
    }
    
    return YES;
}

+ (void)generateInvalidQRCodeError:(NSError **)error {
    NSString *errorTitle = [Localization localize:@"error_enroll_invalid_qr_code" comment:@"Invalid QR tag title"];
    NSString *errorMessage = [Localization localize:@"error_enroll_invalid_response" comment:@"Invalid QR tag message"];
    NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
    [self applyError:[NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidQRTagError userInfo:details] toError:error];
}

+ (EnrollmentChallenge *)challengeWithChallengeString:(NSString *)challengeString allowFiles:(BOOL)allowFiles error:(NSError **)error {
    NSURL *fullURL = [NSURL URLWithString:challengeString];
    
    EnrollmentChallenge *challenge = [[EnrollmentChallenge alloc] init];
    
    if (fullURL == nil || ![TiqrConfig isValidEnrollmentURL:challengeString]) {
        [self generateInvalidQRCodeError: error];
        return nil;
    }
    
    NSURL *metadataURL;
    
    if ([fullURL.scheme isEqualToString:@"https"]) {
        // New format URL
        NSURLComponents *components = [NSURLComponents componentsWithURL:fullURL resolvingAgainstBaseURL:NO];
        NSPredicate *metadataPredicate = [NSPredicate predicateWithFormat:@"name == %@", @"metadata"];
        NSArray<NSURLQueryItem *>* metadataItem = [[components queryItems] filteredArrayUsingPredicate: metadataPredicate];
        if ([metadataItem count] != 1) {
            NSLog(@"Enrollment URL did not contain metadata query item!");
            [self generateInvalidQRCodeError: error];
            return nil;
        }
        NSString *metadataURLString = [[metadataItem objectAtIndex:0] value];
        metadataURL = [NSURL URLWithString: metadataURLString];
        if (!metadataURL) {
            NSLog(@"Enrollment URL metadata parameter is not a valid URL!");
            [self generateInvalidQRCodeError: error];
            return nil;
        }
    } else {
        // Old format URL
        NSString *enrollmentSchemeKey = @"TIQREnrollmentURLScheme";
        NSString *enrollmentScheme = [[[NSBundle mainBundle] infoDictionary] objectForKey:enrollmentSchemeKey];
        int startIndex = enrollmentScheme.length + 3 // +3 for the ://
        // Remove the custom scheme to get the metadata URL
        metadataURL = [NSURL URLWithString:[challengeString substringFromIndex:startIndex]];
        if (metadataURL == nil) {
            [self generateInvalidQRCodeError: error];
            return nil;
        }
        
        if (![metadataURL.scheme isEqualToString:@"http"] && ![metadataURL.scheme isEqualToString:@"https"] && ![metadataURL.scheme isEqualToString:@"file"]) {
            [self generateInvalidQRCodeError: error];
            return nil;
        } else if ([metadataURL.scheme isEqualToString:@"file"] && !allowFiles) {
            [self generateInvalidQRCodeError: error];
            return nil;
        }
    }
    
    
    NSError *downloadError = nil;
    NSData *data = [challenge downloadSynchronously:metadataURL error:&downloadError];
    if (downloadError != nil) {
        NSString *errorTitle = [Localization localize:@"no_connection" comment:@"No connection title"];
        NSString *errorMessage = [Localization localize:@"internet_connection_required" comment:@"You need an Internet connection to activate your account. Please try again later."];
        NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage, NSUnderlyingErrorKey: downloadError};
        [self applyError:[NSError errorWithDomain:TIQRECErrorDomain code:TIQRECConnectionError userInfo:details] toError:error];
        return nil;
    }
    
    NSDictionary *metadata = nil;
    
    @try {
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([object isKindOfClass:[NSDictionary class]]) {
            metadata = object;
        }
    } @catch (NSException *exception) {
        metadata = nil;
    }
    
    if (metadata == nil || ![challenge isValidMetadata:metadata]) {
        NSString *errorTitle = [Localization localize:@"error_enroll_invalid_response_title" comment:@"Invalid response title"];
        NSString *errorMessage = [Localization localize:@"error_enroll_invalid_response" comment:@"Invalid response message"];
        NSDictionary *details;
        details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
        [self applyError:[NSError errorWithDomain:TIQRECErrorDomain code:TIQRECInvalidResponseError userInfo:details] toError:error];
        return nil;
    }
    
    NSMutableDictionary *identityProviderMetadata = [NSMutableDictionary dictionaryWithDictionary:metadata[@"service"]];
    
    [self applyError:[challenge assignIdentityProviderMetadata:identityProviderMetadata] toError:error];
    if (*error) {
        return nil;
    }
    
    NSDictionary *identityMetadata = metadata[@"identity"];
    NSError *assignError = [challenge assignIdentityMetadata:identityMetadata];
    if (assignError) {
       [self applyError:assignError toError:error];
        return nil;
    }
    
    NSString *regex = @"^http(s)?://.*";
    NSPredicate *protocolPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    if (metadataURL.query != nil && [metadataURL.query length] > 0 && [protocolPredicate evaluateWithObject:metadataURL.query] == YES) {
        challenge.returnUrl = metadataURL.query.decodedURL;
    } else {
        challenge.returnUrl = nil;
    }
    
    challenge.returnUrl = nil; // TODO: support return URL metadataURL.query == nil || [metadataURL.query length] == 0 ? nil : metadataURL.query;
    challenge.enrollmentUrl = [identityProviderMetadata[@"enrollmentUrl"] description];
    
    return challenge;
    
}

- (BOOL)isValidMetadata:(NSDictionary *)metadata {
    // TODO: service => identityProvider 
	if ([metadata valueForKey:@"service"] == nil ||
		[metadata valueForKey:@"identity"] == nil) {
		return NO;
	}

	// TODO: improve validation
    
	return YES;
}

- (NSData *)downloadSynchronously:(NSURL *)url error:(NSError **)error {
	NSURLResponse *response = nil;
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[TiqrUserAgent getUserAgent] forHTTPHeaderField:@"User-Agent"];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	return data;
}

- (NSError *)assignIdentityProviderMetadata:(NSDictionary *)metadata {
	self.identityProviderIdentifier = [metadata[@"identifier"] description];
	self.identityProvider = [ServiceContainer.sharedInstance.identityService findIdentityProviderWithIdentifier:self.identityProviderIdentifier];

	if (self.identityProvider != nil) {
		self.identityProviderDisplayName = self.identityProvider.displayName;
		self.identityProviderAuthenticationUrl = self.identityProvider.authenticationUrl;	
        self.identityProviderOcraSuite = self.identityProvider.ocraSuite;
		self.identityProviderLogo = self.identityProvider.logo;
	} else {
		NSURL *logoUrl = [NSURL URLWithString:[metadata[@"logoUrl"] description]];		
		NSError *error = nil;		
		NSData *logo = [self downloadSynchronously:logoUrl error:&error];
		if (error != nil) {
            NSString *errorTitle = [Localization localize:@"error_enroll_logo_error_title" comment:@"No identity provider logo"];
            NSString *errorMessage = [Localization localize:@"error_enroll_logo_error" comment:@"No identity provider logo message"];
            NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage, NSUnderlyingErrorKey: error};
            return [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECIdentityProviderLogoError userInfo:details];
		}
		
		self.identityProviderDisplayName =  [metadata[@"displayName"] description];
		self.identityProviderAuthenticationUrl = [metadata[@"authenticationUrl"] description];	
		self.identityProviderInfoUrl = [metadata[@"infoUrl"] description];        
        self.identityProviderOcraSuite = [metadata[@"ocraSuite"] description];
		self.identityProviderLogo = logo;
	}	
	
	return nil;
}

- (NSError *)assignIdentityMetadata:(NSDictionary *)metadata {
	self.identityIdentifier = [metadata[@"identifier"] description];
	self.identityDisplayName = [metadata[@"displayName"] description];
	self.identitySecret = nil;
	
	if (self.identityProvider != nil) {
        Identity *identity = [ServiceContainer.sharedInstance.identityService findIdentityWithIdentifier:self.identityIdentifier forIdentityProvider:self.identityProvider];
		if (identity != nil && [identity.blocked boolValue]) {
            self.identity = identity;
        } else if (identity != nil) {
            NSString *errorTitle = [Localization localize:@"error_enroll_already_enrolled_title" comment:@"Account already activated"];
            NSString *errorMessage = [NSString stringWithFormat:[Localization localize:@"error_enroll_already_enrolled" comment:@"Account already activated message"], self.identityDisplayName, self.identityProviderDisplayName];
            NSDictionary *details = @{NSLocalizedDescriptionKey: errorTitle, NSLocalizedFailureReasonErrorKey: errorMessage};
            return [NSError errorWithDomain:TIQRECErrorDomain code:TIQRECAccountAlreadyExistsError userInfo:details];
		}
	}
								 
	return nil;
}


@end
