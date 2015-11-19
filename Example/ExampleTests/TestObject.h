//
//  Created by merowing on 08/10/2013.
//
//
//


#import <Foundation/Foundation.h>

@protocol TestProtocol <NSObject>
@property (nonatomic, readonly) id value;
@end
extern id<TestProtocol> TestProtocolCreate(id value);
@class ConcreteTestProtocol;

@interface TestObject : NSObject
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) id type;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *subtitle;
@property(nonatomic, strong) NSNumber *uniqueID;
@property(nonatomic, strong) NSNumber *number;
@property(nonatomic, assign) int intNumber;
@property(nonatomic, assign) float floatNumber;
@property(nonatomic, assign) BOOL isCheap;
@property(nonatomic, assign) BOOL isExpensive;
@property (nonatomic) id<TestProtocol> dependency_as_id;
@property (nonatomic) NSObject<TestProtocol>* dependency_as_nsobject;
@property (nonatomic) ConcreteTestProtocol *dependency_as_concrete_type;

- (BOOL)updateFromDictionary:(NSDictionary *)dictionary;
- (id)passthroughMethod:(id)object;

@end

@interface ConcreteTestProtocol : NSObject<TestProtocol>
- (instancetype)initWithValue:(id)value;
@end
