//
//  Created by merowing on 29/04/2013.
//
//
//


#import <Foundation/Foundation.h>

#define KZMap(mapping, property) KZMapT(self, mapping, property)
#define KZProperty(property) KZPropertyT(self, property)

#define KZMapT(target, mapping, property) ({[target property], [KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:@#mapping];})
#define KZPropertyT(target, property) ({[target property], [KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:nil];})


@interface KZPropertyMapper : NSObject
+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping;
+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping errors:(__autoreleasing NSArray**)errors;
@end

@interface KZPropertyMapper (Debug)
+ (void)logIgnoredValues:(BOOL)logIgnoredValues;
@end

@interface KZPropertyDescriptor : NSObject
+ (instancetype)descriptorWithPropertyName:(NSString*)name andMapping:(NSString *)mapping;
- (id)initWithPropertyName:(NSString *)name andMapping:(NSString *)mapping;
- (void)addValidatonWithBlock:(NSError * (^)(id value, NSString *propertyName))validationBlock;
- (void)addValidatorWithName:(NSString *)name validation:(BOOL (^)(id value))validator;
@end