//
//  StackAddressProcessor.m
//  CrashSymbolizer
//
//  Created by likid1412 on 1/8/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "StackAddressProcessor.h"

#import "TaskManager.h"

@interface StackAddressProcessor ()

@property (strong, nonatomic) NSDictionary *params;
@property (assign, nonatomic) unsigned int vmAddr;

@end

@implementation StackAddressProcessor


- (NSString *)symbolizeCrashReport:(NSString *)report params:(NSDictionary *)params
{
    NSString *ret = nil;
    
    NSString *appFilePath = params[kAppFilePath];
    if (appFilePath.length == 0)
    {
        ret = @"appFilepath is nil or length is zero";
        return ret;
    }

    NSString *armv = params[kArmv];
    if (armv.length == 0)
    {
        ret = @"armv is nil or length is zero";
        return ret;
    }

    self.params = params;

    NSArray *encodedAddrs = [self processCrashReport:report];

    NSError *error = nil;
    // 先找到 vmAddr，再进行符号化
    [self findVMAddr:&error];

    if (error)
    {
        return error.localizedDescription;
    }

    // 解码
    __weak StackAddressProcessor *selfObj = self;
    __weak NSMutableArray *decodedStrings = [NSMutableArray arrayWithCapacity:encodedAddrs.count];


    [encodedAddrs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *addr = obj;
        NSString *key = addr.allKeys.lastObject;
        NSString *value = addr.allValues.lastObject;

        NSError *sError = nil;
        NSString *symbolizedString = [selfObj symbolize:key error:&sError];
        if (symbolizedString == nil)
        {
            *stop = YES;
            [AppDelegate logError:sError.localizedDescription];
        }

        [decodedStrings addObject:[NSString stringWithFormat:@"%@ %@", value, symbolizedString]];
    }];

    return [decodedStrings componentsJoinedByString:@"\n"];
}

/*
 @fn 获取虚拟地址

 @ret 虚拟地址
 */
- (NSString *)generateVMAddr:(NSError **)error
{
    NSString *VMAddr = [[TaskManager sharedManager] executeTask:[self path:@"otool"]
                                                      arguments:@[@"-arch", self.params[kArmv], @"-l", self.params[kAppFilePath]] error:error];


    return VMAddr;
}

/*
 @fn 符号化栈地址，返回符号化的字符串

 @param stackAddr 栈地址

 @ret 符号化后的字符串，若地址没错，正常为函数名
 */
- (NSString *)symbolize:(NSString *)stackAddr error:(NSError **)error
{
    NSString *stringOfRMAddr = [self generateRMAddrViaStackAddr:stackAddr];

    //atos -arch $2 -o $1 $stack_address
    NSString *symbolization = [[TaskManager sharedManager] executeTask:@"/Applications/Xcode.app/Contents/Developer/usr/bin/atos"
                                                             arguments:@[@"-arch",
                                                                         self.params[kArmv],
                                                                         @"-o",
                                                                         self.params[kAppFilePath],
                                                                         stringOfRMAddr]
                                                                 error:error];

    return symbolization;
}

- (NSString *)path:(NSString *)command
{
    return [NSString stringWithFormat:@"/usr/bin/%@", command];
}

/*
 @fn 获取虚拟内存地址
 */
- (void)findVMAddr:(NSError **)error
{
    NSString *VMAddr = [self generateVMAddr:error];

    if (VMAddr == nil)
    {
        return;
    }

    NSString *grepResult =
    [self writeAndReadWithTempFile:VMAddr task:^id (NSString *tempFile) {
        return [[TaskManager sharedManager] executeTask:[self path:@"grep"]
                                              arguments:@[@"-A", @"1", @"-m", @"2", @"__TEXT", tempFile]
                                                  error:error];
    }];

    if (grepResult == nil)
    {
        return;
    }

    NSArray *components = [grepResult componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    grepResult = nil;
    //    DLog(@"components: %@", components);

    __block NSUInteger indexOfVmaddr = 0;
    [components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *string = obj;
        if ([string hasPrefix:@"0x"])
        {
            indexOfVmaddr = idx;
            *stop = YES;
        }
    }];

    NSString *stringOfVMAddr = components[indexOfVmaddr];

    NSScanner *scanner = [NSScanner scannerWithString:stringOfVMAddr];
    unsigned int vmaddr = 0;
    [scanner scanHexInt:&vmaddr];
    self.vmAddr = vmaddr;

    DLog(@"vmaddr: %@(16), %d(10)", stringOfVMAddr, self.vmAddr);
}

/*
 @fn 生成实际内存地址
 
 @param stackAddr 栈地址
 
 @ret 实际内存地址
 */
- (NSString *)generateRMAddrViaStackAddr:(NSString *)stackAddr
{
    NSScanner *scanner = [NSScanner scannerWithString:stackAddr];
    int stackAddress = 0;
    [scanner scanInt:&stackAddress];

    int rmAddr = stackAddress + self.vmAddr;

    DLog(@"vmaddr: %x, stackaddr: %x, realaddr: %x", self.vmAddr, stackAddress, rmAddr);

    return [NSString stringWithFormat:@"%x", rmAddr];
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
        if (AppDelegate.shouldShowAllInfos)
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

- (NSString *)writeAndReadWithTempFile:(NSString *)string task:(WriteReadTempFileBlock)block
{
    NSString *tempFile = @"/Users/hower_new/Desktop/tempFile.txt";
    [string writeToFile:tempFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];

    NSString *ret = block(tempFile);

    [[NSFileManager defaultManager] removeItemAtPath:tempFile error:NULL];

    return ret;
}

@end
