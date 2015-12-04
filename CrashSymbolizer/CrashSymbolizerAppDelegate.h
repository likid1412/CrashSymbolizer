//
//  CrashSymbolizerAppDelegate.h
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CrashSymbolizerAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *argumentsTextView;
@property (unsafe_unretained) IBOutlet NSTextView *resultTextView;
@property (weak) IBOutlet NSComboBox *armComboBox;
@property (weak) IBOutlet NSTextField *appFilePathTextField;
@property (weak) IBOutlet NSButton *checkBoxForShowAllInfos;
@property (assign, nonatomic) BOOL shouldShowAllInfos;

- (IBAction)showAllInfos:(NSButton *)sender;
- (IBAction)transfer:(NSButton *)sender;

- (void)logError:(NSString *)msg;

@end
