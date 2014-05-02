//
//  CrashSymbolizerAppDelegate.m
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "CrashSymbolizerAppDelegate.h"

#import "StackAddressProcessor.h"
#import "TaskManager.h"

NSString * const CSDefaultAppFilePath = @"~/Desktop";
NSString * const CSKeyAppFilePath = @"AppFilePath";

@interface CrashSymbolizerAppDelegate ()

@property (strong, nonatomic) StackAddressProcessor *processor;
@property (strong, nonatomic) NSArray *ARMs;

@end

@implementation CrashSymbolizerAppDelegate

- (StackAddressProcessor *)processor
{
    if (_processor == nil)
    {
        _processor = [[StackAddressProcessor alloc] init];
    }

    return _processor;
}

- (NSArray *)ARMs
{
    if (_ARMs == nil)
    {
        _ARMs = [[NSArray alloc] initWithObjects:@"armv7", @"armv7s", @"arm64", nil];
    }

    return _ARMs;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *filePath = [[NSUserDefaults standardUserDefaults] objectForKey:CSKeyAppFilePath];

    if (filePath.length == 0)
    {
        filePath = CSDefaultAppFilePath;
    }

    [self.appFilePathTextField setStringValue:filePath];
    [self.archTextField setStringValue:@"armv7"];
    self.checkBoxForShowAllInfos.state = NSOffState;
}

- (IBAction)showAllInfos:(NSButton *)sender
{
    self.shouldShowAllInfos = sender.state;
    DLog(@"%ld", (long)sender.state);
}

- (IBAction)transfer:(NSButton *)sender
{
    if ([self isValidFilePath] == NO)
    {
        return;
    }
    NSString *appFilePath = self.appFilePathTextField.stringValue;
    if ( ![appFilePath isAbsolutePath])
    {
        [self logError:[NSString stringWithFormat:@"%@, file path is not an absolutePath", appFilePath]];
        return;
    }

    if ([appFilePath hasPrefix:@"~/"])
    {
        NSString *userName = [[TaskManager sharedManager] executeTask:@"/usr/bin/id" arguments:@[@"-un"] error:nil];

        // user command "/user/bin/id -un", result has a \n char at the end, so remove the last word
        userName = [userName substringToIndex:userName.length - 1];

        appFilePath = [appFilePath stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                           withString:[NSString stringWithFormat:@"/Users/%@", userName]];

        DLog(@"userDocument:%@", userName);
    }

    if ([appFilePath hasSuffix:@".dSYM"])
    {
        //MyApp.app.dSYM/Contents/Resources/DWARF
        appFilePath = [appFilePath stringByAppendingPathComponent:@"Contents/Resources/DWARF"];
    }

    DLog(@"appFilePath: %@", appFilePath);

//    if ( ![[NSFileManager defaultManager] fileExistsAtPath:appFilePath])
//    {
//        [self logError:[NSString stringWithFormat:@"file does not exist at path: %@", appFilePath]];
//        return;
//    }

    NSString *armv = self.archTextField.stringValue;
    if ([self isValidARM:armv] == NO)
    {
        [self logError:[NSString stringWithFormat:@"'arm' argument shuold be one of the following valid arm: \n%@", self.ARMs]];
        return;
    }

    NSString *symbolizations = [self.processor symbolizeCrashReport:self.argumentsTextView.textStorage.string
                                                             params:@{kAppFilePath: appFilePath, kArmv: armv}];
    DLog(@"symbolizations: %@", symbolizations);

	NSAttributedString *as = [[NSAttributedString alloc] initWithString:symbolizations];
    [self.resultTextView.textStorage setAttributedString:as];
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

- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];

	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];

	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];

	[[self.resultTextView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (BOOL)isValidARM:(NSString *)armv
{
    __block BOOL isValidARM = NO;
    [self.ARMs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([armv isEqualToString:obj])
        {
            *stop = YES;
            isValidARM = YES;
        }
    }];

    return isValidARM;
}

- (BOOL)isValidFilePath
{
    NSString *appFilePath = self.appFilePathTextField.stringValue;
    if ( ![appFilePath isAbsolutePath])
    {
        [self logError:[NSString stringWithFormat:@"%@, file path is not an absolutePath", appFilePath]];
        return NO;
    }

    if ([appFilePath hasPrefix:@"~/"])
    {
        NSError *error = nil;

        NSString *userName = [[TaskManager sharedManager] executeTask:@"/usr/bin/id" arguments:@[@"-un"] error:&error];
        if (userName == nil)
        {
            [self logError:error.localizedDescription];
            return NO;
        }

        // user command "/user/bin/id -un", result has a \n char at the end, so remove the last word
        userName = [userName substringToIndex:userName.length - 1];

        appFilePath = [appFilePath stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                           withString:[NSString stringWithFormat:@"/Users/%@", userName]];

        DLog(@"userDocument:%@", userName);
    }

    if ([appFilePath hasSuffix:@".dSYM"])
    {
        // MyApp.app.dSYM/Contents/Resources/DWARF
        NSString *dSYMFilePath = [@"Contents/Resources/DWARF" stringByAppendingPathComponent:[StackAddressProcessor getAppName:appFilePath]];

        appFilePath = [appFilePath stringByAppendingPathComponent:dSYMFilePath];
    }

    DLog(@"appFilePath: %@", appFilePath);

    // save filePath
    [[NSUserDefaults standardUserDefaults] setObject:self.appFilePathTextField.stringValue forKey:CSKeyAppFilePath];
    [[NSUserDefaults standardUserDefaults] synchronize];

    return YES;
}

@end
