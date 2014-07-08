//
//  Created by merowing on 29/04/2013.
//
//
//

#import "KZPropertyMapper.h"
#import <objc/message.h>
#import "KZPropertyMapperCommon.h"
#import "KZPropertyDescriptor.h"
#import <CoreData/CoreData.h>

@implementation KZPropertyMapper {
}

+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping
{
  return [self mapValuesFrom:arrayOrDictionary toInstance:instance usingMapping:parameterMapping errors:nil];
}

+ (BOOL)mapValuesFrom:(id)arrayOrDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping errors:(__autoreleasing NSArray **)oErrors
{
  NSArray *errors = [self validateMapping:parameterMapping withValues:arrayOrDictionary];
  if (errors.count > 0) {
    if (oErrors) {
      *oErrors = errors;
    }
    return NO;
  }

  if ([arrayOrDictionary isKindOfClass:NSDictionary.class]) {
    return [self mapValuesFromDictionary:arrayOrDictionary toInstance:instance usingMapping:parameterMapping];
  }

  if ([arrayOrDictionary isKindOfClass:NSArray.class]) {
    return [self mapValuesFromArray:arrayOrDictionary toInstance:instance usingMapping:parameterMapping];
  }

  AssertTrueOrReturnNo([arrayOrDictionary isKindOfClass:NSArray.class] || [arrayOrDictionary isKindOfClass:NSDictionary.class]);
  return YES;
}

+ (BOOL)mapValuesFromDictionary:(NSDictionary *)sourceDictionary toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping
{
  AssertTrueOrReturnNo([sourceDictionary isKindOfClass:NSDictionary.class]);
  __block BOOL isValid = YES;
  [sourceDictionary enumerateKeysAndObjectsUsingBlock:^(id property, id value, BOOL *stop) {
    id subMapping = [parameterMapping objectForKey:property];
    isValid = [self mapValue:value toInstance:instance usingMapping:subMapping sourcePropertyName:property] && isValid;
  }];
  return isValid;
}

+ (BOOL)mapValuesFromArray:(NSArray *)sourceArray toInstance:(id)instance usingMapping:(NSDictionary *)parameterMapping
{
  AssertTrueOrReturnNo([sourceArray isKindOfClass:NSArray.class]);
  __block BOOL isValid = YES;
  [sourceArray enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
    NSNumber *key = @(idx);
    id subMapping = [parameterMapping objectForKey:key];
    isValid = [self mapValue:value toInstance:instance usingMapping:subMapping sourcePropertyName:[NSString stringWithFormat:@"Index %ld", (long)key.integerValue]] && isValid;
  }];
  return isValid;
}

+ (BOOL)mapValue:(id)value toInstance:(id)instance usingMapping:(id)mapping sourcePropertyName:(NSString *)propertyName
{
  if ([value isKindOfClass:NSNull.class]) {
    value = nil;
  }

  if ([mapping isKindOfClass:NSDictionary.class] || [mapping isKindOfClass:NSArray.class]) {
    if ([value isKindOfClass:NSDictionary.class] || [value isKindOfClass:NSArray.class]) {
      return [self mapValuesFrom:value toInstance:instance usingMapping:mapping];
    } else {
      AssertTrueOrReturnNo(value == nil);
      if (_shouldLogIgnoredValues) {
        NSLog(@"KZPropertyMapper: Ignoring property %@ as it's not in mapping dictionary", propertyName);
      }
      return YES;
    }
  }

  if (!mapping) {
    if (_shouldLogIgnoredValues) {
      NSLog(@"KZPropertyMapper: Ignoring value at index %@ as it's not mapped", propertyName);
    }
    return YES;
  }

  return [self mapValue:value toInstance:instance usingMapping:mapping sourceKey:propertyName];
}

+ (BOOL)mapValue:(id)value toInstance:(id)instance usingMapping:(id)mapping sourceKey:(NSString *)sourceKey
{
  if ([mapping isKindOfClass:KZPropertyDescriptor.class]) {
    return [self mapValue:value toInstance:instance usingDescriptor:(KZPropertyDescriptor *)mapping sourceKey:sourceKey];
  }

  return [self mapValue:value toInstance:instance usingStringMapping:mapping sourceKey:sourceKey];

}

+ (BOOL)mapValue:(id)value toInstance:(id)instance usingStringMapping:(NSString *)mapping sourceKey:(NSString *)sourceKey
{
  AssertTrueOrReturnNo([mapping isKindOfClass:NSString.class]);

  BOOL isBoxedMapping = [mapping hasPrefix:@"@"];
  BOOL isListOfMappings = [mapping rangeOfString:@"&"].location != NSNotFound;
  
  if (!isBoxedMapping && !isListOfMappings) {
    //! normal 1 : 1 mapping
    return [self setValue:value onInstance:instance usingKeyPath:mapping sourceKey:sourceKey];;
  }

  if (isListOfMappings) {
    //! List of mappings
    BOOL parseResult = YES;
    NSArray *stringMappings = [mapping componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    for (NSString *innerMapping in stringMappings) {
      NSString *wipedInnerMapping = [innerMapping stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      parseResult = [self mapValue:value toInstance:instance usingStringMapping:wipedInnerMapping sourceKey:sourceKey] && parseResult;
    }
    return parseResult;
  }

  //! Single boxing
  NSArray *components = [mapping componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@()"]];
  AssertTrueOrReturnNo(components.count == 4);

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
    AssertTrueOrReturnNoBlock([self respondsToSelector:mappingSelector], ^(NSError *error) {
    });
    id (*objc_msgSendTyped)(id, SEL, id, id, NSArray *) = (id (*)(id, SEL, id, id, NSArray *))objc_msgSend;
    boxingParameters = [boxingParameters arrayByAddingObject:targetProperty];
    boxedValue = objc_msgSendTyped(self, mappingSelector, instance, value, boxingParameters);
  } else {
    SEL mappingSelector = NSSelectorFromString([NSString stringWithFormat:@"boxValueAs%@:", mappingType]);
    AssertTrueOrReturnNoBlock([self respondsToSelector:mappingSelector], ^(NSError *error) {
    });
    id (*objc_msgSendTyped)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
    boxedValue = objc_msgSendTyped(self, mappingSelector, value);
  }

  if (!boxedValue) {
    return NO;
  }
  
  return [self setValue:boxedValue onInstance:instance usingKeyPath:targetProperty sourceKey:sourceKey];
}

+ (BOOL)mapValue:(id)value toInstance:(id)instance usingDescriptor:(KZPropertyDescriptor *)descriptor sourceKey:(NSString *)sourceKey
{
  NSArray *errors = [descriptor validateValue:value];
  if (errors.count > 0) {
    return NO;
  }

  [self mapValue:value toInstance:instance usingStringMapping:descriptor.stringMapping sourceKey:sourceKey];
  return YES;
}

+ (BOOL)setValue:(id)value onInstance:(id)instance usingKeyPath:(NSString *)targetKeyPath sourceKey:(NSString *)sourceKey
{
  if (![self validateMapping:targetKeyPath withMappingValue:value onInstance:instance sourceKey:sourceKey]) {
    return NO;
  }
  
  Class coreDataBaseClass = NSClassFromString(@"NSManagedObject");
  if (coreDataBaseClass != nil && [instance isKindOfClass:coreDataBaseClass] &&
          [[((NSManagedObject *) instance).entity propertiesByName] valueForKey:targetKeyPath]) {
    [instance willChangeValueForKey:targetKeyPath];
    void (*objc_msgSendTyped)(id, SEL, id, NSString*) = (void (*)(id, SEL, id, NSString*))objc_msgSend;
    objc_msgSendTyped(instance, NSSelectorFromString(@"setPrimitiveValue:forKey:"), value, targetKeyPath);
    [instance didChangeValueForKey:targetKeyPath];
  } else {
    [instance setValue:value forKeyPath:targetKeyPath];
  }
  return YES;
}

#pragma mark - Validation

+ (BOOL)validateMapping:(NSString *)mapping withMappingValue:(id)object onInstance:(id)instance sourceKey:(NSString *)sourceKey
{
  if (object == nil) {
    return YES;
  }
  
  objc_property_t theProperty = class_getProperty([instance class], [mapping UTF8String]);
  if (!theProperty) {
    return YES; // This keeps default behaviour of KZPropertyMapper
  }
  
  NSString *propertyEncoding = [NSString stringWithUTF8String:property_getAttributes(theProperty)];
  NSArray *encodings = [propertyEncoding componentsSeparatedByString:@","];
  NSString *fullTypeEncoding = [encodings firstObject];
  NSString *typeEncoding = [fullTypeEncoding substringFromIndex:1];
  const char *cTypeEncoding = [typeEncoding substringToIndex:1].UTF8String;
  
  if (strcmp(cTypeEncoding, @encode(id)) != 0) {
    return YES; // This keeps default behaviour of KZPropertyMapper
  }
  
  if ([typeEncoding isEqual:@"@"] || typeEncoding.length < 3) {
    return YES; // Looks like it is "id" so, should be fine
  }
  
  NSString *propertyClassName = [typeEncoding substringWithRange:NSMakeRange(2, typeEncoding.length - 3)];
  Class propertyClass = NSClassFromString(propertyClassName);
  BOOL isSameTypeObject = ([object isKindOfClass:propertyClass]);
  
  if (_shouldLogIgnoredValues && !isSameTypeObject) {
    NSLog(@"KZPropertyMapper: Ignoring mapping from %@ to %@ because type %@ does NOT match %@", sourceKey, mapping, NSStringFromClass([object class]), propertyClassName);
  }
  AssertTrueOrReturnNo(isSameTypeObject);
  return isSameTypeObject;
}

+ (NSArray *)validateMapping:(NSDictionary *)mapping withValues:(id)values
{
  AssertTrueOrReturnErrors([mapping isKindOfClass:NSDictionary.class]);

  if (!values || [values isKindOfClass:NSDictionary.class]) {
    return [self validateMapping:mapping withValuesDictionary:values];
  } else if ([values isKindOfClass:NSArray.class]) {
    return [self validateMapping:mapping withValuesArray:values];
  }
  if (_shouldLogIgnoredValues) {
    NSLog(@"KZPropertyMapper: Ignoring value at index %@ as it's not mapped", mapping);
  }
  return nil;
}

+ (NSArray *)validateMapping:(NSDictionary *)mapping withValuesArray:(NSArray *)values
{
  AssertTrueOrReturnNil([values isKindOfClass:NSArray.class]);
  
  NSMutableArray *errors = [NSMutableArray new];
  [mapping enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
    if (![key isKindOfClass:NSNumber.class]) {
      NSError *error = pixle_NSErrorMake([NSString stringWithFormat:@"Expected key to be number, but got %@", key], kErrorCodeInternal, nil, nil);
      [errors addObject:error];
      AssertTrueOrReturn(NO); // Looks weird, but is needed to throw exception, when running with asserts on.
      return;
    }
    
    NSUInteger itemIndex = key.unsignedIntValue;
    if (itemIndex >= values.count) {
      if (_shouldLogIgnoredValues) {
        NSLog(@"KZPropertyMapper: Ignoring value at index %@ as it's not mapped", key);
      }
      return;
    }
    
    id value = [values objectAtIndex:itemIndex];
    
    //! submapping
    if ([obj isKindOfClass:NSArray.class] || [obj isKindOfClass:NSDictionary.class]) {
      NSArray *validationErrors = [self validateMapping:obj withValues:value];
      if (validationErrors) {
        [errors addObjectsFromArray:validationErrors];
      }
    }

    if ([obj isKindOfClass:KZPropertyDescriptor.class]) {
      KZPropertyDescriptor *descriptor = obj;
      NSArray *validationErrors = [descriptor validateValue:value];
      if (validationErrors.count > 0) {
        [errors addObjectsFromArray:validationErrors];
      }
    }
  }];

  return errors;
}

+ (NSArray *)validateMapping:(NSDictionary *)mapping withValuesDictionary:(NSDictionary *)values
{
  NSMutableArray *errors = [NSMutableArray new];
  [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
    id value = [values objectForKey:key];
    if ([value isKindOfClass:NSNull.class]) {
      value = nil;
    }
    
    //! submapping
    if ([obj isKindOfClass:NSArray.class] || [obj isKindOfClass:NSDictionary.class]) {
      NSArray *validationErrors = [self validateMapping:obj withValues:value];
      if (validationErrors) {
        [errors addObjectsFromArray:validationErrors];
      }
    }

    if ([obj isKindOfClass:KZPropertyDescriptor.class]) {
      KZPropertyDescriptor *descriptor = obj;
      NSArray *validationErrors = [descriptor validateValue:value];
      if (validationErrors.count > 0) {
        [errors addObjectsFromArray:validationErrors];
      }
    }
  }];

  return errors;
}

#pragma mark - Logging configuration

#ifdef KZPropertyMapperLogIgnoredValues
static BOOL _shouldLogIgnoredValues = KZPropertyMapperLogIgnoredValues;
#else
static BOOL _shouldLogIgnoredValues = YES;
#endif

+ (void)logIgnoredValues:(BOOL)logIgnoredValues
{
  _shouldLogIgnoredValues = logIgnoredValues;
}


#pragma mark - Dynamic boxing

+ (NSURL *)boxValueAsURL:(id)value __unused
{
  if (value == nil) {
    return nil;
  }
  AssertTrueOrReturnNil([value isKindOfClass:NSString.class]);
  return [NSURL URLWithString:value];
}

+ (NSDate *)boxValueAsDate:(id)value __unused
{
  if (value == nil) {
    return nil;
  }
  AssertTrueOrReturnNil([value isKindOfClass:NSString.class]);
  return [[self dateFormatter] dateFromString:value];
}

+ (NSDateFormatter *)dateFormatter
{
  static NSDateFormatter *df = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    df = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [df setLocale:locale];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
  });
  return df;
}

+ (id)boxValueAsSelectorOnTarget:(id)target value:(id)value params:(NSArray *)params __unused
{
  AssertTrueOrReturnNil(params.count == 2);
  NSString *selectorName = [params objectAtIndex:0];
  NSString *targetPropertyName = [params objectAtIndex:1];
  NSArray *selectorComponents = [selectorName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
  SEL selector = NSSelectorFromString(selectorName);
  
  AssertTrueOrReturnNil([target respondsToSelector:selector]);
  if(selectorComponents.count > 2){
    id (*objc_msgSendTyped)(id, SEL, id, NSString*) = (id (*)(id, SEL, id, NSString*))objc_msgSend;
    return objc_msgSendTyped(target, selector, value, targetPropertyName);
  }
  id (*objc_msgSendTyped)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
  return objc_msgSendTyped(target, selector, value);
}
@end

