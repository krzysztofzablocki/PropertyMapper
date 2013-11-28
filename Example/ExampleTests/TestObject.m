//
//  Created by merowing on 08/10/2013.
//
//
//


#import "TestObject.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"

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

@end
