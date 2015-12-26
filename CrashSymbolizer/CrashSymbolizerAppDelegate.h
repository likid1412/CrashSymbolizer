//
//  CrashSymbolizerAppDelegate.h
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CrashSymbolizerAppDelegate;

extern CrashSymbolizerAppDelegate *AppDelegateInstance();



FOUNDATION_EXPORT NSString * const CSDefaultAppFilePath;
FOUNDATION_EXPORT NSString * const CSKeyAppFilePath;

@interface CrashSymbolizerAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *argumentsTextView;
@property (unsafe_unretained) IBOutlet NSTextView *resultTextView;
@property (weak) IBOutlet NSComboBox *armComboBox;
@property (weak) IBOutlet NSTextField *appFilePathTextField;
@property (weak) IBOutlet NSButton *checkBoxForShowAllInfos;
@property (assign, nonatomic) BOOL shouldShowAllInfos;

- (void)scrollToBottom;
- (void)logError:(NSString *)msg;

@end
