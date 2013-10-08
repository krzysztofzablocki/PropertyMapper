//
//  Created by merowing on 08/10/2013.
//
//
//


#import <Foundation/Foundation.h>
#import "KZPropertyMapper.h"

@interface KZPropertyDescriptor (Validators)

#pragma mark - Strings
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^isRequired)();
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^lengthRange)(NSUInteger min, NSUInteger max);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^matchesRegEx)(NSRegularExpression *regularExpression);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^length)(NSUInteger length);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^minLength)(NSUInteger min);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^maxLength)(NSUInteger max);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^oneOf)(NSArray *items);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^equalTo)(NSString *value);


#pragma mark - Numbers
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^min)(NSUInteger min);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^max)(NSUInteger max);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^range)(NSUInteger min, NSUInteger max);


@end