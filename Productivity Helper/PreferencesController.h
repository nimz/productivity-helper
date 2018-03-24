//
//  PreferencesController.h
//  Productivity Helper
//
//  Created by Nimit Sohoni on 3/23/16.
//  Copyright © 2016 Nimit Sohoni. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController

@property (weak) IBOutlet NSButton *secondsCheckbox;
@property (weak) IBOutlet NSButton *confirmCheckbox;
@property (weak) IBOutlet NSButton *highlightCheckbox;
- (IBAction)toggleSecondsCheckbox:(id)sender;
- (IBAction)toggleConfirmCheckbox:(id)sender;
- (IBAction)toggleHighlightCheckbox:(id)sender;
- (bool)showSeconds;
- (bool)doConfirm;
- (bool)doHighlight;
- (void)initializePrefs:(NSString *)aPrefsFile createNew:(bool)doCreate;

@end
