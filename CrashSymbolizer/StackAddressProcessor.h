//
//  StackAddressProcessor.h
//  CrashSymbolizer
//
//  Created by likid1412 on 1/8/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kAppFilePath @"kAppFilePath"
#define kArmv @"kArmv"

typedef id (^WriteReadTempFileBlock)(NSString *tempFile);

@interface StackAddressProcessor : NSObject

/*
 @fn 获取应用名称

 @param appFilePath 待解析的应用路径

 @ret 应用名称
 */
+ (NSString *)getAppName:(NSString *)appFilePath;

/*
 @fn 符号化崩溃日志

 @param report 崩溃日志字符串
 @param params 参数 @{kAppFilePath: 崩溃应用的路径, kArmv: 架构（一般为 armv7 / armv7s)

 @ret 符号化后的日志
 */
- (void)symbolizeCrashReport:(NSString *)report params:(NSDictionary *)params completion:(void (^)(NSString *symbolization))completion;

@end

/*
 0   CoreFoundation                	0x3345929e __exceptionPreprocess + 158
 1   libobjc.A.dylib               	0x3b17697a objc_exception_throw + 26
 2   CoreFoundation                	0x3345ce02 -[NSObject(NSObject) doesNotRecognizeSelector:] + 166
 3   CoreFoundation                	0x3345b52c ___forwarding___ + 388
 4   CoreFoundation                	0x333b2f64 _CF_forwarding_prep_0 + 20
 5   MyApp                        	0x000760c6 0x4f000 + 159942
 6   UIKit                         	0x352c1ad4 -[UIApplication _handleDelegateCallbacksWithOptions:isSuspended:restoreState:] + 248
 7   UIKit                         	0x352c165e -[UIApplication _callInitializationDelegatesForURL:payload:suspended:] + 1186
 8   UIKit                         	0x352b9846 -[UIApplication _runWithURL:payload:launchOrientation:statusBarStyle:statusBarHidden:] + 694
 9   BaiduInputMethod.dylib        	0x006e34d0 0x5c0000 + 1193168
 10  UIKit                         	0x35261c34 -[UIApplication handleEvent:withNewEvent:] + 1000
 11  UIKit                         	0x352616c8 -[UIApplication sendEvent:] + 68
 12  BaiduInputMethod.dylib        	0x006e402e 0x5c0000 + 1196078
 13  UIKit                         	0x35261116 _UIApplicationHandleEvent + 6150
 14  GraphicsServices              	0x36f7759e _PurpleEventCallback + 586
 15  GraphicsServices              	0x36f771ce PurpleEventCallback + 30
 16  CoreFoundation                	0x3342e16e __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 30
 17  CoreFoundation                	0x3342e112 __CFRunLoopDoSource1 + 134
 18  CoreFoundation                	0x3342cf94 __CFRunLoopRun + 1380
 19  CoreFoundation                	0x3339feb8 CFRunLoopRunSpecific + 352
 20  CoreFoundation                	0x3339fd44 CFRunLoopRunInMode + 100
 21  UIKit                         	0x352b8480 -[UIApplication _run] + 664
 22  UIKit                         	0x352b52fc UIApplicationMain + 1116
 23  MyApp                        	0x000736cc 0x4f000 + 149196
 24  MyApp                        	0x00051714 0x4f000 + 10004
 */