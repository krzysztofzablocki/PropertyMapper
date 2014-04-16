//
//  HBMultipleKeyTargetParserTest.m
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
  
  NSString *properValue = @"value";
  
  context(nil, ^{
    beforeEach(^{
      object = [TestObject new];
      parsingSource = @{@"Content": @"value"};
    });
    
    it(@"should parse when using string mapping", ^{
      mapping = @{@"Content": @"title & uniqueID"};
      
      [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
      [[properValue should] equal:object.title];
      [[properValue should] equal:object.uniqueID];
      [[object.contentURL should] beNil];
    });
    
    it(@"should parse when using KZPropertyDescriptor", ^{
      mapping = @{@"Content": [KZPropertyDescriptor descriptorWithPropertyName:nil andMappings:@"title", @"uniqueID", nil]};

      [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
      [[properValue should] equal:object.title];
      [[properValue should] equal:object.uniqueID];
      [[object.contentURL should] beNil];
    });
    
    context(@"when using KZList", ^{
      beforeAll(^{
        mapping = @{@"Content": KZList(@"title", KZBoxT(object, URL, contentURL), KZPropertyT(object, uniqueID), KZCallT(object, passthroughMethod:, type))};
      });
      
      beforeEach(^{
        [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
      });
      
      it(@"should work with string maping", ^{
        [[properValue should] equal:object.title];
      });
      
      it(@"should wotk with KZPropertyT macro", ^{
        [[properValue should] equal:object.uniqueID];
      });
      
      it(@"should wotk with KZCallT macro", ^{
        [[properValue should] equal:object.type];
      });
      
      it(@"should wotk with KZBoxT macro", ^{
        [[[NSURL URLWithString:properValue] should] equal:object.contentURL];
      });
    });
    
    context(@"when parsing bad mappings", ^{
      it(@"should raise mistyped property", ^{
        mapping = @{@"Content": @"titlee & uniqueID"};
        [[theBlock(^{
          [KZPropertyMapper mapValuesFrom:parsingSource toInstance:object usingMapping:mapping];
        }) should] raiseWithName:@"NSUnknownKeyException"];
      });
    });
    
  });
});

SPEC_END
