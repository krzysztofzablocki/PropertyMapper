#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"
#import "TestObject.h"

SPEC_BEGIN(KZPropertyMapperSpec)

  describe(@"Mapper", ^{
    context(nil, ^{

      __block NSDictionary *mapping;
      __block NSDictionary *sourceDictionary;
      __block TestObject *testObject;
      __block BOOL testResult;
      
      beforeEach(^{
        mapping = @{@"videoURL" : @"@URL(contentURL)",
          @"name" : @"title",
          @"videoType" : @"type",
          @"sub_object" : @{
            @"title" : @"uniqueID"}
        };
        sourceDictionary = @{@"videoURL" : @"http://test.com/video.mp4", @"name" : @"Some Cool", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};
        testObject = [TestObject new];
      });

      afterEach(^{
        mapping = nil;
        sourceDictionary = nil;
        testObject = nil;
        testResult = NO;
      });

      it(@"should convert any NSNull's to nil", ^{
        [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        [testObject.type shouldBeNil];
      });

      it(@"should support array as source data structure", ^() {
        mapping = @{@0 : @{@"testValue" : @{@1 : @"uniqueID"}}};
        id sourceArray = @[@{@"testValue" : @[@543, @123]}];

        [KZPropertyMapper mapValuesFrom:sourceArray toInstance:testObject usingMapping:mapping];
        [[testObject.uniqueID should] equal:@123];
      });

      it(@"should raise exception if mapping is to invalid fields", ^{
        NSDictionary *badMappingDict = @{@"videoURL" : @"wrongField", @"name" : @"Someothernonexistentfield", @"videoType" : @"type"};
        [[theBlock(^{
          [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:badMappingDict];
        }) should] raiseWithName:@"NSUnknownKeyException"];
      });


      it(@"shouldn't throw exception if source data doesn't have a key", ^{
        mapping = @{@"videoURL4432" : @"@URL(contentURL)", @"name" : @"title", @"videoType" : @"type"};
        [[theBlock(^{
          [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
      });

      it(@"should support dictionary sub-objects", ^() {
        [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        [[testObject.uniqueID should] equal:@616];
      });

      it(@"should support array sub-objects", ^() {
        mapping = @{@"sub_object_array" : @{@1 : @"uniqueID"}};
        sourceDictionary = @{@"sub_object_array" : @[@"test", @123]};

        [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        [[testObject.uniqueID should] equal:@123];
      });

      it(@"should support dictionary sub-object in array sub-object", ^() {
        mapping = @{@"sub_object_array" : @{@1 : @{@"testValue" : @"uniqueID"}}};
        sourceDictionary = @{@"sub_object_array" : @[@"test", @{@"testValue" : @123}]};

        [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        [[testObject.uniqueID should] equal:@123];
      });

      it(@"should support array sub-object in dictionary sub-object", ^() {
        mapping = @{@"sub_object_dictionary" : @{@"testValue" : @{@1 : @"uniqueID"}}};
        sourceDictionary = @{@"sub_object_dictionary" : @{@"testValue" : @[@543, @123]}};

        [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        [[testObject.uniqueID should] equal:@123];
      });

      context(@"using boxing functionality", ^{
        it(@"should support @URL boxing", ^{
          [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          [[testObject.contentURL should] equal:[NSURL URLWithString:@"http://test.com/video.mp4"]];
        });
      });


      context(@"using advanced mapping features", ^{
        beforeEach(^{
          [testObject updateFromDictionary:sourceDictionary];
        });

        it(@"should work for base properties", ^{
          [[testObject.title should] equal:sourceDictionary[@"name"]];
        });

        it(@"should support boxing functionality", ^{
          [[testObject.contentURL should] beKindOfClass:NSURL.class];
        });

        it(@"should work with selector boxing", ^{
          TestObject *testObject = [TestObject new];
          [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:testObject usingMapping:@{
            @"number" : KZCallT(testObject, numberIncrease:, number)
          }];
          [[testObject.number should] equal:@4];
        });
        
        it(@"should work with two argument selector boxing", ^{
          TestObject *testObject = [TestObject new];
          [[testObject should] receive:@selector(numberIncrease:forProperty:) withArguments:@3, @"number"];
          [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:testObject usingMapping:@{
              @"number" : KZCallT(testObject, numberIncrease:forProperty:, number)
          }];
        });

        it(@"should support mapping anonymous protocol dependency", ^{
          sourceDictionary = @{@"dependency" : TestProtocolCreate(@YES)};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary
                                              toInstance:testObject
                                            usingMapping:@{
                            @"dependency" : KZPropertyT(testObject, dependency_as_id)
                         }];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          // casting is necessary because of 'Kiwi'
          [[(NSObject*)testObject.dependency_as_id shouldNot] beNil];
          [[(NSObject*)testObject.dependency_as_id.value should] equal:@YES];
        });

        it(@"should support mapping concrete protocol dependency", ^{
          sourceDictionary = @{@"dependency" : [ConcreteTestProtocol.alloc initWithValue:@YES]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary
                                              toInstance:testObject
                                            usingMapping:@{
                            @"dependency" : KZPropertyT(testObject, dependency_as_concrete_type)
                         }];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          // casting is necessary because of 'Kiwi'
          [[testObject.dependency_as_concrete_type shouldNot] beNil];
          [[testObject.dependency_as_concrete_type.value should] equal:@YES];
        });

        it(@"should fail mapping generic object protocol dependency", ^{
          sourceDictionary = @{@"dependency" : TestProtocolCreate(@YES)};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary
                                              toInstance:testObject
                                            usingMapping:@{
                            @"dependency" : KZPropertyT(testObject, dependency_as_nsobject)
                         }];
          }) should] raise];
          // "type _TestProtocol does NOT match NSObject<TestProtocol>"
          [[theValue(testResult) should] beFalse];
          [[testObject.dependency_as_nsobject should] beNil];
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
          [[testObject.title shouldNot] beNil];
          [[testObject.title should] equal:@"domek"];
        });
        
        it(@"should handle absence of value", ^{
          sourceDictionary = @{@"differentValue" : @"domek"};
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
        
        it(@"should handle dictionary value", ^{
          sourceDictionary = @{@"testValue" : @{@"key" : @"value"}};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) should] raise];
          [[theValue(testResult) should] beFalse];
          [[testObject.title should] beNil];
        });
        
        it(@"should handle dictionary value when using KZProperty", ^{
          sourceDictionary = @{@"testValue" : @{@"key" : @"value"}};
          #ifndef NS_BLOCK_ASSERTIONS
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:@{@"testValue": KZPropertyT(testObject, title)}];
          }) should] raise];
          #else
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:@{@"testValue": KZPropertyT(testObject, title)}];
          [[theValue(testResult) should] beFalse];
          [[testObject.title should] beNil];
          #endif
        });
        
        it(@"should handle array value", ^{
          sourceDictionary = @{@"testValue" : @[@"v1", @"v2"]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) should] raise];
          [[theValue(testResult) should] beFalse];
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
          [[testObject.title shouldNot] beNil];
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
          }) should] raise];
          [[theValue(testResult) should] beFalse];
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
          }) should] raise];
          [[theValue(testResult) should] beFalse];
          [[testObject.title should] beNil];
        });
        
        it(@"should handle nested dictionary value", ^{
          sourceDictionary = @{@"key" : @{@"testValue" : @{@"v" : @"op"}}};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) should] raise];
          [[theValue(testResult) should] beFalse];
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
          [[testObject.title shouldNot] beNil];
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
          }) should] raise];
          [[theValue(testResult) should] beFalse];
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
          }) should] raise];
          [[theValue(testResult) should] beFalse];
          [[testObject.title should] beNil];
        });
        
        it(@"should handle nested array value", ^{
          sourceDictionary = @{@"testValue" : @[@"v1", @[@"v2", @"v3"]]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) should] raise];
          [[theValue(testResult) should] beFalse];
          [[testObject.title should] beNil];
        });
      });
    });
    
  });

  SPEC_END