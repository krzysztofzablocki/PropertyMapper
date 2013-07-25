//
//  Created by merowing on 29/04/2013.
//
//
//


#import <Foundation/Foundation.h>

#ifndef KZPropertyMapperLogIgnoredValues
  #define KZPropertyMapperLogIgnoredValues 1
#endif

@interface KZPropertyMapper : NSObject
+ (void)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping;
@end