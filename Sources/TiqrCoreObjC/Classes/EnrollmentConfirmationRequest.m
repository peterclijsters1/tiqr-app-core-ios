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

#import "EnrollmentConfirmationRequest.h"
#import "NotificationRegistration.h"
#import "NSData+Hex.h"
#import "TiqrConfig.h"
@import TiqrCore;

NSString *const TIQRECRErrorDomain = @"org.tiqr.ecr";

typedef void (^CompletionBlock)(BOOL success, NSError *error);

@interface EnrollmentConfirmationRequest ()

@property (nonatomic, strong) EnrollmentChallenge *challenge;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) NSString *protocolVersion;
@property (nonatomic, strong) NSURLConnection *sendConnection;
@property (nonatomic, strong) CompletionBlock completionBlock;

@end

@implementation EnrollmentConfirmationRequest

- (instancetype)initWithEnrollmentChallenge:(EnrollmentChallenge *)challenge {
    self = [super init];
    if (self != nil) {
        self.challenge = challenge;
    }
    
    return self;
}

- (void)sendWithCompletionHandler:(void (^)(BOOL, NSError *))completionHandler {
    self.completionBlock = completionHandler;

	NSString *secret = [self.challenge.identitySecret hexStringValue];
	NSString *escapedSecret = [secret stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *escapedLanguage = [[NSLocale preferredLanguages][0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *notificationToken = [NotificationRegistration sharedInstance].notificationToken;
	NSString *escapedNotificationToken = [notificationToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *version = [TiqrConfig valueForKey:@"TIQRProtocolVersion"];
    NSString *operation = @"register";
    NSString *notificationType = [NotificationRegistration sharedInstance].notificationType;
    NSString *escapedNotificationType = [notificationType stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *body = [NSString stringWithFormat:@"secret=%@&language=%@&notificationType=%@&notificationAddress=%@&version=%@&operation=%@", escapedSecret, escapedLanguage, escapedNotificationType, escapedNotificationToken, version, operation];
    
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.challenge.enrollmentUrl]];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
	[request setTimeoutInterval:5.0];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[TiqrUserAgent getUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:version forHTTPHeaderField:@"X-TIQR-Protocol-Version"];

    self.sendConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.data setLength:0];
    
    NSDictionary* headers = [(NSHTTPURLResponse *)response allHeaderFields];
    if (headers[@"X-TIQR-Protocol-Version"]) {
        self.protocolVersion = headers[@"X-TIQR-Protocol-Version"];
    } else {
        self.protocolVersion = @"1";
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError {
    self.data = nil;
    
    NSString *title = [Localization localize:@"no_connection" comment:@"No connection error title"];
    NSString *message = [Localization localize:@"internet_connection_required" comment:@"No connection error message"];
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue:title forKey:NSLocalizedDescriptionKey];
    [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];    
    [details setValue:connectionError forKey:NSUnderlyingErrorKey];
    
    NSError *error = [NSError errorWithDomain:TIQRECRErrorDomain code:TIQRECRConnectionError userInfo:details];
    
    self.completionBlock(NO, error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.protocolVersion != nil && [self.protocolVersion intValue] >= 2) {
        // Parse the JSON result
        id result = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:nil];
        self.data = nil;
        
        NSNumber *responseCode = @([[result valueForKey:@"responseCode"] intValue]);
        if ([responseCode intValue] == EnrollmentChallengeResponseCodeSuccess) {
            self.completionBlock(YES, nil);
        } else {
            NSString *title = [Localization localize:@"enroll_error_title" comment:@"Enrollment error title"];
            NSString *message = nil;
            NSString *serverMessage = [result valueForKey:@"message"];
            if (serverMessage) {
                message = serverMessage;
            } else {
                message = [Localization localize:@"unknown_enroll_error_message" comment:@"Unknown error message"];
            }
            
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
            [details setValue:title forKey:NSLocalizedDescriptionKey];
            [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];
            
            NSError *error = [NSError errorWithDomain:TIQRECRErrorDomain code:TIQRECRUnknownError userInfo:details];
            self.completionBlock(NO, error);
        }
    } else {
        // Parse string result
        NSString *response = [[NSString alloc] initWithBytes:[self.data bytes] length:[self.data length] encoding:NSUTF8StringEncoding];
        self.data = nil;
        if ([response isEqualToString:@"OK"]) {
            self.completionBlock(YES, nil);
        } else {
            // TODO: server should return different error codes
            NSString *title = [Localization localize:@"unknown_error" comment:@"Unknown error title"];
            NSString *message = [Localization localize:@"unknown_enroll_error_message" comment:@"Unknown error message"];
            
            NSMutableDictionary *details = [NSMutableDictionary dictionary];
            [details setValue:title forKey:NSLocalizedDescriptionKey];
            [details setValue:message forKey:NSLocalizedFailureReasonErrorKey];
            
            NSError *error = [NSError errorWithDomain:TIQRECRErrorDomain code:TIQRECRUnknownError userInfo:details];
            self.completionBlock(NO, error);
        }
        
    }
    
}

@end
