#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"
#import "TestObject.h"

SPEC_BEGIN(KZPropertyMapperValidatorSpec)
  describe(@"Mapper", ^{
    context(@"while validating", ^{

      it(@"should fail isRequired validator if property is missing", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"Some Cool Video"} toInstance:[TestObject new] usingMapping:@{
          @"videoURL" : KZMapT([TestObject new], URL, contentURL).isRequired()
        }];
        [[theValue(result) should] beFalse];
      });

      it(@"should succed isRequired validator if ok", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"videoURL" : @"http://test.com/video.mp4"} toInstance:[TestObject new] usingMapping:@{
          @"videoURL" : KZMapT([TestObject new], URL, contentURL).isRequired()
        }];
        [[theValue(result) should] beTrue];
      });

      it(@"should fail lengthRange validator if missing", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"videoType" : [NSNull null]} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).lengthRange(5, 10)
        }];

        [[theValue(result)should] beFalse];
      });

      it(@"should fail lengthRange validator if outside range", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"Some Cool Video dsadsa dsa dsa"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).lengthRange(5, 10)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed lengthRange validator if ok", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"Some Cool"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).lengthRange(5, 11)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"should succed regex validator if ok", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BC"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).matchesRegEx([NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b" options:NSRegularExpressionCaseInsensitive error:nil])
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"should fail regex validator if doens't match", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).matchesRegEx([NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b" options:NSRegularExpressionCaseInsensitive error:nil])
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should fail length validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).length(10)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed length validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).length(3)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"should fail minLength validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).minLength(10)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed minLength validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).minLength(3)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"should fail maxLength validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).maxLength(2)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed maxLength validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).maxLength(3)
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"should fail oneOf validator if not found", ^{

        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).oneOf(@[@"aba", @"baba"])
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed oneOf validator if wrong length", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).oneOf(@[@"BCd", @"baba"])
        }];
        [[theValue(result)should] beTrue];
      });

      it(@"should fail equalTo", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd", @"videoType" : [NSNull null], @"sub_object" : @{@"title" : @616}} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).equalTo(@"aba")
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed equalTo", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"name" : @"BCd"} toInstance:[TestObject new] usingMapping:@{
          @"name" : KZPropertyT([TestObject new], title).equalTo(@"BCd")
        }];
        [[theValue(result)should] beTrue];
      });


      it(@"should fail max", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).max(2)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed max", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).max(2)
        }];
        [[theValue(result)should] beTrue];
      });


      it(@"should fail min", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).min(4)
        }];
        [[theValue(result)should] beFalse];
      });

      it(@"should succed min", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).min(2)
        }];
        [[theValue(result)should] beTrue];
      });


      it(@"should fail range", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @3} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).range(1, 2)
        }];
        [[theValue(result) should] beFalse];
      });

      it(@"should succed range", ^{
        BOOL result = [KZPropertyMapper mapValuesFrom:@{@"number" : @2} toInstance:[TestObject new] usingMapping:@{
          @"number" : KZPropertyT([TestObject new], number).range(1, 4)
        }];
        [[theValue(result) should] beTrue];
      });

//! TODO: add reverse range test
    });
  });

  SPEC_END