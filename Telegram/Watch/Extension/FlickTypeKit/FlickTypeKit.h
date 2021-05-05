//
//  FlickTypeKit.h
//  FlickTypeKit
//
//  Created by Kosta Eleftheriou on 5/3/21.
//  Copyright © 2021 Kpaw. All rights reserved.
//

#import <WatchKit/WatchKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FlickTypeMode) {
    FlickTypeModeAsk,
    FlickTypeModeAlways,
    FlickTypeModeOff
};

typedef NS_ENUM(NSInteger, FlickTypeCompletionType) {
    FlickTypeCompletionTypeDismiss,
    FlickTypeCompletionTypeAction,
};

@interface FlickType : NSObject

// eg "https://www.my-app.com/flicktype"
@property (class) NSURL* returnURL;

// Returns true if it was a FlickType response activity
+ (BOOL)handle:(NSUserActivity*)userActivity;

@end

@interface WKInterfaceController (FlickType)

- (void)presentTextInputControllerWithSuggestions:(nullable NSArray<NSString*> *)suggestions allowedInputMode:(WKTextInputMode)inputMode flickType:(FlickTypeMode)flickTypeMode completion:(void(^)(NSArray * __nullable results))completion; // results is nil if cancelled

- (void)presentTextInputControllerWithSuggestionsForLanguage:(NSArray * __nullable (^ __nullable)(NSString *inputLanguage))suggestionsHandler allowedInputMode:(WKTextInputMode)inputMode  flickType:(FlickTypeMode)flickTypeMode completion:(void(^)(NSArray * __nullable results))completion; // will never go straight to dictation because allows for switching input language

@end

NS_ASSUME_NONNULL_END
