//
//  Created by merowing on 29/04/2013.
//
//
//


#import <Foundation/Foundation.h>

@interface KZPropertyMapper : NSObject
+ (void)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping;
@end

@interface KZPropertyMapper (Debug)
+ (void)logIgnoredValues:(BOOL)logIgnoredValues;
@end
