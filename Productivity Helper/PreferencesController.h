//
//  PreferencesController.h
//  Productivity Helper
//
//  Created by Nimit Sohoni on 3/23/16.
//  Copyright © 2016 Nimit Sohoni. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController

@property (weak) IBOutlet NSButton *checkbox;
- (IBAction)toggleCheckbox:(id)sender;
- (bool)showSeconds;

@end
