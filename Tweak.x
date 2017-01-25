#import <Foundation/Foundation.h>

#pragma mark - Headers

@interface TFNTwitterAccount : NSObject
@end

@interface TFNTwitterUser : NSObject
@property(readonly) NSString *username;
@end

@interface TFNTwitterUserReference : NSObject
@property(readonly) NSString *username;
@end

@interface TFNTwitterStatus : NSObject
@property(retain) TFNTwitterUser *fromUser;
@property(readonly) TFNTwitterStatus *representedStatus;
@property(readonly) NSString *textWithExpandedURLs;
@end

@interface TFNTwitterComposition : NSObject
@property(retain) TFNTwitterStatus *replyToStatus;
@property(retain) TFNTwitterStatus *quotedStatus;
@property(retain) TFNTwitterUserReference *replyToUserReference;
@property(retain) NSString *replyPlaceholderText;
@property(assign) NSRange initialSelectedRange;
+ (NSString *)quoteTweetTextForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account;
+ (NSString *)replyAllTextForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account getReplyToUserReference:(TFNTwitterUserReference **)reference initialSelectionRange:(NSRange **)selectionRange;
+ (NSString *)replyAllPlaceholderForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account;
- (instancetype)initWithInitialText:(NSString *)initialText;
@end

@interface TFNTwitterCompositionBuilder : NSObject
+ (TFNTwitterComposition *)compositionForReplyToTweet:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account;
+ (TFNTwitterComposition *)compositionWithQuoteTweet:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account;
@end

@interface TFNActionSheetController : NSObject
@property(retain) NSArray *actionItems;
@end

@interface TFNActionItem : NSObject
@property(copy) NSString *title;
@property(copy) void (^action)(void);
+ (instancetype)actionItemWithTitle:(NSString *)title action:(void (^)(void))action;
+ (instancetype)cancelActionItemWithTitle:(NSString *)title action:(void (^)(void))action;
+ (instancetype)destructiveActionItemWithTitle:(NSString *)title action:(void (^)(void))action;
@end

@interface TFSLocalized : NSObject
+ (NSString *)localizedString:(NSString *)string;
@end

@interface NSString (TFNHTMLEntity)
- (NSString *)tfs_stringByUnescapingHTMLEntities;
@end

#pragma mark - Hooks

static BOOL isClassicRetweet;

%hook TFNTwitterComposition
+ (NSString *)quoteTweetTextForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account {
    NSString *username = status.representedStatus.fromUser.username;
    NSString *statusText = status.textWithExpandedURLs.tfs_stringByUnescapingHTMLEntities;
    return [NSString stringWithFormat:@"RT @%@: %@", username, statusText];
}
%end

%hook TFNTwitterCompositionBuilder
+ (TFNTwitterComposition *)compositionWithQuoteTweet:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account {
    if (isClassicRetweet) {
        NSString *initialText = [%c(TFNTwitterComposition) quoteTweetTextForStatus:status fromAccount:account];
        NSString *placeholder = [%c(TFNTwitterComposition) replyAllPlaceholderForStatus:status fromAccount:account];
        TFNTwitterUserReference *userReference = nil;
        [%c(TFNTwitterComposition) replyAllTextForStatus:status fromAccount:account getReplyToUserReference:&userReference initialSelectionRange:NULL];
        TFNTwitterComposition *composition = [[%c(TFNTwitterComposition) alloc]initWithInitialText:initialText];
        composition.replyToStatus = status.representedStatus;
        composition.replyToUserReference = userReference;
        composition.replyPlaceholderText = placeholder;
        composition.initialSelectedRange = NSMakeRange(0, 0);
        return composition;
    } else {
        return %orig;
    }
}
%end

%hook UIViewController
- (TFNActionSheetController *)t1_retweetActionSheetForStatus:(TFNTwitterStatus *)status account:(TFNTwitterAccount *)account source:(id)source scribeParameters:(id)scribeParameters willQuoteRetweetBlock:(id)willQuoteRetweetBlock doneBlock:(id)doneBlock {
    TFNActionSheetController *sheet = %orig;
    NSUInteger quoteTweetIndex = [sheet.actionItems indexOfObjectPassingTest:^(TFNActionItem *actionItem, NSUInteger index, BOOL *stop) {
        return [actionItem.title isEqualToString:[%c(TFSLocalized) localizedString:@"QUOTE_TWEET_ACTION_LABEL"]];
    }];
    if (quoteTweetIndex != NSNotFound) {
        NSMutableArray *actionItems = sheet.actionItems.mutableCopy;
        TFNActionItem *quoteTweetItem = actionItems[quoteTweetIndex];
        TFNActionItem *classicRetweetItem = [%c(TFNActionItem) actionItemWithTitle:@"Classic Retweet" action:quoteTweetItem.action ? ^{
            isClassicRetweet = YES;
            quoteTweetItem.action();
            isClassicRetweet = NO;
        } : NULL];
        [actionItems insertObject:classicRetweetItem atIndex:quoteTweetIndex + 1];
        sheet.actionItems = actionItems;
    }
    return sheet;
}
%end

