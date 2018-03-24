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
NSArray *prefList = nil;

NSString *_prefsFile; // avoid name clash
// could also resolve with the following (but not doing so for now):
// https://stackoverflow.com/questions/2264455/iphone-duplicate-symbol-error

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setCheckboxes];
    init = true;
    NSWindow *prefWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:1];
    [[prefWindow standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    [prefWindow setTitle:@"Preferences"];
}

- (void) setCheckboxes {
    [_secondsCheckbox setState:(showSec ? NSOnState : NSOffState)];
    [_confirmCheckbox setState:(confirm ? NSOnState : NSOffState)];
    [_highlightCheckbox setState:(highlight ? NSOnState : NSOffState)];
}

- (IBAction)toggleSecondsCheckbox:(id)sender {
    NSLog(@"Toggled seconds checkbox\n");
    showSec = !showSec;
    [self writePrefs];
}

- (IBAction)toggleConfirmCheckbox:(id)sender {
    NSLog(@"Toggled confirm checkbox\n");
    confirm = !confirm;
    [self writePrefs];
}

- (IBAction)toggleHighlightCheckbox:(id)sender {
    NSLog(@"Toggled highlight checkbox\n");
    highlight = !highlight;
    [self writePrefs];
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

- (void)initializePrefs:(NSString *)aPrefsFile createNew:(bool)doCreate {
    _prefsFile = aPrefsFile;
    if (prefList == nil)
        prefList = @[@"show_seconds", @"confirm_stop", @"highlight_active"];
    if (doCreate) {
        [self writePrefs];
    }
    else { // load preferences
        NSString *existingPrefs = [NSString stringWithContentsOfFile:_prefsFile
                                   encoding:NSUTF8StringEncoding error:NULL];
        NSLog(@"%@", existingPrefs);
        NSArray<NSString *> *lines = [existingPrefs componentsSeparatedByString:@"\n"];
        if ([lines count] < 3) { // malformed preferences file
            [self writePrefs]; // rewrite preferences
        }
        else {
            showSec = [self extractFlag:lines[0]];
            confirm = [self extractFlag:lines[1]];
            highlight = [self extractFlag:lines[2]];
            [self setCheckboxes];
        }
    }
}

- (bool)extractFlag:(NSString *)str {
    str = [str stringByTrimmingCharactersInSet:
           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    str = [str substringFromIndex:[str length]-1];
    return [str boolValue];
}

- (void)writePrefs {
    NSString *outputStr = [NSString stringWithFormat:@"%@:%i\n%@:%i\n%@:%i",
                           prefList[0], showSec, prefList[1], confirm,
                           prefList[2], highlight];
    NSData *data = [outputStr dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:_prefsFile atomically:YES];
}

@end
