#import <Foundation/Foundation.h>

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

@interface NSString (TFNHTMLEntity)
- (NSString *)stringByUnescapingHTMLEntities;
@end

#pragma mark - Hooks

%hook TFNTwitterComposition
+ (NSString *)quoteTweetTextForStatus:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account
{
    NSString *username = status.representedStatus.fromUser.username;
    NSString *statusText = status.textWithExpandedURLs.stringByUnescapingHTMLEntities;
    return [NSString stringWithFormat:@"RT @%@: %@", username, statusText];
}
%end

%hook TFNTwitterCompositionBuilder
+ (TFNTwitterComposition *)compositionWithQuoteTweet:(TFNTwitterStatus *)status fromAccount:(TFNTwitterAccount *)account
{
    TFNTwitterComposition *composition = %orig;
    composition.initialSelectedRange = NSMakeRange(0, 0);
    return composition;
}
%end