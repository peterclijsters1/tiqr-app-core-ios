//
//  NSString+LocalizedBiometricString.h
//  Tiqr
//
//  Created by Thom Hoekstra on 11/12/2018.
//  Copyright © 2018 Egeniq. All rights reserved.
//

#ifndef NSString_LocalizedBiometricString_h
#define NSString_LocalizedBiometricString_h

#define LocalizedBiometricString(touchIDKey, faceIDKey) \
ServiceContainer.sharedInstance.secretService.biometricType == SecretServiceBiometricTypeFaceID ? [Localization localize:faceIDKey comment:@""] : [Localization localize:touchIDKey comment:@""]


#endif /* NSString_LocalizedBiometricString_h */
