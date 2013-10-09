//
//  Created by merowing on 08/10/2013.
//
//
//

typedef NS_ENUM(NSInteger, kErrorCode) {
  kErrorCodeInternal = 44324344,
};

extern NSError *pixle_NSErrorMake(NSString *message, NSUInteger code, NSDictionary *aUserInfo, SEL selector);

#define AssertTrueOrReturnNoBlock(condition, block) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { block(pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd)); return NO;} }while(0)

#define AssertTrueOrReturnNo(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd); return NO;} } while(0)

#define AssertTrueOrReturn(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd); return;} } while(0)

#define AssertTrueOrReturnNil(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd); return nil;}} while(0)

#define AssertTrueOrReturnErrors(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { return @[pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd)];} }while(0)
