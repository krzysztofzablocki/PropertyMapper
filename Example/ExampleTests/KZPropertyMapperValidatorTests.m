#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"
#import "TestObject.h"

SPEC_BEGIN(KZPropertyMapperValidatorSpec)
  describe(@"Mapper", ^{
    context(@"while validating", ^{

      it(@"isRequired failing if property is missing", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"Some Cool Video"} toInstance:[TestObject new] usingMapping:@{
          @"videoURL" : KZBoxT([TestObject new], URL, contentURL).isRequired()
        }];
        [[theValue(result) should] beFalse];
      });

      it(@"isRequired succeding if property exists", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"videoURL" : @"http://test.com/video.mp4"} toInstance:[TestObject new] usingMapping:@{
          @"videoURL" : KZBoxT([TestObject new], URL, contentURL).isRequired()
        }];
        [[theValue(result) should] beTrue];
      });

      it(@"lengthRange failing if outside range", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"Some Cool Video dsadsa dsa dsa"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).lengthRange(5, 10)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"lengthRange succeding if ok", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"Some Cool"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).lengthRange(5, 11)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"regex succeding if ok", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BC"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).matchesRegEx([NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b" options:NSRegularExpressionCaseInsensitive error:nil])
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"regex failing if wrong pattern", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).matchesRegEx([NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b" options:NSRegularExpressionCaseInsensitive error:nil])
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"length fails if mismatched", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).length(10)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"length succeding when matched", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).length(3)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"minLength failing if too short", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).minLength(10)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"minLength succeding if long enough", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).minLength(3)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"maxLength failing if too long", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).maxLength(2)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"maxLength succeding if shorter", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).maxLength(3)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"oneOf failing if outside test set", ^{

        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).oneOf(@[@"aba", @"baba"])
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"oneOf succeding if correct", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).oneOf(@[@"BCd", @"baba"])
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"equalTo failing if mismatched", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).equalTo(@"aba")
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"equalTo succeding if matching", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).equalTo(@"BCd")
        }];
        [[theValue(result)should] beTrue];
      });


      it(@"max failing if bigger number", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).max(2)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"max succeding if equal number", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).max(2)
        }];
        [[theValue(result)should] beTrue];
      });


      it(@"min failing if too small number", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).min(4)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"min succeding if equal number", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).min(2)
        }];
        [[theValue(result)should] beTrue];
      });


      it(@"range failing if outside range", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).range(1, 2)
        }];
        [[theValue(result) should] beFalse];
      });

      it(@"range succeding if contained in range", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).range(1, 4)
        }];
        [[theValue(result) should] beTrue];
      });

      it(@"range succeding even in mismatched min/max", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).range(4, 1)
        }];
        [[theValue(result) should] beTrue];
      });
    });
  });

  SPEC_END