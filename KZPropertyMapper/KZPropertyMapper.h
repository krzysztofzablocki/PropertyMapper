//
//  Created by merowing on 29/04/2013.
//
//
//


#import <Foundation/Foundation.h>

#define KZMap(mapping, property) ({self.property, [KZPropertyDescriptor descriptorWithPropertyName:@#property andMapping:@#mapping];})
#define KZProperty(property) ({self.property, [NSString stringWithCString:#property encoding:NSUTF8StringEncoding];})


@interface KZPropertyMapper : NSObject
+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping;
@end

@interface KZPropertyMapper (Debug)
+ (void)logIgnoredValues:(BOOL)logIgnoredValues;
@end

@interface KZPropertyDescriptor : NSObject
@property (nonatomic, copy, readonly) KZPropertyDescriptor* (^isRequired)();

+ (instancetype)descriptorWithPropertyName:(NSString*)name andMapping:(NSString *)mapping;
- (id)initWithPropertyName:(NSString *)name andMapping:(NSString *)mapping;
@end