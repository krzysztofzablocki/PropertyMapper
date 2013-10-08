#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"
#import "TestObject.h"

SPEC_BEGIN(KZPropertyMapperSpec)

  describe(@"KZPropertyMapper", ^{
    context(@"basic", ^{

      __block NSDictionary *mapping;
      __block NSDictionary *sourceDictionary;
      __block TestObject *testObject;

      beforeEach(^{
        mapping = @{@"videoURL" : @"@URL(contentURL)",
          @"name" : @"title",
          @"videoType" : @"type",
          @"sub_object" : @{
            @"title" : @"uniqueID"}
        };
        sourceDictionary = @{@"videoURL" : @"http://test.com/video.mp4", @"name" : @"Some Cool Video", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}};
        testObject = [TestObject new];
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
      });
    });
  });


  SPEC_END