#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"


@interface KZPropertyTestObject : NSObject
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) id type;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *uniqueID;
@property(nonatomic, strong) NSNumber *number;

- (BOOL)updateFromDictionary:(NSDictionary *)dictionary;
@end

@implementation KZPropertyTestObject

- (BOOL)updateFromDictionary:(NSDictionary *)dictionary
{
  BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:@{
    @"videoURL" : KZMap(URL, contentURL).isRequired(),
    @"name" : KZProperty(title).lengthRange(5, 12),
    @"videoType" : KZProperty(type),
    @"sub_object" : @{
      @"title" : KZProperty(uniqueID),
    },
  }];

  return result;
}

@end

SPEC_BEGIN(KZPropertyMapperSpec)

  describe(@"KZPropertyMapper", ^{
    context(@"basic", ^{

      __block NSDictionary *mapping;
      __block NSDictionary *sourceDictionary;
      __block KZPropertyTestObject *testObject;

      beforeEach(^{
        mapping = @{@"videoURL" : @"@URL(contentURL)",
          @"name" : @"title",
          @"videoType" : @"type",
          @"sub_object" : @{
            @"title" : @"uniqueID"}
        };
        sourceDictionary = @{@"videoURL" : @"http://test.com/video.mp4", @"name" : @"Some Cool Video", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};
        testObject = [KZPropertyTestObject new];
      });

      afterEach(^{
        mapping = nil;
        sourceDictionary = nil;
        testObject = nil;
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
          [[testObject.type should] equal:sourceDictionary[@"name"]];
        });

        it(@"should support boxing functionality", ^{
          [[testObject.videoURL should] beKindOfClass:NSURL.class];
        });


        context(@"using validators", ^{
          it(@"should fail isRequired validator if property is missing", ^{
            NSDictionary *dictionary = @{@"name" : @"Some Cool Video", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"videoURL" : KZMapT(testInstance, URL, contentURL).isRequired()
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed isRequired validator if ok", ^{
            NSDictionary *dictionary = @{@"videoURL" : @"http://test.com/video.mp4", @"name" : @"Some Cool Video", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"videoURL" : KZMapT(testInstance, URL, contentURL).isRequired()
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should fail lengthRange validator if missing", ^{
            NSDictionary *dictionary = @{@"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).lengthRange(5, 10)
            }];

            [[theValue(result) should] beFalse];
          });

          it(@"should fail lengthRange validator if outside range", ^{
            NSDictionary *dictionary = @{@"name" : @"Some Cool Video dsadsa dsa dsa", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).lengthRange(5, 10)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed lengthRange validator if ok", ^{
            NSDictionary *dictionary = @{@"name" : @"Some Cool", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).lengthRange(5, 11)
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should succed regex validator if ok", ^{
            NSDictionary *dictionary = @{@"name" : @"BC", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).matchesRegEx([NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b" options:NSRegularExpressionCaseInsensitive error:nil])
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should fail regex validator if doens't match", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).matchesRegEx([NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b" options:NSRegularExpressionCaseInsensitive error:nil])
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should fail length validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).length(10)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed length validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).length(3)
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should fail minLength validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).minLength(10)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed minLength validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).minLength(3)
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should fail maxLength validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).maxLength(2)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed maxLength validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).maxLength(3)
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should fail oneOf validator if not found", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).oneOf(@[@"aba", @"baba"])
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed oneOf validator if wrong length", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).oneOf(@[@"BCd", @"baba"])
            }];
            [[theValue(result) should] beTrue];
          });

          it(@"should fail equalTo", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).equalTo(@"aba")
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed equalTo", ^{
            NSDictionary *dictionary = @{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};

            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:dictionary toInstance:testInstance usingMapping:@{
              @"name" : KZPropertyT(testInstance, title).equalTo(@"BCd")
            }];
            [[theValue(result) should] beTrue];
          });


          it(@"should fail max", ^{
            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:testInstance usingMapping:@{
              @"number" : KZPropertyT(testInstance, number).max(2)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed max", ^{
            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:testInstance usingMapping:@{
              @"number" : KZPropertyT(testInstance, number).max(2)
            }];
            [[theValue(result) should] beTrue];
          });


          it(@"should fail min", ^{
            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:testInstance usingMapping:@{
              @"number" : KZPropertyT(testInstance, number).min(4)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed min", ^{
            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:testInstance usingMapping:@{
              @"number" : KZPropertyT(testInstance, number).min(2)
            }];
            [[theValue(result) should] beTrue];
          });


          it(@"should fail range", ^{
            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:testInstance usingMapping:@{
              @"number" : KZPropertyT(testInstance, number).range(1, 2)
            }];
            [[theValue(result) should] beFalse];
          });

          it(@"should succed range", ^{
            KZPropertyTestObject *testInstance = [KZPropertyTestObject new];
            BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:testInstance usingMapping:@{
              @"number" : KZPropertyT(testInstance, number).range(1, 4)
            }];
            [[theValue(result) should] beTrue];
          });

        //! TODO: add reverse range test
        });

      });
    });
  });


  SPEC_END