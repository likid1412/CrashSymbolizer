//
//  StackAddressProcessor.m
//  CrashSymbolizer
//
//  Created by likid1412 on 1/8/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "StackAddressProcessor.h"

#import "TaskManager.h"

static NSString *kExecuteModeForShellFileKey = @"ExecuteModeForShellFileKey";

@interface StackAddressProcessor ()

@property (strong, nonatomic) NSDictionary *params;
@property (copy, nonatomic) NSNumber *isExecuteMode;

@end

@implementation StackAddressProcessor

- (NSNumber *)isExecuteMode {
    if (_isExecuteMode == nil)
    {
        BOOL mode = [[NSUserDefaults standardUserDefaults] boolForKey:kExecuteModeForShellFileKey];
        _isExecuteMode = @(mode);
    }
    
    return _isExecuteMode;
}

- (void)symbolizeCrashReport:(NSString *)report params:(NSDictionary *)params completion:(void (^)(NSString *symbolization))completion
{
    if (completion == nil) {
        return;
    }
    
    NSString *ret = nil;
    
    NSString *appFilePath = params[kAppFilePath];
    if (appFilePath.length == 0)
    {
        ret = @"appFilepath is nil or length is zero";
        completion(ret);
        
        return;
    }

    NSString *armv = params[kArmv];
    if (armv.length == 0)
    {
        ret = @"armv is nil or length is zero";
        completion(ret);
        return;
    }

    self.params = params;

    NSArray *encodedAddrs = [self processCrashReport:report];

    // 解码
    [encodedAddrs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *addr = obj;
        NSString *key = addr.allKeys.lastObject;
        NSString *value = addr.allValues.lastObject;

        NSError *sError = nil;
        NSString *symbolizedString = [self symbolize:key error:&sError];
        if (symbolizedString == nil)
        {
            *stop = YES;
            [AppDelegateInstance() logError:sError.localizedDescription];
        }

        NSString *decodedString = [NSString stringWithFormat:@"%@ %@", value, symbolizedString] ?: @"";
        completion(decodedString);
    }];
}

/*
 @fn 符号化栈地址，返回符号化的字符串

 @param stackAddr 栈地址

 @ret 符号化后的字符串，若地址没错，正常为函数名
 */
- (NSString *)symbolize:(NSString *)stackAddr error:(NSError **)error
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"symbolize" ofType:@"sh"];
    [self addExecuteModeForShellFile:path];
    
    NSString *symbolization = [[TaskManager sharedManager] executeTask:path arguments:@[self.params[kAppFilePath], self.params[kArmv], stackAddr] error:nil];
    DLog(@"symbolization: %@", symbolization);

    return symbolization;
}

/*
 @fn 获取应用名称

 @param appFilePath 待解析的应用路径

 @ret 应用名称
 */
+ (NSString *)getAppName:(NSString *)appFilePath
{
    NSString *appName = nil;
    NSString *lastPath = appFilePath.lastPathComponent;

    NSRange temp = [lastPath rangeOfString:@"."];
    if (temp.location == NSNotFound)
    {
        appName = lastPath;
    }
    else
    {
        appName = [lastPath substringToIndex:temp.location];
    }

    return appName;
//    NSRange rangeOfAppName = [appFilePath rangeOfString:@"/" options:NSBackwardsSearch];
//
//    if (rangeOfAppName.location == NSNotFound)
//    {
//        DLog(@"not found");
//        return nil;
//    }
//
//    return [appFilePath substringFromIndex:NSMaxRange(rangeOfAppName)];
}

/*
 @fn 对崩溃日志的字符串进行处理，返回需要解析的地址

 @param reportString 崩溃日志字符串

 @ret encodedAddrs @[@{待解析地址(NSString): 崩溃行(NSString)}, ...]
 */
- (NSArray *)processCrashReport:(NSString *)reportString
{
    NSString *appName = [StackAddressProcessor getAppName:self.params[kAppFilePath]];
    DLog(@"appName: %@", appName);
    // 获取每一行的内容

    NSArray *components = [reportString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    // 判断当前行是否需要解码
    // 把当前行根据空白字符截成若干段，通过判断倒数第三段字符串是否以 0x开头的地址，若是，则为需要解码的行
    NSMutableArray *encodedAddrs = [NSMutableArray array];

    for (NSString *oneLine in components)
    {
        if (oneLine.length == 0)
            continue;

        NSString *trimmedLine = [oneLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *words = [trimmedLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSMutableArray *wordsWithoutEmptyString = [NSMutableArray array];
        for (NSString *aWord in words)
        {
            if (aWord.length)
                [wordsWithoutEmptyString addObject:aWord];
        }


        BOOL isEqualToAppName = [wordsWithoutEmptyString[1] isEqualToString:appName];
        // 如果需要显示所有信息，isEqualToAppName 置为 YES
        if (AppDelegateInstance().shouldShowAllInfos)
            isEqualToAppName = YES;
        /*
         5   MyApp                        	0x000760c6 0x4f000 + 159942
         0      1                                2        3    4    5
         依次对应 wordsWithoutEmptyString[0] ~ wordsWithoutEmptyString[5]
         */

        if (wordsWithoutEmptyString.count > 4 &&
            isEqualToAppName /*
                              &&
                              ([wordsWithoutEmptyString[3] hasPrefix:@"0x"] || [wordsWithoutEmptyString[3] hasPrefix:appName])
                              */ )
        {
            [encodedAddrs addObject:@{words.lastObject: trimmedLine}];
        }
    }

    DLog(@"%@", encodedAddrs);
    return [encodedAddrs copy];
}

/**
 *  @brief  changes the permissions of the script to allow it to be executed
 
 The chmod command changes the permissions of the script to allow it to be executed by your NSTask object. 
 If you tried to run your application without these permissions in place, you’d see the same “Launch path not accessible” error as before.
 
 *
 *  @param filePath script file path
 */
- (void)addExecuteModeForShellFile:(NSString *)filePath {
    if (self.isExecuteMode.boolValue) {
        return;
    }
    
    NSError *error = nil;
    [[TaskManager sharedManager] executeTask:@"/bin/chmod" arguments:@[@"+x", filePath] error:&error];
    
    if (error) {
        [AppDelegateInstance() logError:error.localizedDescription];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kExecuteModeForShellFileKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExecuteModeForShellFileKey];
        self.isExecuteMode = @YES;
    }
}

@end
