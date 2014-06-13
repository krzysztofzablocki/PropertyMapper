//
// Created by Marek Cirkos on 02/04/2014.
//


#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"
#import "TestObject.h"

SPEC_BEGIN(KZPropertyMapperTypingSpec)

describe(@"Mapper", ^{
  
  context(nil, ^{
    __block TestObject *testObject = nil;
    __block NSDictionary *mapping = nil;
    __block NSDictionary *sourceDictionary = nil;
    __block BOOL testResult = NO;
    
    beforeEach(^{
      testResult = NO;
      testObject = [TestObject new];
    });
    
    afterEach(^{
      mapping = nil;
      sourceDictionary = nil;
      testObject = nil;
    });
    
    it(@"should parse simple type values with good mapping", ^{
      mapping = @{@"stringValue" : @"title",
                  @"numberValue" : @"number",
                  @"integetValue" : @"intNumber",
                  @"floatValue" : @"floatNumber",
                  @"boolValue1" : @"isCheap",
                  @"boolValue2" : @"isExpensive"
                  };
      
      sourceDictionary = @{@"stringValue" : @"niceTitle",
                           @"numberValue" : @1,
                           @"integetValue" : @3,
                           @"floatValue" : @1.5,
                           @"boolValue1" : @YES,
                           @"boolValue2" : @NO
                           };
      [[theBlock(^{
        testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
      }) shouldNot] raise];
      [[theValue(testResult) should] beTrue];
      
      [[testObject.title should] equal:@"niceTitle"];
      [[testObject.number should] equal:@1];
      [[theValue(testObject.intNumber) should] equal:theValue(3)];
      [[theValue(testObject.floatNumber) should] equal:theValue(1.5)];
      [[theValue(testObject.isCheap) should] beYes];
      [[theValue(testObject.isExpensive) should] beNo];
    });
    
    context(@"when mapping object to object", ^{
      
      it(@"should parse NSULR to NSURL fine", ^{
        mapping = @{@"helpURL" : @"@URL(videoURL)"};
        sourceDictionary = @{@"helpURL" : @"http://help.apple.com"};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.videoURL should] equal:[NSURL URLWithString:@"http://help.apple.com"]];
      });
      
      it(@"should parse NSString to id fine", ^{
        mapping = @{@"sideURL" : @"type"};
        sourceDictionary = @{@"sideURL" : @"http://apple.com"};
        
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.type should] equal:@"http://apple.com"];
      });
      
      it(@"should parse NSULR to id fine", ^{
        mapping = @{@"sideURL" : @"@URL(type)"};
        sourceDictionary = @{@"sideURL" : @"http://apple.com"};
        
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.type should] equal:[NSURL URLWithString:@"http://apple.com"]];
      });
      
      it(@"should NOT parse NSString to NSURL", ^{
        mapping = @{@"helpURL" : @"videoURL"};
        sourceDictionary = @{@"helpURL" : @"http://help.apple.com"};
        
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.videoURL should] beNil];
      });
    });
    
    context(@"when mapping to non-collection object", ^{
      
      beforeEach(^{
        mapping = @{@"testValue" : @"title" };
      });
      
      it(@"should work with good mapping", ^{
        sourceDictionary = @{@"testValue" : @"domek"};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] equal:@"domek"];
      });
      
      it(@"should handle absence of value", ^{
        sourceDictionary = @{@"differentValue" : @"domek"};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
      });
      
      it(@"should handle NULL value", ^{
        sourceDictionary = @{@"testValue" : [NSNull null]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle dictionary value", ^{
        sourceDictionary = @{@"testValue" : @{@"key" : @"value"}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle array value", ^{
        sourceDictionary = @{@"testValue" : @[@"v1", @"v2"]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
    });
    
    context(@"when mapping to dictionary", ^{
      
      beforeEach(^{
        mapping = @{@"key" : @{@"testValue" : @"title"}};
      });
      
      it(@"should work with good mapping", ^{
        sourceDictionary = @{@"key" : @{@"testValue" : @"domek"}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] equal:@"domek"];
      });
      
      it(@"should handle wrong path", ^{
        sourceDictionary = @{@"differentKey" : @{@"testValue" : @"domek"}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle wrong path", ^{
        sourceDictionary = @{@"key" : @{@"wrongValue" : @"domek"}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle absence of value", ^{
        sourceDictionary = @{@"differentKey" : @""};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle NULL value", ^{
        sourceDictionary = @{@"key" : [NSNull null]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle NULL value", ^{
        sourceDictionary = @{@"key" : @{@"testValue" : [NSNull null]}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle simple value", ^{
        sourceDictionary = @{@"key" : @"someValue"};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle array value", ^{
        sourceDictionary = @{@"key" : @[@"v1", @"v2"]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) should] raise];
        [[theValue(testResult) should] beFalse];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle nested array value", ^{
        sourceDictionary = @{@"key" : @{@"testValue" : @[@"v"]}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle nested dictionary value", ^{
        sourceDictionary = @{@"key" : @{@"testValue" : @{@"v" : @"op"}}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
    });
    
    context(@"when mapping to array", ^{
     
      beforeEach(^{
        mapping = @{ @"testValue" : @{@1 : @"title"}};
      });
      
      it(@"should work with good mapping", ^{
        sourceDictionary = @{@"testValue" : @[@"v1", @"domek"]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] equal:@"domek"];
      });
      
      it(@"should handle index out of range", ^{
        sourceDictionary = @{@"testValue" : @[@"v1"]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle absence of value", ^{
        sourceDictionary = @{@"differentValue" : @"someValue"};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle NULL value in array", ^{
        sourceDictionary = @{@"testValue" : @[@"v1", [NSNull null]]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle NULL value", ^{
        sourceDictionary = @{@"testValue" : [NSNull null]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle simple value", ^{
        sourceDictionary = @{@"testValue" : @"value"};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle dictionary value", ^{
        sourceDictionary = @{@"testValue" : @{@"v1" : @"v2"}};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle nested dictionary value", ^{
        sourceDictionary = @{@"testValue" : @[@"v1", @{@"v2" : @"v3"}]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
      
      it(@"should handle nested array value", ^{
        sourceDictionary = @{@"testValue" : @[@"v1", @[@"v2", @"v3"]]};
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        [[testObject.title should] beNil];
      });
    });
    
  });
});


SPEC_END