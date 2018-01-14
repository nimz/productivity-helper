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

@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *changeButton;
@property (weak) IBOutlet NSButton *breakButton;
@property (weak) IBOutlet NSButton *slackButton;
@property (weak) IBOutlet NSTextField *timeText;
@property (weak) IBOutlet NSTextField *overallText;
@property (weak) IBOutlet NSMenuItem *startMenuItem;
@property (weak) IBOutlet NSMenuItem *changeMenuItem;
@property (weak) IBOutlet NSMenuItem *slackMenuItem;
@property (weak) IBOutlet NSMenuItem *breakMenuItem;
- (IBAction)showStatistics:(id)sender;
- (IBAction)openStatisticsFile:(id)sender;
- (IBAction)openReadme:(id)sender;
- (IBAction)startSession:(id)sender;
- (IBAction)startSlack:(id)sender;
- (IBAction)startBreak:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)changeActivity:(id)sender;

@end

