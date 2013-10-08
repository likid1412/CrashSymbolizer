//
//  TaskManager.h
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ReadDataCompletion) (NSString *resultString);

@interface TaskManager : NSObject

+ (TaskManager *)sharedManager;
- (NSString *)executeTask:(NSString *)command arguments:(NSArray *)arguments;

@end
