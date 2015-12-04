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

@interface CrashSymbolizerAppDelegate () <NSOpenSavePanelDelegate>

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
    [self.armComboBox selectItemAtIndex:0];
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
        
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appFilePath error:&error];
        if (contents == nil) {
            if (error) {
                [self logError:error.localizedDescription];
            } else {
                [self logError:[NSString stringWithFormat:@"%@ is an empty directory!!", appFilePath]];
            }
            return;
        }
        
        appFilePath = [appFilePath stringByAppendingPathComponent:contents.firstObject];
    }

    DLog(@"appFilePath: %@", appFilePath);

    NSString *arm = self.armComboBox.objectValueOfSelectedItem;
    if ([self isValidARM:arm] == NO)
    {
        [self logError:[NSString stringWithFormat:@"'arm' argument shuold be one of the following valid arm: \n%@", self.ARMs]];
        return;
    }
    
    // clear up
    [self.resultTextView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.processor symbolizeCrashReport:self.argumentsTextView.textStorage.string
                                      params:@{kAppFilePath: appFilePath, kArmv: arm}
                                  completion:^(NSString *symbolization) {
                                      DLog(@"symbolizations: %@", symbolization);
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          
                                          NSAttributedString *as = [[NSAttributedString alloc] initWithString:[symbolization stringByAppendingString:@"\n"]];
                                          [self.resultTextView.textStorage appendAttributedString:as];
                                      });
                                  }];
        
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
        
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
        
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        
        [[self.resultTextView textStorage] appendAttributedString:as];
        [self scrollToBottom];
    });
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

- (void)showFilePanel {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.delegate = self;
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.allowedFileTypes = @[@"dSYM", @""];
    openPanel.treatsFilePackagesAsDirectories = YES;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        NSLog(@"%ld", (long)result);
    }];
}

#pragma mark - NSOpenSavePanelDelegate

/* Optional - enabled URLs.
 NSOpenPanel: Return YES to allow the 'url' to be enabled in the panel. Delegate implementations should be fast to avoid stalling the UI. Applications linked on Mac OS 10.7 and later should be prepared to handle non-file URL schemes.
 NSSavePanel: This method is not called; all urls are always disabled.
 */
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
    NSLog(@"%s url:%@", __FUNCTION__, url);
    return YES;
}

/* Optional - URL validation for saving and opening files.
 NSSavePanel: The method is called once by the save panel when the user chooses the Save button. The user is intending to save a file at 'url'. Return YES if the 'url' is a valid location to save to. Note that an item at 'url' may not physically exist yet, unless the user decided to overwrite an existing item. Return NO and fill in the 'outError' with a user displayable error message for why the 'url' is not valid. If a recovery option is provided by the error, and recovery succeeded, the panel will attempt to close again.
 NSOpenPanel: The method is called once for each selected filename (or directory) when the user chooses the Open button. Return YES if the 'url' is acceptable to open. Return NO and fill in the 'outError' with a user displayable message for why the 'url' is not valid for opening. You would use this method over panel:shouldEnableURL: if the processing of the selected item takes a long time. If a recovery option is provided by the error, and recovery succeeded, the panel will attempt to close again.
 */
- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    NSLog(@"%s url:%@", __FUNCTION__, url);
    
    self.appFilePathTextField.stringValue = url.path;
    return YES;
}

/* Optional - Sent when the user has changed the selected directory to the directory located at 'url'. 'url' may be nil, if the current directory can't be represented by an NSURL object (ie: the media sidebar directory, or the "Computer").
 */
- (void)panel:(id)sender didChangeToDirectoryURL:(nullable NSURL *)url {
        NSLog(@"%s url:%@", __FUNCTION__, url);
}

/* Optional - Filename customization for the NSSavePanel. Allows the delegate to customize the filename entered by the user, before the extension is appended, and before the user is potentially asked to replace a file.
 */
- (nullable NSString *)panel:(id)sender userEnteredFilename:(NSString *)filename confirmed:(BOOL)okFlag {
        NSLog(@"%s filename:%@", __FUNCTION__, filename);
    return filename;
}

/* Optional - Sent when the user clicks the disclosure triangle to expand or collapse the file browser while in NSOpenPanel.
 */
- (void)panel:(id)sender willExpand:(BOOL)expanding {
        NSLog(@"%s url:%d", __FUNCTION__, expanding);
}

/* Optional - Sent when the user has changed the selection.
 */
- (void)panelSelectionDidChange:(nullable id)sender {
        NSLog(@"%s sender:%@", __FUNCTION__, sender);
}



@end
