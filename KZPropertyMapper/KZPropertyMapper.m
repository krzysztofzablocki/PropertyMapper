//
//  Created by merowing on 29/04/2013.
//
//
//
typedef NS_ENUM(NSInteger, kErrorCode) {
  kErrorCodeInternal = 44324344,
};

NSError *pixle_NSErrorMake(NSString *message, NSUInteger code, NSDictionary *aUserInfo, SEL selector)
{
  NSMutableDictionary *userInfo = [aUserInfo mutableCopy];
  userInfo[NSLocalizedDescriptionKey] = message;
  NSError *error = [NSError errorWithDomain:@"com.pixle.KZPropertyMapper" code:code userInfo:userInfo];

  NSLog(@"KZPropertyMapper Error: %@", error);
  return error;
}

#define AssertTrueOrReturnBlock(condition, block) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { block(pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd)); return;} }while(0)

#define AssertTrueOrReturn(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd); return;} } while(0)

#define AssertTrueOrReturnNilBlock(condition, block) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { block(pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd)); return nil;} } while(0)

#define AssertTrueOrReturnNil(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd); return nil;}} while(0)

#define AssertTrueOrReturnError(condition) do{ NSAssert((condition), @"Invalid condition not satisfying: %s", #condition);\
if(!(condition)) { return pixle_NSErrorMake([NSString stringWithFormat:@"Invalid condition not satisfying: %s", #condition], kErrorCodeInternal, nil, _cmd);} }while(0)


#import "KZPropertyMapper.h"
#import <objc/message.h>

@implementation KZPropertyMapper {
}

+ (void)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping
{
  if ([arrayOrDictionary isKindOfClass:NSDictionary.class]) {
    [self mapValuesFromDictionary:arrayOrDictionary toInstance:instance usingMapping:parameterMapping];
    return;
  }

  if ([arrayOrDictionary isKindOfClass:NSArray.class]) {
    [self mapValuesFromArray:arrayOrDictionary toInstance:instance usingMapping:parameterMapping];
    return;
  }

  AssertTrueOrReturn([arrayOrDictionary isKindOfClass:NSArray.class] || [arrayOrDictionary isKindOfClass:NSDictionary.class]);
}

+ (void)mapValuesFromDictionary:(NSDictionary *)sourceDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping
{
  AssertTrueOrReturn([sourceDictionary isKindOfClass:NSDictionary.class]);

  [sourceDictionary enumerateKeysAndObjectsUsingBlock:^(id property, id value, BOOL *stop) {
    id subMapping = [parameterMapping objectForKey:property];
    [self mapValue:value toInstance:instance usingMapping:subMapping sourcePropertyName:property];
  }];
}

+ (void)mapValuesFromArray:(NSArray *)sourceArray toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping
{
  AssertTrueOrReturn([sourceArray isKindOfClass:NSArray.class]);

  [sourceArray enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
    NSNumber *key = @(idx);
    id subMapping = [parameterMapping objectForKey:key];
    [self mapValue:value toInstance:instance usingMapping:subMapping sourcePropertyName:[NSString stringWithFormat:@"Index %d", key.integerValue]];
  }];
}

+ (void)mapValue:(id)value toInstance:(id)instance usingMapping:(id)mapping sourcePropertyName:(NSString *)propertyName
{
  if ([value isKindOfClass:NSNull.class]) {
    value = nil;
  }

  if ([mapping isKindOfClass:NSDictionary.class] || [mapping isKindOfClass:NSArray.class]) {
    if ([value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSArray.class]) {
      [self mapValuesFrom:value toInstance:instance usingMapping:mapping];
    } else {
#if KZPropertyMapperLogIgnoredValues
      NSLog(@"KZPropertyMapper: Ignoring property %@ as it's not in mapping dictionary", propertyName);
#endif
    }
    return;
  }

  if (!mapping) {
#if KZPropertyMapperLogIgnoredValues
    NSLog(@"KZPropertyMapper: Ignoring value at index %@ as it's not mapped", propertyName);
#endif
    return;
  }

  [self mapValue:value toInstance:instance usingMapping:mapping];
}

+ (void)mapValue:(id)value toInstance:(id)instance usingMapping:(NSString *)mapping
{
  AssertTrueOrReturn([mapping isKindOfClass:NSString.class]);

  //! normal 1 : 1 mapping
  if (![mapping hasPrefix:@"@"]) {
    [self setValue:value withMapping:mapping onInstance:instance];
    return;
  }

  NSArray *components = [mapping componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@()"]];
  AssertTrueOrReturn(components.count == 4);

  NSString *mappingType = [components objectAtIndex:1];
  NSString *boxingParametersString = [components objectAtIndex:2];

  //! extract and cleanup params
  NSArray *boxingParameters = [boxingParametersString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
  
  NSMutableArray *boxingParametersProcessed = [NSMutableArray new];
  [boxingParameters enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop) {
    [boxingParametersProcessed addObject:[param stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
  }];
  boxingParameters = [boxingParametersProcessed copy];
  
  NSString *targetProperty = [boxingParameters lastObject];
  boxingParameters = [boxingParameters subarrayWithRange:NSMakeRange(0, boxingParameters.count - 1)];

  //! We need to handle multiple params boxing as well as normal one
  id boxedValue = nil;
  if (boxingParameters.count > 0) {
    SEL mappingSelector = NSSelectorFromString([NSString stringWithFormat:@"boxValueAs%@OnTarget:value:params:", mappingType]);
    AssertTrueOrReturnBlock([self respondsToSelector:mappingSelector], ^(NSError *error) {
    });
    id (*objc_msgSendTyped)(id, SEL, id, id, NSArray *) = (void*)objc_msgSend;
    boxedValue = objc_msgSendTyped(self, mappingSelector, instance, value, boxingParameters);
  } else {
    SEL mappingSelector = NSSelectorFromString([NSString stringWithFormat:@"boxValueAs%@:", mappingType]);
    AssertTrueOrReturnBlock([self respondsToSelector:mappingSelector], ^(NSError *error) {
    });
    id (*objc_msgSendTyped)(id, SEL, id) = (void*)objc_msgSend;
    boxedValue = objc_msgSendTyped(self, mappingSelector, value);
  }

  if (!boxedValue) {
    return;
  }
  [self setValue:boxedValue withMapping:targetProperty onInstance:instance];
}

+ (void)setValue:(id)value withMapping:(NSString *)mapping onInstance:(id)instance
{
  
  Class coreDataBaseClass = NSClassFromString(@"NSManagedObject");
  if (coreDataBaseClass != nil && [instance isKindOfClass:coreDataBaseClass]) {
    [instance willChangeValueForKey:mapping];
    objc_msgSend(instance, NSSelectorFromString(@"setPrimitiveValue:forKey:"), value, mapping);
    [instance didChangeValueForKey:mapping];
  } else {
    [instance setValue:value forKey:mapping];
  }
}
#pragma mark - Dynamic boxing

+ (NSURL *)boxValueAsURL:(id)value __unused
{
  if(value == nil){
    return nil;
  }
  AssertTrueOrReturnNil([value isKindOfClass:NSString.class]);
  return [NSURL URLWithString:value];
}

+ (NSDate *)boxValueAsDate:(id)value __unused
{
  if(value == nil){
    return nil;
  }
  AssertTrueOrReturnNil([value isKindOfClass:NSString.class]);
  return [[self dateFormatter] dateFromString:value];
}

+ (NSDateFormatter *)dateFormatter
{
  static NSDateFormatter *df = nil;
  if (df == nil) {
    df = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [df setLocale:locale];
  }
  return df;
}

+ (id)boxValueAsSelectorOnTarget:(id)target value:(id)value params:(NSArray *)params __unused
{
  AssertTrueOrReturnNil(params.count == 1);
  SEL selector = NSSelectorFromString([params objectAtIndex:0]);

  AssertTrueOrReturnNil([target respondsToSelector:selector]);
  id (*objc_msgSendTyped)(id, SEL, id) = (void*)objc_msgSend;
  return objc_msgSendTyped(target, selector, value);
}

@end
