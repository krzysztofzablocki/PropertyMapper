//
// Created by Marek Cirkos on 02/04/2014.
//


#import "Kiwi.h"
#import "KZPropertyMapper.h"
#import "KZPropertyDescriptor+Validators.h"
#import <CoreData/CoreData.h>

@protocol TestObjectProtocol <NSObject>
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, assign) BOOL boolValue1;
@property (nonatomic, assign) BOOL boolValue2;

@end

@interface TestManagedObject : NSManagedObject <TestObjectProtocol>
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, assign) BOOL boolValue1;
@property (nonatomic, assign) BOOL boolValue2;
@property (nonatomic, strong) TestManagedObject *child;
@end

@implementation TestManagedObject
@synthesize stringValue;
@synthesize numberValue;
@synthesize floatValue;
@synthesize boolValue1, boolValue2;
@synthesize child;
@end

@interface HBTestObject : NSObject <TestObjectProtocol>
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, assign) BOOL boolValue1;
@property (nonatomic, assign) BOOL boolValue2;
@end

@implementation HBTestObject
@end


SPEC_BEGIN(KZPropertyMapperTypingSpec)

describe(@"Mapper", ^{
  
  
  context(nil, ^{
    __block id <TestObjectProtocol> testObject = nil;
    __block NSDictionary *mapping = nil;
    __block NSDictionary *sourceDictionary = nil;
    __block BOOL testResult = NO;
    
    beforeEach(^{
      testResult = NO;
    });
    
    afterEach(^{
      mapping = nil;
      sourceDictionary = nil;
      testObject = nil;
    });
    
    
    void (^runTestForObject)() = ^() {
      
      it(@"should parse simple type values with good mapping", ^{
        mapping = @{@"stringValue" : @"stringValue",
                    @"numberValue" : @"numberValue",
                    @"floatValue" : @"floatValue",
                    @"boolValue1" : @"boolValue1",
                    @"boolValue2" : @"boolValue2"
                    };
        
        
        sourceDictionary = @{@"stringValue" : @"stringValue",
                             @"numberValue" : @1,
                             @"floatValue" : @1.5,
                             @"boolValue1" : @YES,
                             @"boolValue2" : @NO,
                             @"urlValue" : @"@URL(contentURL)"
                             };
        [[theBlock(^{
          testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
        }) shouldNot] raise];
        [[theValue(testResult) should] beTrue];
        
        [[testObject.stringValue should] equal:@"stringValue"];
        [[testObject.numberValue should] equal:@1];
        [[theValue(testObject.floatValue) should] equal:theValue(1.5)];
        [[theValue(testObject.boolValue1) should] beYes];
        [[theValue(testObject.boolValue2) should] beNo];
        
      });

      
      context(@"when expecting simple value", ^{
        beforeEach(^{
          mapping = @{@"testValue" : @"stringValue" };
        });
        
        it(@"should work with good mapping", ^{
          sourceDictionary = @{@"testValue" : @"domek"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [[testObject.stringValue should] equal:@"domek"];
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
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle dictionary value", ^{
          sourceDictionary = @{@"testValue" : @{@"key" : @"value"}};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle array value", ^{
          sourceDictionary = @{@"testValue" : @[@"v1", @"v2"]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
      });
      
      context(@"when expecting dictionary", ^{
        beforeEach(^{
          mapping = @{@{@"key" : @"testValue"}: @"stringValue"};
        });
        
        it(@"should work with good mapping", ^{
          sourceDictionary = @{@{@"key" : @"testValue"} : @"domek"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [[testObject.stringValue should] equal:@"domek"];
        });
        
        it(@"should handle wrong path", ^{
          sourceDictionary = @{@{@"differentKey" : @"testValue"} : @"domek"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle wrong path", ^{
          sourceDictionary = @{@{@"key" : @"value"} : @"domek"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle absence of value", ^{
          sourceDictionary = @{@"differentKey" : @""};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle NULL value", ^{
          sourceDictionary = @{@"key" : [NSNull null]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle simple value", ^{
          sourceDictionary = @{@"key" : @"someValue"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle array value", ^{
          sourceDictionary = @{@"key" : @[@"v1", @"v2"]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
      });
      
      context(@"when expecting array", ^{
        beforeEach(^{
          mapping = @{ @"testValue" : @{@1 : @"stringValue"}};
        });
        
        it(@"should work with good mapping", ^{
          sourceDictionary = @{@"testValue" : @[@"v1", @"domek"]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          
          [[testObject.stringValue should] equal:@"domek"];
        });
        
        it(@"should handle index out of range", ^{
          sourceDictionary = @{@"testValue" : @[@"v1"]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle absence of value", ^{
          sourceDictionary = @{@"differentValue" : @"someValue"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle NULL value in array", ^{
          sourceDictionary = @{@"testValue" : @[@"v1", [NSNull null]]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle NULL value", ^{
          sourceDictionary = @{@"testValue" : [NSNull null]};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle simple value", ^{
          sourceDictionary = @{@"testValue" : @"value"};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
        
        it(@"should handle dictionary value", ^{
          sourceDictionary = @{@"testValue" : @{@"v1" : @"v2"}};
          [[theBlock(^{
            testResult = [KZPropertyMapper mapValuesFrom:sourceDictionary toInstance:testObject usingMapping:mapping];
          }) shouldNot] raise];
          [[theValue(testResult) should] beTrue];
          [testObject.stringValue shouldBeNil];
        });
      });
    };
    
    
    
    context(@"handling NSObject", ^{
      beforeEach(^{
        testObject = [HBTestObject new];
      });
      
      afterEach(^{
        testObject = nil;
      });
      
      runTestForObject();
    });
    
    context(@"handling NSManagedObject", ^{
      __block NSEntityDescription *stubEntity;
      __block NSManagedObjectContext *moc;
      
      beforeAll(^{
        NSString *entityName = NSStringFromClass(TestManagedObject.class);
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
        stubEntity = [[NSEntityDescription alloc] init];
        [stubEntity setName:entityName];
        [stubEntity setManagedObjectClassName:entityName];
        model.entities = @[stubEntity];
        
        moc = [NSManagedObjectContext new];
        moc.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
      });
      
      beforeEach(^{
        testObject = [[TestManagedObject alloc] initWithEntity:stubEntity insertIntoManagedObjectContext:moc];
      });
      
      afterEach(^{
        [moc deleteObject:testObject];
        testObject = nil;
      });
      
      runTestForObject();
      
    });
    
  });
});


SPEC_END