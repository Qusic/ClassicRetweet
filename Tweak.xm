#import <Foundation/Foundation.h>

@interface TwitterComposition : NSObject
@property(nonatomic) NSRange initialSelectedRange;
- (id)initWithInitialText:(NSString *)text;
@end

%hook TwitterComposition

- (id)initWithInitialText:(NSString *)text
{
    if([text hasPrefix:@"“"] && [text hasSuffix:@"”"])
    {
        text = [text substringWithRange:NSMakeRange(1, [text length]-2)];
        text = [@" RT " stringByAppendingString:text];
        id r = %orig;
        [r setInitialSelectedRange:NSMakeRange(0,0)];
        return r;
    } else {
        id r = %orig;
        return r;
    }
}

%end
