//
//  Created by merowing on 29/04/2013.
//
//
//


#import <Foundation/Foundation.h>
#import "KZPropertyDescriptor.h"

#define KZBox(mapping, property) KZBoxT(self, mapping, property)
#define KZProperty(property) KZPropertyT(self, property)
#define KZCall(method, property) KZCallT(self, method, property)

#ifdef KZPropertyMapperDisableCompileTimeChecking
  #define KZBoxT(target, mapping, property) ({[KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:@#mapping];})
  #define KZPropertyT(target, property) ({[KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:nil];})
  #define KZCallT(target, method, property) ({[KZPropertyDescriptor descriptorWithPropertyName:@#property selector:@selector(method)];})
#else
  #define KZBoxT(target, mapping, property) ({[target property], [KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:@#mapping];})
  #define KZPropertyT(target, property) ({[target property], [KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:nil];})
  #define KZCallT(target, method, property) ({[target property], [KZPropertyDescriptor descriptorWithPropertyName:@#property selector:@selector(method)];})
#endif

@interface KZPropertyMapper : NSObject
+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping;

+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping errors:(__autoreleasing NSArray **)errors;
@end

@interface KZPropertyMapper (Debug)
+ (void)logIgnoredValues:(BOOL)logIgnoredValues;
@end
