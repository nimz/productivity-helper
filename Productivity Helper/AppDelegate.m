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

bool slacking = false;
bool breaking = false;
bool working = false;
bool showSecondsLast = true;
NSString *fileName = @"Productivity Helper/Statistics.txt";
NSString *jsFileName = @"Productivity Helper/Statistics.js";
NSString *redirName = @"Productivity Helper/Stats_redir.html";
NSString *visualizationName = @"Productivity Helper/Stats.html";
NSString *portString;

NSString *filePath;
NSString *jsFilePath;
NSString *redirFile;
NSString *visualizationFile;
NSString *d3File;
NSString *currentTask;
NSString *setupScriptPath;
NSString *killServerPath;
NSFileManager *fileManager;
NSDateFormatter *dateFormatter;
NSDateFormatter *outputFormatter;
NSDateFormatter *timerFormatter;

NSDate *timerStart, *sessionStart;
NSTimer *timer;

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
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
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
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
        NSData *data = [numstr dataUsingEncoding:NSUTF8StringEncoding];
        [fileHandler writeData:data];
        [fileHandler closeFile];
    }
}

+ (void)initializeFiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        NSString *documentsDirPath = [paths objectAtIndex:0];
        filePath = [documentsDirPath stringByAppendingPathComponent:fileName];
        redirFile = [documentsDirPath stringByAppendingPathComponent:redirName];
        visualizationFile = [documentsDirPath stringByAppendingPathComponent:visualizationName];
        d3File = [documentsDirPath stringByAppendingPathComponent:@"Productivity Helper/scripts/d3.v4.min.js"];
        fileManager = [NSFileManager defaultManager];
    }
}

/** Appends text to statistics file located in the /Documents directory.
 * If file does not exist it will be created from scratch.
 * @param str String to write.
 * From http://objective-c-functions.blogspot.com/2013/09/write-and-append-text-to-file.html
 */
+ (void)writeString:(NSString *)str {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        NSString *documentsDirPath = [paths objectAtIndex:0];
        filePath = [documentsDirPath stringByAppendingPathComponent:fileName];
        jsFilePath = [documentsDirPath stringByAppendingPathComponent:jsFileName];
        NSString *str2;
        NSData *data;
        
        fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Add the text at the end of the file.
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
            [fileHandler seekToEndOfFile];
            data = [str dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandler writeData:data];
            [fileHandler closeFile];
        } else {
            // Create the file and write text to it.
            str2 = [NSString stringWithFormat:@"%@%@", @"0\n", str];
            data = [str2 dataUsingEncoding:NSUTF8StringEncoding];
            [data writeToFile:filePath atomically:YES];
        }
        
        bool successful = false;
        if ([fileManager fileExistsAtPath:jsFilePath]) {
            // Add the text at the end of the file.
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:jsFilePath];
            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:jsFilePath error:nil] fileSize];
            
            if (fileSize > 2) {
                successful = true;
                [fileHandler seekToFileOffset:(fileSize-3)];
                if (str.length > 1) {
                    if ([[str substringFromIndex:(str.length-1)] isEqualToString:@"\n"]) {
                        str2 = [str substringToIndex:(str.length-1)];
                        str = [str2 stringByAppendingString:@"\\n"];
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
                    str2 = [str substringToIndex:(str.length-1)];
                    str = [str2 stringByAppendingString:@"\\n"];
                }
            }
            str2 = [NSString stringWithFormat:@"%@%@", @"\\n", str];
            str2 = [@"var stats=\"" stringByAppendingString:str2];
            str2 = [str2 stringByAppendingString:@"\";\n"];
            data = [str2 dataUsingEncoding:NSUTF8StringEncoding];
            [data writeToFile:jsFilePath atomically:YES];
        }
    }
}

+ (void)genRedirFile {
    NSString *htmlstr = @"<html><head><meta http-equiv=\"refresh\" content=\"0; "
                          "url=http://localhost:8008/Stats.html\" /></head></html>";
    NSData *data = [htmlstr dataUsingEncoding:NSUTF8StringEncoding];
    [data writeToFile:redirFile atomically:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_slackButton setEnabled:NO];
    [_breakButton setEnabled:NO];
    [_changeButton setEnabled:NO];
    [_startButton setEnabled:NO];
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
    [AppDelegate setupServer];
    [AppDelegate initializeFiles];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
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
    [AppDelegate genRedirFile];
    NSString *visualizationPath = [bundle pathForResource:@"Stats" ofType:@"html"];
    NSLog(@"Path to canonical visualization file: %@", visualizationPath);
    NSLog(@"Destination to copy visualization file: %@", visualizationFile);
    [fileManager removeItemAtPath:visualizationFile error:nil]; //  Remove the old file (once the UI is stable, this can be omitted)
    [fileManager copyItemAtPath:visualizationPath toPath:visualizationFile error:nil];
    NSString *d3Path = [bundle pathForResource:@"d3.v4.min" ofType:@"js"];
    NSLog(@"Path to d3 file: %@", d3Path);
    [fileManager copyItemAtPath:d3Path toPath:d3File error:nil];
}

// see https://github.com/electron/electron/issues/3038
- (void)applicationWillFinishLaunching:(nonnull NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSFullScreenMenuItemEverywhere"];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [AppDelegate stopWorking];
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

+ (void)stopSlacking {
    if (!slacking) return;
    slacking = false;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
    [AppDelegate startTask];
}

+ (void)stopBreaking {
    if (!breaking) return;
    breaking = false;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
    [AppDelegate startTask];
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

+ (void)stopWorking {
    if (!working) return;
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
}

NSString *prefix = @"";

- (IBAction)startSession:(id)sender {
    if (working) {
        [AppDelegate stopWorking];
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
        NSLog(@"Starting session\n");
        prevNumDays = numDays;
        numDays++;
        working = true;
        [_slackButton setEnabled:YES];
        [_breakButton setEnabled:YES];
        [_changeButton setEnabled:YES];
        [_startButton setTitle:@"Stop Work Session"];
        [self changeActivity:sender];
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

- (IBAction)startBreak:(id)sender {
    if (breaking) {
        [AppDelegate stopBreaking];
        [_breakButton setTitle:@"Go On Break"];
        prefix = [currentTask stringByAppendingString:@": "];
    }
    else {
        breaking = true;
        if (slacking) {
            [AppDelegate stopSlacking];
            [_slackButton setTitle:@"Slack Off"];
        }
        else {
            [AppDelegate stopTask];
        }
        [_breakButton setTitle:@"End Break"];
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Break, %@", start];
        [AppDelegate writeString:str];
        prefix = @"Break Time: ";
    }
    [self resetTimer];
}

- (IBAction)startSlack:(id)sender {
    if (slacking) {
        [AppDelegate stopSlacking];
        [_slackButton setTitle:@"Slack Off"];
        prefix = [currentTask stringByAppendingString:@": "];
    }
    else {
        slacking = true;
        if (breaking) {
            [AppDelegate stopBreaking];
            [_breakButton setTitle:@"Go On Break"];
        }
        else {
            [AppDelegate stopTask];
        }
        [_slackButton setTitle:@"Get Back To Work!"];
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Wasted, %@", start];
        [AppDelegate writeString:str];
        prefix = @"Time Wasted: ";
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
- (NSString *)inputBox:(NSString *)prompt allowCancel:(bool)cancellable {
    NSString *result;
    unsigned int loopCount = 0;
    do {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:prompt];
        [alert addButtonWithTitle:@"OK"];
        if (cancellable)
            [alert addButtonWithTitle:@"Cancel"];

        if (loopCount++ > 0)
            [alert setInformativeText:@"Please enter the name of the activity"];

        NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 250, 24)];
        [alert setAccessoryView:input];
        NSInteger button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
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
    bool firstActivity = (currentTask == nil);
    NSString *mss = [self inputBox:@"What are you working on?" allowCancel:(!firstActivity)];
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
    }
}

- (void)updateTimer {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:timerStart];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    bool showSecondsCur = [prefController showSeconds];

    if ([prefController init] && showSecondsCur != showSecondsLast) {
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
