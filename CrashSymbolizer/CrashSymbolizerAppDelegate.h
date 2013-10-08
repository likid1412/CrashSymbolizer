//
//  CrashSymbolizerAppDelegate.h
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CrashSymbolizerAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextView *argumentsTextView;
@property (assign) IBOutlet NSTextView *resultTextView;
@property (assign) IBOutlet NSTextField *archTextField;
@property (assign) IBOutlet NSTextField *appFilePathTextField;
@property (assign) IBOutlet NSButton *checkBoxForShowAllInfos;
@property (assign, nonatomic) BOOL shouldShowAllInfos;

- (IBAction)showAllInfos:(NSButton *)sender;
- (IBAction)transfer:(NSButton *)sender;

@end
