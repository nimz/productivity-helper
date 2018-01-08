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

bool init = false, showSec = true;

- (void)windowDidLoad {
    [super windowDidLoad];
    init = true;
    NSWindow *prefWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:1];
    [[prefWindow standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    [prefWindow setTitle:@"Preferences"];
}

- (IBAction)toggleCheckbox:(id)sender {
    NSLog(@"Toggled seconds checkbox\n");
    showSec = !showSec;
}

- (bool)showSeconds {
    return showSec;
}

- (bool)initialized {
    return init;
}

@end
