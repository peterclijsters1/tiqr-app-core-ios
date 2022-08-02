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

#import "TiqrConfig.h"

@interface TiqrConfig()

@end

@implementation TiqrConfig

+ (NSString *)valueForKey:(NSString *)string {
    NSString *path = [SWIFTPM_MODULE_BUNDLE pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    NSString *value = [dictionary objectForKey:string];
    
    return value;
}

+ (BOOL)isValidAuthenticationURL:(NSString *)url {
    NSString *authenticationSchemeKey = @"TIQRAuthenticationURLScheme";
    NSString *appScheme = [[[NSBundle mainBundle] infoDictionary] objectForKey:authenticationSchemeKey];
    NSURLComponents *components = [NSURLComponents componentsWithURL: [NSURL URLWithString:url] resolvingAgainstBaseURL:NO];
    // Old format: URL starts with custom scheme
    if (appScheme && [appScheme isEqualToString: [components scheme]]) {
        return true;
    }
    // New format: URL scheme, and special path parameter
    NSString *authenticationPathParameterKey = @"TIQRAuthenticationURLPathParameter";
    NSString *authenticationPathParameter = [[[NSBundle mainBundle] infoDictionary] objectForKey:authenticationPathParameterKey];
    // If the path parameter does not start with a slash, we add it
    if (![authenticationPathParameter hasPrefix:@"/"]) {
        authenticationPathParameter = [NSString stringWithFormat:@"/%@", authenticationPathParameter];
    }
    if (authenticationPathParameter &&
        [url hasPrefix:@"https://"]) {
        if (!([[components path] isEqualToString: authenticationPathParameter])) {
            NSLog(@"Authentication URL is not valid because the path parameter does not match. Path of the URL: %@, expected path: %@", [components path], authenticationPathParameter);
            return false;
        }
        // Check for all the required parameters
        NSArray<NSString *>* requiredParams = @[@"q", @"s", @"i"];
        for(id param in requiredParams) {
            NSPredicate *paramPredicate = [NSPredicate predicateWithFormat:@"name == %@", param];
            NSArray<NSURLQueryItem *>* paramItem = [[components queryItems] filteredArrayUsingPredicate: paramPredicate];
            if ([paramItem count] != 1) {
                NSLog(@"Authentication URL did not contain the following required query parameter: '%@'!", param);
                return false;
            }
        }
        // Enforce host check
        NSString *enforceChallengeHostsKey = @"TIQREnforceChallengeHosts";
        NSString *enforceChallengeHosts = [[[NSBundle mainBundle] infoDictionary] objectForKey:enforceChallengeHostsKey];
        if (enforceChallengeHosts && enforceChallengeHosts.length > 0) {
            NSString* host = [components host];
            bool validHost = false;
            for (NSString *enforcedHost in [enforceChallengeHosts componentsSeparatedByString:@","]) {
                NSString *enforcedHostWithSubdomain = [NSString stringWithFormat:@".%@", enforcedHost];
                if ([host isEqualToString: enforcedHost] ||
                    [host hasSuffix: enforcedHostWithSubdomain]) {
                    NSLog(@"Authentication URL host is valid.");
                    validHost = true;
                }
            }
            if (!validHost) {
                NSLog(@"Authentication URL is not valid because host is not allowed. Host of the URL: %@, allowed hosts: %@", host, enforceChallengeHosts);
                return false;
            }
        }
        return true;
    }
    // HTTPS URL but no path parameter supplied, so we don't support it at all
    return false;
}

+ (BOOL)isValidEnrollmentURL:(NSString *)url {
    NSString *enrollmentSchemeKey = @"TIQREnrollmentURLScheme";
    NSString *appScheme = [[[NSBundle mainBundle] infoDictionary] objectForKey:enrollmentSchemeKey];
    NSURLComponents *components = [NSURLComponents componentsWithURL: [NSURL URLWithString:url] resolvingAgainstBaseURL:NO];
    // Old format: URL starts with custom scheme
    if (appScheme && [appScheme isEqualToString: [components scheme]]) {
        return true;
    }
    // New format: URL scheme, and special path parameter
    NSString *enrollmentPathParameterKey = @"TIQREnrollmentURLPathParameter";
    NSString *enrollmentPathParameter = [[[NSBundle mainBundle] infoDictionary] objectForKey:enrollmentPathParameterKey];
    // If the path parameter does not start with a slash, we add it
    if (![enrollmentPathParameter hasPrefix:@"/"]) {
        enrollmentPathParameter = [NSString stringWithFormat:@"/%@", enrollmentPathParameter];
    }
    if (enrollmentPathParameter &&
        [url hasPrefix:@"https://"]) {
        if (!([[components path] isEqualToString: enrollmentPathParameter])) {
            NSLog(@"Enrollment URL is not valid because the path parameter does not match. Path of the URL: %@, expected path: %@", [components path], enrollmentPathParameter);
            return false;
        }
        // Metadata is a required parameter
        NSPredicate *metadataPredicate = [NSPredicate predicateWithFormat:@"name == %@", @"metadata"];
        NSArray<NSURLQueryItem *>* metadataItem = [[components queryItems] filteredArrayUsingPredicate: metadataPredicate];
        if ([metadataItem count] != 1) {
            NSLog(@"Enrollment URL did not contain metadata query item!");
            return false;
        }
        NSString* metadataURLString = [[metadataItem objectAtIndex:0] value];
        NSURL* metadataURL = [NSURL URLWithString:metadataURLString];
        if (!metadataURL) {
            NSLog(@"Enrollment URL metadata parameter is not a valid URL!");
            return false;
        }
        // Enforce host check
        NSString *enforceChallengeHostsKey = @"TIQREnforceChallengeHosts";
        NSString *enforceChallengeHosts = [[[NSBundle mainBundle] infoDictionary] objectForKey:enforceChallengeHostsKey];
        if (enforceChallengeHosts && enforceChallengeHosts.length > 0) {
            NSString* host = [components host];
            bool validHost = false;
            for (NSString *enforcedHost in [enforceChallengeHosts componentsSeparatedByString:@","]) {
                NSString *enforcedHostWithSubdomain = [NSString stringWithFormat:@".%@", enforcedHost];
                if ([host isEqualToString: enforcedHost] ||
                    [[host lowercaseString] rangeOfString:enforcedHostWithSubdomain].location != NSNotFound) {
                    NSLog(@"Enrollment URL host is valid.");
                    validHost = true;
                }
            }
            if (!validHost) {
                NSLog(@"Enrollment URL is not valid because host is not allowed. Host of the URL: %@, allowed hosts: %@", host, enforceChallengeHosts);
                return false;
            }
            // We also need to validate the metadata URL host
            NSString* metadataURLHost = [metadataURL host];
            bool validMetadataHost = false;
            for (NSString *enforcedHost in [enforceChallengeHosts componentsSeparatedByString:@","]) {
                NSString *enforcedHostWithSubdomain = [NSString stringWithFormat:@".%@", enforcedHost];
                if ([metadataURLHost isEqualToString: enforcedHost] ||
                    [[metadataURLHost lowercaseString] rangeOfString:enforcedHostWithSubdomain].location != NSNotFound) {
                    NSLog(@"Enrollment metadata URL host is valid.");
                    validMetadataHost = true;
                }
            }
            if (!validMetadataHost) {
                NSLog(@"Enrollment metadata URL is not valid because host is not allowed. Host of the URL: %@, allowed hosts: %@", metadataURLHost, enforceChallengeHosts);
                return false;
            }
        }
        
        return true;
    }
    // HTTPS URL but no path parameter supplied, so we don't support it at all
    return false;
}

+ (NSString *)appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

+ (NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

@end
