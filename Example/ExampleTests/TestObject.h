//
//  Created by merowing on 08/10/2013.
//
//
//


#import <Foundation/Foundation.h>


@interface TestObject : NSObject
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) id type;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *uniqueID;
@property(nonatomic, strong) NSNumber *number;

- (BOOL)updateFromDictionary:(NSDictionary *)dictionary;
- (id)passthroughMethod:(id)object;

@end