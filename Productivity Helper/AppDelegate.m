//
//  AppDelegate.m
//  Productivity Helper
//
//  Created by Nimit Sohoni on 6/19/15.
//  Copyright (c) 2015 Nimit Sohoni. All rights reserved.
//
// Note: daylight savings time is not handled correctly, nor are midsession computer shutdowns

#import "AppDelegate.h"
#import "PreferencesController.h"

@implementation AppDelegate

uint PORT = 8008;

bool slacking = false, breaking = false, working = false;
bool showSecondsLast = true;

NSString *basedir = @"Productivity Helper/";
NSString *documentsDir, *statsFile, *jsFile, *redirFile, *visualizationFile,
         *mainJSFile, *d3File, *iconFile;
NSString *portString;
NSString *setupScriptPath;
NSString *killServerPath;
NSString *currentTask;

NSFileManager *fileManager;

NSTimer *timer;
NSDate *timerStart, *sessionStart;
NSDateFormatter *dateFormatter, *outputFormatter, *timerFormatter;

int initialNumDays = 0;
int prevNumDays = 0;
int numDays = 0;

+ (int)numDigitsH:(int)n {
    if (n == 0) return 0;
    return 1 + [AppDelegate numDigitsH:(n / 10)];
}

+ (int)numDigits:(int)n {
    if (n == 0) return 1;
    return [AppDelegate numDigitsH:n];
}

+ (void)updateNumDays {
    NSString *numstr = [@(numDays) stringValue];
    if ([AppDelegate numDigits:numDays] > [AppDelegate numDigits:prevNumDays]) {
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:statsFile];
        NSData *oldata = [fileHandler readDataToEndOfFile];
        NSString *str = [[NSString alloc] initWithData:oldata encoding:NSUTF8StringEncoding];
        NSRange range = [str rangeOfString:@"\n"];
        NSString *substr = [str substringFromIndex:range.location];
        substr = [NSString stringWithFormat:@"%@%@", numstr, substr];
        NSData *data = [substr dataUsingEncoding:NSUTF8StringEncoding];
        [fileHandler seekToFileOffset:0];
        [fileHandler writeData:data];
        [fileHandler closeFile];
    }
    else {
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:statsFile];
        NSData *data = [numstr dataUsingEncoding:NSUTF8StringEncoding];
        [fileHandler writeData:data];
        [fileHandler closeFile];
    }
}

+ (void)initializeDirectories {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        documentsDir = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
        statsFile = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"Statistics.txt"];
        jsFile = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"Statistics.js"];
        redirFile = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"Stats_redir.html"];
        visualizationFile = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"Stats.html"];
        mainJSFile = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"scripts/main.js"];
        d3File = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"scripts/d3.v4.min.js"];
        iconFile = [NSString stringWithFormat:@"%@%@%@", documentsDir, basedir, @"images/favicon.png"];
        fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:[documentsDir stringByAppendingString:@"Productivity Helper/images"]
               withIntermediateDirectories:true attributes:nil error:nil];
        [fileManager createDirectoryAtPath:[documentsDir stringByAppendingString:@"Productivity Helper/scripts"]
               withIntermediateDirectories:true attributes:nil error:nil];
    }
}

/** Appends text to statistics file located in the /Documents directory.
 * If file does not exist it will be created from scratch.
 * @param str String to write.
 * From http://objective-c-functions.blogspot.com/2013/09/write-and-append-text-to-file.html
 */
+ (void)writeString:(NSString *)str {
    NSString *outputStr;
    NSData *data;
    
    if ([fileManager fileExistsAtPath:statsFile]) {
        // Add the text at the end of the file.
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:statsFile];
        [fileHandler seekToEndOfFile];
        data = [str dataUsingEncoding:NSUTF8StringEncoding];
        [fileHandler writeData:data];
        [fileHandler closeFile];
    } else {
        // Create the file and write text to it.
        outputStr = [NSString stringWithFormat:@"%@%@", @"0\n", str];
        data = [outputStr dataUsingEncoding:NSUTF8StringEncoding];
        [data writeToFile:statsFile atomically:YES];
    }
    
    bool successful = false;
    if ([fileManager fileExistsAtPath:jsFile]) {
        // Add the text at the end of the file.
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:jsFile];
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:jsFile error:nil] fileSize];
        
        if (fileSize > 2) {
            successful = true;
            [fileHandler seekToFileOffset:(fileSize-3)];
            if (str.length > 1) {
                if ([[str substringFromIndex:(str.length-1)] isEqualToString:@"\n"]) {
                    outputStr = [str substringToIndex:(str.length-1)];
                    str = [outputStr stringByAppendingString:@"\\n"];
                }
            }
            data = [str dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandler writeData:data];
            NSData *data2 = [@"\";\n" dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandler writeData:data2];
            [fileHandler closeFile];
        }
    }
    if (!successful) {
        // Create the file and write text to it.
        if (str.length > 1) {
            if ([[str substringFromIndex:(str.length-1)] isEqualToString:@"\n"]) {
                outputStr = [str substringToIndex:(str.length-1)];
                str = [outputStr stringByAppendingString:@"\\n"];
            }
        }
        outputStr = [NSString stringWithFormat:@"%@%@", @"\\n", str];
        outputStr = [@"var stats=\"" stringByAppendingString:outputStr];
        outputStr = [outputStr stringByAppendingString:@"\";\n"];
        data = [outputStr dataUsingEncoding:NSUTF8StringEncoding];
        [data writeToFile:jsFile atomically:YES];
    }
}

+ (void)genRedirFile {
    NSString *htmlstr = @"<html><head><meta http-equiv=\"refresh\" content=\"0; "
                          "url=http://localhost:8008/Stats.html\" /></head></html>";
    NSData *data = [htmlstr dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:redirFile atomically:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_startMenuItem setEnabled:NO];
    [_changeMenuItem setEnabled:NO];
    [_slackMenuItem setEnabled:NO];
    [_breakMenuItem setEnabled:NO];
    [_startButton setEnabled:NO];
    [_slackButton setEnabled:NO];
    [_breakButton setEnabled:NO];
    [_changeButton setEnabled:NO];
    [_timeText setAlignment:NSCenterTextAlignment];
    [_timeText setPreferredMaxLayoutWidth:0];
    [_overallText setAlignment:NSCenterTextAlignment];
    [_overallText setPreferredMaxLayoutWidth:0];
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0]; // thanks to https://stackoverflow.com/questions/7620251/how-to-get-main-window-app-delegate-from-other-class-subclass-of-nsviewcontro
    [mainWindow setLevel:NSFloatingWindowLevel];
    [[mainWindow standardWindowButton:NSWindowCloseButton] setEnabled:NO];
    NSBundle *bundle = [NSBundle mainBundle];
    setupScriptPath = [bundle pathForResource:@"runner" ofType:@"sh"];
    killServerPath = [bundle pathForResource:@"kill_server" ofType:@"sh"];
    portString = [NSString stringWithFormat:@"%u", PORT];
    [AppDelegate initializeDirectories];
    [AppDelegate setupServer];
    if ([fileManager fileExistsAtPath:statsFile]) {
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:statsFile];
        NSData *data = [fileHandler readDataOfLength:10];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([str length] == 0) {
            [AppDelegate writeString:@"0\n"];
        }
        else {
            NSArray *arr = [str componentsSeparatedByString:@"\n"];
            initialNumDays = [arr[0] intValue];
            numDays = initialNumDays;
            prevNumDays = initialNumDays;
        }
    }
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"MM/DD/YY HH:mm:ss"];
    timerFormatter = [[NSDateFormatter alloc] init];
    [timerFormatter setDateFormat:@"HH:mm:ss"];
    [timerFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    [_startButton setEnabled:YES];
    [_startMenuItem setEnabled:YES];
    [AppDelegate genRedirFile];
    NSString *visualizationPath = [bundle pathForResource:@"Stats" ofType:@"html"];
    NSLog(@"Copying %@ to %@", visualizationPath, visualizationFile);
    [fileManager removeItemAtPath:visualizationFile error:nil]; // Remove the old file (once the UI is stable, this can be omitted)
    [fileManager copyItemAtPath:visualizationPath toPath:visualizationFile error:nil];
    NSString *d3Path = [bundle pathForResource:@"d3.v4.min" ofType:@"js"];
    NSLog(@"Copying %@ to %@", d3Path, d3File);
    [fileManager copyItemAtPath:d3Path toPath:d3File error:nil];
    NSString *mainJSPath = [bundle pathForResource:@"main" ofType:@"js"];
    NSLog(@"Copying %@ to %@", mainJSPath, mainJSFile);
    [fileManager removeItemAtPath:mainJSFile error:nil]; // Remove the old file (once the UI is stable, this can be omitted)
    [fileManager copyItemAtPath:mainJSPath toPath:mainJSFile error:nil];
    NSString *trophyImagePath = [bundle pathForResource:@"trophy16" ofType:@"png"];
    NSLog(@"Copying %@ to %@", trophyImagePath, iconFile);
    [fileManager copyItemAtPath:trophyImagePath toPath:iconFile error:nil];
}

// see https://github.com/electron/electron/issues/3038
- (void)applicationWillFinishLaunching:(nonnull NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSFullScreenMenuItemEverywhere"];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (![self stopWorking])
        return NSTerminateCancel; // abort termination if canceled
    //[AppDelegate stopServer]; // May as well leave server up so user can still see stats!
    NSLog(@"Application exited");
    return NSTerminateNow;
}

+ (void)setupServer {
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:[NSArray arrayWithObjects:setupScriptPath, portString, nil]];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
    NSLog (@"Server running on port %@", portString);
}

+ (void)stopServer {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:[NSArray arrayWithObjects:killServerPath, portString, nil]];
    [task setStandardOutput:[NSPipe pipe]];
    [task launch];
    NSLog (@"Server on port %@ killed", portString);
}

+ (NSString *)getTimeString {
    NSDate * now = [NSDate date];
    NSString *start = [outputFormatter stringFromDate:now];
    return start;
}

- (void)stopSlacking {
    if (!slacking) return;
    slacking = false;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
    [AppDelegate startTask];
    [_slackButton setTitle:@"Slack Off"];
    [AppDelegate resetButtonStyle:_slackButton];
}

- (void)stopBreaking {
    if (!breaking) return;
    breaking = false;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
    [AppDelegate startTask];
    [_breakButton setTitle:@"Go On Break"];
    [AppDelegate resetButtonStyle:_breakButton];
}

+ (void)stopTask {
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

+ (void)stopSlacking:(NSString *)start {
    if (!slacking) return;
    slacking = false;
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

+ (void)stopBreaking:(NSString *)start {
    if (!breaking) return;
    breaking = false;
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

- (bool)stopWorking {
    if (!working) return true;
    if ([prefController doConfirm]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Are you sure you want to stop this session?"];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Cancel"];
        NSInteger selection = [alert runModal];
        if (selection != NSAlertFirstButtonReturn) {
            return false;
        }
    }
    NSLog(@"Ending session\n");
    working = false;
    NSString *start = [AppDelegate getTimeString];
    if (!breaking && !slacking)
        [AppDelegate stopTask];
    [AppDelegate stopSlacking:start];
    [AppDelegate stopBreaking:start];
    NSString *stop = [NSString stringWithFormat:@"Stopped Work %@\n",start];
    [AppDelegate writeString:stop];
    [AppDelegate updateNumDays];
    currentTask = nil;
    return true;
}

NSString *prefix = @"";

- (IBAction)startSession:(id)sender {
    if (working) {
        if (![self stopWorking])
            return;
        [_slackMenuItem setEnabled:NO];
        [_breakMenuItem setEnabled:NO];
        [_changeMenuItem setEnabled:NO];
        [AppDelegate resetButtonStyle:_slackButton];
        [AppDelegate resetButtonStyle:_breakButton];
        [_breakButton setTitle:@"Go On Break"];
        [_slackButton setTitle:@"Slack Off"];
        [_startButton setTitle:@"Start Work Session"];
        [_slackButton setEnabled:NO];
        [_breakButton setEnabled:NO];
        [_changeButton setEnabled:NO];
        [_overallText setStringValue:@""];
        [_timeText setStringValue:@"Idle"];
        [timer invalidate];
        timer = nil;
    }
    else {
        if (![self changeActivityHelper])
            return;
        NSLog(@"Starting session\n");
        prevNumDays = numDays;
        numDays++;
        working = true;
        [_slackButton setEnabled:YES];
        [_breakButton setEnabled:YES];
        [_changeButton setEnabled:YES];
        [_slackMenuItem setEnabled:YES];
        [_breakMenuItem setEnabled:YES];
        [_changeMenuItem setEnabled:YES];
        [_startButton setTitle:@"Stop Work Session"];
        NSDate *date = [NSDate date];
        NSString *str = [NSString stringWithFormat:@"Session %d, %@\n", numDays, [dateFormatter stringFromDate:date]];
        [AppDelegate writeString:str];
        NSString *start = [AppDelegate getTimeString];
        NSString *str2 = [NSString stringWithFormat:@"Started Work %@\n",start];
        [AppDelegate writeString:str2];
        prefix = [currentTask stringByAppendingString:@": "];
        sessionStart = [NSDate date];
        [self resetTimer];
        [AppDelegate startTask];
    }
}

+ (void)startTask {
    if (breaking || slacking) return;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@"Task: %@, %@", [currentTask stringByReplacingOccurrencesOfString:@"," withString:@"\\,"], start];
    [AppDelegate writeString:str];
}

+ (void)colorizeButton:(NSButton *)button withColor:(NSColor *)color {
    // thanks to https://stackoverflow.com/questions/29387102/how-to-set-background-color-of-nsbutton-osx
    // and https://stackoverflow.com/questions/1017468/change-background-color-of-nsbutton
    [button setBezelStyle:NSTexturedSquareBezelStyle];
    [button setBordered:false];
    [button setWantsLayer:true];
    button.layer.backgroundColor = color.CGColor;
}

+ (void)resetButtonStyle:(NSButton *)button {
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setBordered:true];
    [button setWantsLayer:false];
}

- (IBAction)startSlack:(id)sender {
    if (slacking) {
        [self stopSlacking];
        [_slackButton setTitle:@"Slack Off"];
        prefix = [currentTask stringByAppendingString:@": "];
    }
    else {
        slacking = true;
        if (breaking) {
            [self stopBreaking];
        }
        else {
            [AppDelegate stopTask];
        }
        [_slackButton setTitle:@"Get Back To Work!"];
        if ([prefController doHighlight]) {
            [AppDelegate colorizeButton:_slackButton withColor:[NSColor redColor]];
        }
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Wasted, %@", start];
        [AppDelegate writeString:str];
        prefix = @"Time Wasted: ";
    }
    [self resetTimer];
}

- (IBAction)startBreak:(id)sender {
    if (breaking) {
        [self stopBreaking];
        prefix = [currentTask stringByAppendingString:@": "];
    }
    else {
        breaking = true;
        if (slacking) {
            [self stopSlacking];
        }
        else {
            [AppDelegate stopTask];
        }
        [_breakButton setTitle:@"End Break"];
        if ([prefController doHighlight]) {
            [AppDelegate colorizeButton:_breakButton withColor:[NSColor yellowColor]];
        }
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Break, %@", start];
        [AppDelegate writeString:str];
        prefix = @"Break Time: ";
    }
    [self resetTimer];
}

- (IBAction)openPreferences:(id)sender {
    if (!prefController) {
        prefController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
    }
    [prefController showWindow:self];
}

// Adapted from https://stackoverflow.com/questions/20392802/how-to-display-an-input-box-in-mac-osx-using-c
- (NSString *)inputBox:(NSString *)prompt {
    NSString *result;
    unsigned int loopCount = 0;
    do {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:prompt];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];

        if (loopCount++ > 0)
            [alert setInformativeText:@"Please enter the name of the activity"];

        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 250, 24)];
        [alert setAccessoryView:input];
        NSInteger selection = [alert runModal];
        if (selection == NSAlertFirstButtonReturn) {
            [input validateEditing];
            result = [input stringValue];
            result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        else {
            return nil;
        }
    } while ([result isEqual:@""]);
    return result;
}

- (IBAction)changeActivity:(id)sender {
    [self changeActivityHelper];
}

- (bool)changeActivityHelper {
    bool firstActivity = (currentTask == nil);
    NSString *mss = [self inputBox:@"What are you working on?"];
    if (mss) {
        NSLog(@"New Activity: %@\n", mss);
        currentTask = mss;
        [_changeButton setTitle:[NSString stringWithFormat:@"Change Activity (%@)", currentTask]];
        if (!breaking && !slacking) {
            prefix = [currentTask stringByAppendingString:@": "];
            [self resetTimer];
            if (!firstActivity) {
                [AppDelegate stopTask];
                [AppDelegate startTask];
            }
        }
        return true;
    }
    else
        return false;
}

- (void)updateTimer {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:timerStart];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    bool showSecondsCur = [prefController showSeconds];

    if ([prefController init] && showSecondsCur != showSecondsLast) { // only change format if needed
        if (showSecondsCur)
            [timerFormatter setDateFormat:@"HH:mm:ss"];
        else
            [timerFormatter setDateFormat:@"HH:mm"];
        showSecondsLast = showSecondsCur;
    }
    NSString *timeString = [timerFormatter stringFromDate:timerDate];
    NSTimeInterval totalTimeInterval = [currentDate timeIntervalSinceDate:sessionStart];
    NSDate *totalTimerDate = [NSDate dateWithTimeIntervalSince1970:totalTimeInterval];
    NSString *totalTimeString = [timerFormatter stringFromDate:totalTimerDate];
    [self.timeText setStringValue:[NSString stringWithFormat:@"%@%@", prefix, timeString]];
    [self.overallText setStringValue:[NSString stringWithFormat:@"Overall Time: %@", totalTimeString]];
}

- (void)resetTimer {
    timerStart = [NSDate date];
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
             target:self selector:@selector(updateTimer)
             userInfo:nil repeats:YES];
}

- (IBAction)showStatistics:(id)sender {
    // Does not use openURL to force opening with Chrome, because UI is untested on other browsers (TODO: Change this)
    [[NSWorkspace sharedWorkspace] openFile:redirFile withApplication:@"Google Chrome.app"];
}
@end
