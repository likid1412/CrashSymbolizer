//
//  MainWindowViewModel.m
//  CrashSymbolizer
//
//  Created by Likid on 12/7/15.
//  Copyright © 2015 likid1412. All rights reserved.
//

#import "MainWindowViewModel.h"
#import "StackAddressProcessor.h"
#import "TaskManager.h"

@interface MainWindowViewModel () <NSOpenSavePanelDelegate>

@property (strong, nonatomic) StackAddressProcessor *processor;
@property (strong, nonatomic) NSArray *ARMs;

@end

@implementation MainWindowViewModel

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

#pragma mark - Public

- (void)symbolizeOnCompletion:(void (^)(NSAttributedString *))block {
    
    if ([self isValidFilePath] == NO)
    {
        return;
    }
    
    NSString *appFilePath = AppDelegateInstance().appFilePathTextView.string;
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
    
    NSString *arm = AppDelegateInstance().armComboBox.objectValueOfSelectedItem;
    if ([self isValidARM:arm] == NO)
    {
        [self logError:[NSString stringWithFormat:@"'arm' argument shuold be one of the following valid arm: \n%@", self.ARMs]];
        return;
    }
    
    // clear up
    [AppDelegateInstance().resultTextView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.processor symbolizeCrashReport:AppDelegateInstance().argumentsTextView.textStorage.string
                                      params:@{kAppFilePath: appFilePath, kArmv: arm}
                                  completion:^(NSString *symbolization) {
                                      DLog(@"symbolizations: %@", symbolization);
                                      
                                      if (block) {
                                          NSAttributedString *as = [[NSAttributedString alloc] initWithString:[symbolization stringByAppendingString:@"\n"]];
                                          block(as);
                                      }
                                  }];
        
    });
}

- (void)showFilePanel {

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.delegate = self;
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.allowedFileTypes = @[@"dSYM", @""];
    openPanel.treatsFilePackagesAsDirectories = YES;
    
    [openPanel beginSheetModalForWindow:AppDelegateInstance().window completionHandler:^(NSInteger result) {
        NSLog(@"%ld", (long)result);
    }];
}

- (void)logError:(NSString *)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
        ELog(paragraph);
        
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
        
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
        
        [[AppDelegateInstance().resultTextView textStorage] appendAttributedString:as];
        [AppDelegateInstance() scrollToBottom];
    });
}


#pragma mark - NSOpenSavePanelDelegate

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    NSLog(@"%s url:%@", __FUNCTION__, url);
    
    AppDelegateInstance().appFilePathTextView.string = url.path;
    return YES;
}

#pragma mark - Private

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
    NSString *appFilePath = AppDelegateInstance().appFilePathTextView.string;
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
    [[NSUserDefaults standardUserDefaults] setObject:AppDelegateInstance().appFilePathTextView.string forKey:CSKeyAppFilePath];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}


@end
