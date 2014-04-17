//
//  KZPropertyMapperListTests.m
//  HomebaseMobileAppIphone
//
//  Created by Marek Cirkos on 15/04/2014.
//
//

#import "KZPropertyMapper.h"
#import "Kiwi.h"
#import "TestObject.h"

SPEC_BEGIN(KZPropertyMapperListTests)

describe(@"KZList", ^{
  __block NSDictionary *parsingSource;
  __block NSDictionary *mapping;
  __block TestObject *object;
  
  NSString *compareValue = @"value";
  
  context(nil, ^{
    beforeEach(^{
      object = [TestObject new];
      parsingSource = @{@"Content": @"value"};
    });
    
    it(@"should parse when using string mapping", ^{
      mapping = @{@"Content": @"title & uniqueID"};
      
      [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];;
      [[object.title shouldNot] beNil];
      [[object.title should] equal:compareValue];
      [[object.uniqueID shouldNot] beNil];
      [[object.uniqueID should] equal:compareValue];
      [[object.contentURL should] beNil];
    });
    
    it(@"should parse when using KZPropertyDescriptor", ^{
      mapping = @{@"Content": [KZPropertyDescriptor descriptorWithPropertyName:nil andMappings:@"title", @"uniqueID", nil]};

      [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
      [[object.title shouldNot] beNil];
      [[object.title should] equal:compareValue];
      [[object.uniqueID shouldNot] beNil];
      [[object.uniqueID should] equal:compareValue];
      [[object.contentURL should] beNil];
    });
    
    context(@"when using KZList macro", ^{
      beforeAll(^{
        mapping = @{@"Content": KZList(@"title",
                                       KZBoxT(object, URL, contentURL),
                                       KZPropertyT(object, uniqueID),
                                       KZCallT(object, passthroughMethod:, type))
                    };
      });
      
      beforeEach(^{
        [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
      });
      
      it(@"should work with string maping", ^{
        [[object.title shouldNot] beNil];
        [[object.title should] equal:compareValue];
      });
      
      it(@"should wotk with KZPropertyT macro", ^{
        [[object.uniqueID shouldNot] beNil];
        [[object.uniqueID should] equal:compareValue];
      });
      
      it(@"should wotk with KZCallT macro", ^{
        [[object.type shouldNot] beNil];
        [[object.type should] equal:compareValue];
      });
      
      it(@"should wotk with KZBoxT macro", ^{
        [[object.contentURL shouldNot] beNil];
        [[object.contentURL should] equal:[NSURL URLWithString:compareValue]];
      });
    });
    
    context(@"when parsing bad mappings", ^{
      it(@"should raise mistyped property", ^{
        mapping = @{@"Content": @"titled & uniqueID"};
        [[theBlock(^{
          [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
        }) should] raiseWithName:@"NSUnknownKeyException"];
      });
    });
    
  });
});

SPEC_END
