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
        }) should] raise];
        [[theValue(testResult) should] beFalse];
        [[testObject.videoURL should] beNil];
      });
    });
    
  });
});


SPEC_END