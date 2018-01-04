//
//  AppDelegate.h
//  Productivity Helper
//
//  Created by Nimit Sohoni on 10/28/15.
//  Copyright © 2015 Nimit Sohoni. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PreferencesController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    @private PreferencesController *prefController;
}

@property (weak) IBOutlet NSButton *workButton;
@property (weak) IBOutlet NSButton *breakButton;
@property (weak) IBOutlet NSButton *slackButton;
@property (weak) IBOutlet NSTextField *timeText;
- (IBAction)showStatistics:(id)sender;
- (IBAction)startWork:(id)sender;
- (IBAction)startBreak:(id)sender;
- (IBAction)startSlack:(id)sender;
- (IBAction)openPreferences:(id)sender;

@end
