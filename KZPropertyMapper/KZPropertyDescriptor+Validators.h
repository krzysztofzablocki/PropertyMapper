//
//  Created by merowing on 08/10/2013.
//
//
//


#import <Foundation/Foundation.h>
#import "KZPropertyDescriptor.h"

@interface KZPropertyDescriptor (Validators)

#pragma mark - Strings
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^isRequired)();
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^lengthRange)(NSInteger min, NSInteger max);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^matchesRegEx)(NSRegularExpression *regularExpression);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^length)(NSUInteger length);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^minLength)(NSInteger min);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^maxLength)(NSInteger max);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^oneOf)(NSArray *items);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^equalTo)(NSString *value);


#pragma mark - Numbers
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^min)(NSInteger min);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^max)(NSInteger max);
@property(nonatomic, copy, readonly) KZPropertyDescriptor *(^range)(NSInteger min, NSInteger max);


@end