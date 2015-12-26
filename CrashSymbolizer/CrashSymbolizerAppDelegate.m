//
//  CrashSymbolizerAppDelegate.m
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "CrashSymbolizerAppDelegate.h"

#import "MainWindowViewModel.h"

CrashSymbolizerAppDelegate *AppDelegateInstance() {
    return [NSApplication sharedApplication].delegate;
}

NSString * const CSDefaultAppFilePath = @"~/Desktop";
NSString * const CSKeyAppFilePath = @"AppFilePath";

@interface CrashSymbolizerAppDelegate () <NSOpenSavePanelDelegate>

@property (strong, nonatomic) MainWindowViewModel *viewModel;

@end

@implementation CrashSymbolizerAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *filePath = [[NSUserDefaults standardUserDefaults] objectForKey:CSKeyAppFilePath];

    if (filePath.length == 0)
    {
        filePath = CSDefaultAppFilePath;
    }

    [self.appFilePathTextField setStringValue:filePath];
    [self.armComboBox selectItemAtIndex:0];
    self.checkBoxForShowAllInfos.state = NSOffState;
    
    self.viewModel = [[MainWindowViewModel alloc] init];
}

#pragma mark - Public

- (void)logError:(NSString *)msg {
    [self.viewModel logError:msg];
}

- (void)scrollToBottom
{
    NSScrollView *scrollView = [self.resultTextView enclosingScrollView];
    NSPoint newScrollOrigin;
    
    if ([[scrollView documentView] isFlipped])
        newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
    else
        newScrollOrigin = NSMakePoint(0.0F, 0.0F);
    
    [[scrollView documentView] scrollPoint:newScrollOrigin];
}

#pragma mark - Actions

- (IBAction)showAllInfos:(NSButton *)sender
{
    self.shouldShowAllInfos = sender.state;
    DLog(@"%ld", (long)sender.state);
}

- (IBAction)transfer:(NSButton *)sender
{
    [self.viewModel symbolizeOnCompletion:^(NSAttributedString *attr) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.resultTextView.textStorage appendAttributedString:attr];
            
            [self scrollToBottom];
        });
    }];
}

- (IBAction)onTapedOpenFileButton:(NSButton *)sender {
    [self.viewModel showFilePanel];
}

#pragma mark - Private

@end
