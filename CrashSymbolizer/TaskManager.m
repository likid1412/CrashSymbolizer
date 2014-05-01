//
//  TaskManager.m
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "TaskManager.h"

NSString * const LKTaskErrorDomain = @"LKTaskErrorDomain";

@interface TaskManager ()


@end

@implementation TaskManager

+ (instancetype)sharedManager
{
    static TaskManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[TaskManager alloc] init];
    });
    return _sharedManager;
}

- (NSTask *)taskWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = launchPath;
    task.arguments = arguments;

    return task;
}

- (id)init
{
    if (self = [super init])
    {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidTermination:) name:NSTaskDidTerminateNotification object:nil];
    }

    return self;
}

- (NSString *)executeTask:(NSString *)command arguments:(NSArray *)arguments error:(NSError **)error
{
    NSTask *task = [self taskWithLaunchPath:command arguments:arguments];
    DLog(@"task: %@", [NSString stringWithFormat:@"%@ %@", command, [arguments componentsJoinedByString:@" "]]);

    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];

    [task setStandardOutput:outputPipe];
    [task setStandardError:errorPipe];
    
    NSFileHandle *outputFile = [outputPipe fileHandleForReading];
    NSFileHandle *errorFileHandle = [errorPipe fileHandleForReading];

    [task launch];
//    task.terminationHandler = ^ (NSTask *task){
//        DLog();
//    };

    NSString *errorString = [[NSString alloc] initWithData:[errorFileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];

    if (errorString.length)
    {
        DLog(@"error: %@", errorString);

        if (error)
        {
            *error = [NSError errorWithDomain:LKTaskErrorDomain code:LKErrorCodeTaskError userInfo:@{ NSLocalizedDescriptionKey: errorString }];
        }

        return nil;
    }

    NSString *outputResult = [[NSString alloc] initWithData:[outputFile readDataToEndOfFile] encoding: NSUTF8StringEncoding];
    return outputResult;
}

//- (void)taskDidTermination:(NSNotification *)notification
//{
//    NSTask *object = notification.object;
//
//    DLog(@"class:%@, content: \n%@", [object class], object.launchPath);
//}

@end
