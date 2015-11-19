//
//  Created by merowing on 08/10/2013.
//
//
//


#import "TestObject.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"

@interface _TestProtocol : NSObject <TestProtocol>
@property (nonatomic, readwrite) id value;
@end
@implementation _TestProtocol
- (instancetype)initWithValue:(id)value {
    if (!(self = [self init])) { return nil; }
    self.value = value;
    return self;
}
@end

id<TestProtocol> TestProtocolCreate(id value) {
    return [_TestProtocol.alloc initWithValue:value];
}

@implementation TestObject

- (BOOL)updateFromDictionary:(NSDictionary *)dictionary
{
  BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:@{
    @"videoURL" : KZBox(URL, contentURL).isRequired(),
    @"name" : KZProperty(title).lengthRange(5, 12),
    @"videoType" : KZProperty(type),
    @"sub_object" : @{
      @"title" : KZProperty(uniqueID),
    },
  }];

  return result;
}

- (id)numberIncrease:(NSNumber*)value {
  return @(value.integerValue + 1);
}

- (id)numberIncrease:(NSNumber*)value forProperty:(NSString *)propertyName {
  return nil;
}

- (id)passthroughMethod:(id)object
{
  return object;
}

@end

@interface ConcreteTestProtocol ()
@property (nonatomic, readwrite) id value;
@end
@implementation ConcreteTestProtocol
- (instancetype)initWithValue:(id)value {
    if (!(self = [self init])) { return nil; }
    self.value = value;
    return self;
}

@end

