//
//  Created by merowing on 09/10/2013.
//
//
//


#import "KZPropertyDescriptor.h"
#import "KZPropertyMapperCommon.h"

@interface KZPropertyDescriptor ()
@property(nonatomic, copy) NSString *propertyName;
@property(nonatomic, copy) NSString *mapping;
@property(nonatomic, strong) NSMutableArray *validationBlocks;
@property(nonatomic, assign) BOOL isUsingSelectorMapping;

- (NSArray *)validateValue:(id)value;
@end

@implementation KZPropertyDescriptor

+ (instancetype)descriptorWithPropertyName:(NSString *)name andMapping:(NSString *)mapping
{
  return [[KZPropertyDescriptor alloc] initWithPropertyName:name andMapping:mapping];
}

+ (instancetype)descriptorWithPropertyName:(NSString*)name andMappings:(id)mapping, ...
{
  if (mapping == nil) {
    return nil;
  }
 
  NSMutableString *mappingString = [NSMutableString new];
  [self addMapping:mapping toMappingString:mappingString];
  va_list args;
  va_start(args, mapping);
  
  while(mapping) {
    [self addMapping:mapping toMappingString:mappingString];
    mapping = va_arg(args, id);
  }
  va_end(args);

  return [KZPropertyDescriptor descriptorWithPropertyName:name andMapping:mappingString.copy];
}

+ (void)addMapping:(id)mapping toMappingString:(NSMutableString *)mappingString
{
  NSString *prefix = (mappingString.length ? @" & " : @"");
  if ([mapping isKindOfClass:NSString.class]) {
    [mappingString appendFormat:@"%@%@", prefix, mapping];
    return;
  }
  
  if ([mapping isKindOfClass:KZPropertyDescriptor.class]) {
    [mappingString appendFormat:@"%@%@", prefix, [mapping stringMapping]];
    return;
  }
}

+ (instancetype)descriptorWithPropertyName:(NSString*)name selector:(SEL)selector
{
  KZPropertyDescriptor *descriptor = [[KZPropertyDescriptor alloc] initWithPropertyName:name andMapping:NSStringFromSelector(selector)];
  descriptor.isUsingSelectorMapping = YES;
  return descriptor;
}

- (id)initWithPropertyName:(NSString *)name andMapping:(NSString *)mapping
{
  self = [super init];
  if (self) {
    _propertyName = name;
    _mapping = mapping;
  }

  return self;
}

- (void)addValidatonWithBlock:(NSError * (^)(id, NSString *))validationBlock
{
  if (!self.validationBlocks) {
    self.validationBlocks = [NSMutableArray new];
  }

  [self.validationBlocks addObject:validationBlock];
}

- (void)addValidatorWithName:(NSString *)name validation:(BOOL (^)(id value))validator
{
  [self addValidatonWithBlock:^(NSString *value, NSString *propertyName) {
    BOOL validationResult = validator(value);
    if ([value isKindOfClass:NSNull.class] || !value || !validationResult) {
      return pixle_NSErrorMake([NSString stringWithFormat:@"%@: validation failed on %@", propertyName, name], kErrorCodeInternal, nil, nil);
    }
    return (NSError *)nil;
  }];
}

- (NSArray *)validateValue:(id)value
{
  NSMutableArray *errors = [NSMutableArray new];
  [self.validationBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSError *(^validationBlock)(id, NSString *) = obj;
    NSError *error = validationBlock(value, self.propertyName);
    if (error) {
      [errors addObject:error];
    }
  }];
  return errors;
}

- (NSString *)stringMapping
{
  if (!self.mapping.length) {
    return self.propertyName;
  }
  
  if (!self.propertyName.length) {
    return self.mapping;
  }
  
  if (self.isUsingSelectorMapping) {
    return [NSString stringWithFormat:@"@Selector(%@, %@)", self.mapping, self.propertyName];
  }
  return [NSString stringWithFormat:@"@%@(%@)", self.mapping, self.propertyName];
}

@end