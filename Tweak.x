#import <Foundation/Foundation.h>
#import <dlfcn.h>

#pragma mark - Headers

@interface TFNTwitterAccount : NSObject
@end

@interface TFNTwitterUser : NSObject
@property(readonly, nonatomic) NSString *username;
@end

@interface TFNTwitterStatus : NSObject
@property(readonly, nonatomic) TFNTwitterStatus *representedStatus;
@property(readonly, nonatomic) NSString *textWithExpandedURLs;
@property(retain, nonatomic) TFNTwitterUser *fromUser;
@end

@interface TFNTwitterComposition : NSObject
@property(nonatomic) NSRange initialSelectedRange;
+ (NSString *)quoteTweetTextForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account;
@end

@interface TFNTwitterCompositionBuilder : NSObject
+ (TFNTwitterComposition *)compositionWithQuoteTweet:(id)arg1 fromAccount:(TFNTwitterAccount *)account;
@end

@interface TFNActionSheetController : NSObject
@property(retain, nonatomic) NSArray *buttons;
@end

@interface TFNActionSheetButton : NSObject
@property(copy, nonatomic) NSString *title;
@property(copy, nonatomic) void (^action)(void);
@property(nonatomic) BOOL delaysAction;
+ (instancetype)buttonWithTitle:(NSString *)title action:(void (^)(void))action;
+ (instancetype)buttonWithTitle:(NSString *)title delayedAction:(void (^)(void))action;
@end

@interface NSString (TFNHTMLEntity)
- (NSString *)stringByUnescapingHTMLEntities;
@end

#pragma mark - Hooks

static BOOL overrideQuoteTweetExperiment;
static NSString *(*TFNLocalizedString)(NSString *key);

%hook TFNTwitterComposition
+ (NSString *)quoteTweetTextForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account {
    NSString *username = status.representedStatus.fromUser.username;
    NSString *statusText = status.textWithExpandedURLs.stringByUnescapingHTMLEntities;
    return [NSString stringWithFormat:@"RT @%@: %@", username, statusText];
}
%end

%hook TFNTwitterCompositionBuilder
+ (TFNTwitterComposition *)compositionWithQuoteTweet:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account {
    TFNTwitterComposition *composition = %orig;
    composition.initialSelectedRange = NSMakeRange(0, 0);
    return composition;
}
%end

%hook TFNTwitterAccount
- (BOOL)isInQuoteTweetComposeExperiment {
    return overrideQuoteTweetExperiment ? NO : %orig;
}
%end

%hook T1TweetContextActions
+ (TFNActionSheetController *)retweetActionSheetForStatus:(TFNTwitterStatus *)status account:(TFNTwitterAccount *)account viewController:(id)viewController source:(id)source scribeParameters:(id)scribeParameters doneBlock:(id)doneBlock willQuoteRetweetBlock:(id)willQuoteRetweetBlock {
    TFNActionSheetController *sheet = %orig;
    NSUInteger quoteTweetIndex = [sheet.buttons indexOfObjectPassingTest:^(TFNActionSheetButton *button, NSUInteger index, BOOL *stop) {
        return [button.title isEqualToString:TFNLocalizedString(@"QUOTE_TWEET_ACTION_LABEL")];
    }];
    if (quoteTweetIndex != NSNotFound) {
        NSMutableArray *buttons = sheet.buttons.mutableCopy;
        TFNActionSheetButton *quoteTweetButton = buttons[quoteTweetIndex];
        TFNActionSheetButton *classicRetweetButton = [%c(TFNActionSheetButton) buttonWithTitle:@"Classic Retweet" action:quoteTweetButton.action ? ^{
            overrideQuoteTweetExperiment = YES;
            quoteTweetButton.action();
            overrideQuoteTweetExperiment = NO;
        } : NULL];
        [buttons insertObject:classicRetweetButton atIndex:quoteTweetIndex + 1];
        sheet.buttons = buttons;
    }
    return sheet;
}
%end

%ctor {
    @autoreleasepool {
        %init;
        TFNLocalizedString = dlsym(RTLD_DEFAULT, "TFNLocalizedString");
    }
}
