//
//  TestManagedObject.h
//  Example
//
//  Created by Marek Cirkos on 03/04/2014.
//  Copyright (c) 2014 pixle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TestObjectProtocol.h"

@interface TestManagedObject : NSManagedObject <TestObjectProtocol>
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) id type;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *uniqueID;
@property(nonatomic, strong) NSNumber *number;
@property(nonatomic, assign) int intNumber;
@property(nonatomic, assign) float floatNumber;
@property(nonatomic, assign) BOOL isCheap;
@property(nonatomic, assign) BOOL isExpensive;

@end
