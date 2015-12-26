//
//  MainWindowViewModel.h
//  CrashSymbolizer
//
//  Created by Likid on 12/7/15.
//  Copyright © 2015 likid1412. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MainWindowViewModel : NSObject

- (void)symbolizeOnCompletion:(void (^)(NSAttributedString *attr))block;

- (void)showFilePanel;

- (void)logError:(NSString *)msg;

@end
