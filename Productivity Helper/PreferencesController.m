//
//  PreferencesController.m
//  Productivity Helper
//
//  Created by Nimit Sohoni on 3/23/16.
//  Copyright © 2016 Nimit Sohoni. All rights reserved.
//

#import "PreferencesController.h"

@interface PreferencesController ()

@end

@implementation PreferencesController

bool init = false, showSec = true, confirm = false, highlight = false;

- (void)windowDidLoad {
    [super windowDidLoad];
    [_confirmCheckbox setState:NSOffState];
    [_highlightCheckbox setState:NSOffState];
    init = true;
    NSWindow *prefWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:1];
    [[prefWindow standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    [prefWindow setTitle:@"Preferences"];
}

- (IBAction)toggleSecondsCheckbox:(id)sender {
    NSLog(@"Toggled seconds checkbox\n");
    showSec = !showSec;
}

- (IBAction)toggleConfirmCheckbox:(id)sender {
    NSLog(@"Toggled confirm checkbox\n");
    confirm = !confirm;
}

- (IBAction)toggleHighlightCheckbox:(id)sender {
    NSLog(@"Toggled highlight checkbox\n");
    highlight = !highlight;
}

- (bool)showSeconds {
    return showSec;
}

- (bool)doConfirm {
    return confirm;
}

- (bool)doHighlight {
    return highlight;
}

- (bool)initialized {
    return init;
}

@end
