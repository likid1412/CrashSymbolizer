//
//  TaskManager.m
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "TaskManager.h"

@interface TaskManager ()


@end

@implementation TaskManager

+ (TaskManager *)sharedManager
{
    static TaskManager *_sharedManager = nil;
    if (_sharedManager == nil)
    {
        _sharedManager = [[TaskManager alloc] init];
    }

    return _sharedManager;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSTask *)taskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = launchPath;
    task.arguments = arguments;

    return [task autorelease];
}

- (id)init
{
    if (self = [super init])
    {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidTermination:) name:NSTaskDidTerminateNotification object:nil];
    }

    return self;
}

- (NSString *)executeTask:(NSString *)command arguments:(NSArray *)arguments
{
    NSTask *task = [self taskWithLaunchPath:command arguments:arguments];
    DLog(@"task: %@", [NSString stringWithFormat:@"%@ %@", command, [arguments componentsJoinedByString:@" "]]);

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];

    [task launch];
    task.terminationHandler = ^ (NSTask *task){
        DLog();
    };

    // 不能使用 autorelease 奇怪 -- by Likid
    NSString *result = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding: NSUTF8StringEncoding];
    
    return result;
}

//- (void)taskDidTermination:(NSNotification *)notification
//{
//    NSTask *object = notification.object;
//
//    DLog(@"class:%@, content: \n%@", [object class], object.launchPath);
//}

@end
