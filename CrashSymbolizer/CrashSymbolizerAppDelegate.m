//
//  CrashSymbolizerAppDelegate.m
//  CrashSymbolizer
//
//  Created by likid1412 on 31/7/13.
//  Copyright (c) 2013 likid1412. All rights reserved.
//

#import "CrashSymbolizerAppDelegate.h"

#import "StackAddressProcessor.h"

@interface CrashSymbolizerAppDelegate ()

@property (retain, nonatomic) StackAddressProcessor *processor;

@end

@implementation CrashSymbolizerAppDelegate

- (StackAddressProcessor *)processor
{
    if (_processor == nil)
        _processor = [[StackAddressProcessor alloc] init];

    return _processor;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.appFilePathTextField setStringValue:@"/Users/hower_new/Desktop/CaiYun"];
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
    NSString *appFilePath = self.appFilePathTextField.stringValue;
    if ( ![appFilePath isAbsolutePath])
    {
        [self logError:[NSString stringWithFormat:@"%@, file path is not an absolutePath", appFilePath]];
        return;
    }

    if ( ![[NSFileManager defaultManager] fileExistsAtPath:appFilePath])
    {
        [self logError:[NSString stringWithFormat:@"file does not exist at path: %@", appFilePath]];
        return;
    }

    NSString *armv = self.archTextField.stringValue;
    if ( ![armv isEqualToString:@"armv7"] && ![armv isEqualToString:@"armv7s"])
    {
        [self logError:[NSString stringWithFormat:@"'armv' argument shuold be armv7/armv7s"]];
        return;
    }

    NSString *symbolizations = [self.processor symbolizeCrashReport:self.argumentsTextView.textStorage.string
                                                             params:@{kAppFilePath: appFilePath, kArmv: armv}];
    DLog(@"symbolizations: %@", symbolizations);

	NSAttributedString *as = [[NSAttributedString alloc] initWithString:symbolizations];
    [self.resultTextView.textStorage setAttributedString:as];
    [as release];
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

@end
