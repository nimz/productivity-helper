//
//  AppDelegate.m
//  Productivity Helper
//
//  Created by Nimit Sohoni on 6/19/15.
//  Copyright (c) 2015 Nimit Sohoni. All rights reserved.
//
// Note: daylight savings time is not handled correctly

#import "AppDelegate.h"
#import "PreferencesController.h"

@implementation AppDelegate

/** Append text to a file located in the /Documents directory.
 
 If file does not exist it will be created from scratch.
 
 @param str String to write.
 @param fileName Name of the file.
 
 From http://objective-c-functions.blogspot.com/2013/09/write-and-append-text-to-file.html
 
 */

bool slacking = false;
bool breaking = false;
bool working = false;
NSString *fileName = @"Productivity Helper/Statistics.txt";
NSString *jsFileName = @"Productivity Helper/Statistics.js";
NSString *visualizationName = @"Productivity Helper/Stats.html";

NSString *filePath;
NSString *jsFilePath;
NSString *visualizationFile;
NSString *currentTask;
NSFileManager *fileManager;
NSDateFormatter *dateFormatter;
NSDateFormatter *outputFormatter;
NSDateFormatter *timerFormatter;

NSDate *timerStart;
NSTimer *timer;

int initialNumDays = 0;
int prevNumDays = 0;
int numDays = 0;

+(int)numDigitsH:(int)n {
    if (n == 0) return 0;
    return 1 + [AppDelegate numDigitsH:(n / 10)];
}

+(int)numDigits:(int)n {
    if (n == 0) return 1;
    return [AppDelegate numDigitsH:n];
}

+(void)updateNumDays {
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

+(void)initializeFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        NSString *documentsDirPath = [paths objectAtIndex:0];
        filePath = [documentsDirPath stringByAppendingPathComponent:fileName];
        visualizationFile = [documentsDirPath stringByAppendingPathComponent:visualizationName];
        fileManager = [NSFileManager defaultManager];
    }
}

+ (void)writeString:(NSString *)str {
    //printf("Writing %s\n", [str UTF8String]);
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


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_timeText setAlignment:NSCenterTextAlignment];
    [_timeText setPreferredMaxLayoutWidth:0];
    [_slackButton setEnabled:NO];
    [_breakButton setEnabled:NO];
    [_workButton setEnabled:NO];
    [_changeButton setEnabled:NO];
    [AppDelegate initializeFile];
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
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:@"Statistics.html"];
    NSData *data = [fileHandler readDataOfLength:10];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    printf("%s\n", [str UTF8String]);
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"HH:mm:ss"];
    timerFormatter = [[NSDateFormatter alloc] init];
    [timerFormatter setDateFormat:@"HH:mm:ss"];
    [timerFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0]; // thanks to https://stackoverflow.com/questions/7620251/how-to-get-main-window-app-delegate-from-other-class-subclass-of-nsviewcontro
    [mainWindow setLevel:NSFloatingWindowLevel];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [AppDelegate stopWorking];
    NSLog(@"Application exited");
    return NSTerminateNow;
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
}

+ (void)stopBreaking {
    if (!breaking) return;
    breaking = false;
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
        [_workButton setEnabled:NO];
        [_changeButton setEnabled:NO];
        [_timeText setStringValue:@"Idle"];
        [timer invalidate];
        timer = nil;
    }
    else {
        prevNumDays = numDays;
        numDays++;
        working = true;
        [_slackButton setEnabled:YES];
        [_breakButton setEnabled:YES];
        [_workButton setEnabled:YES];
        [_changeButton setEnabled:YES];
        [_startButton setTitle:@"Stop Work Session"];
        [self changeActivity:sender];
        NSDate *date = [NSDate date];
        NSString *str = [NSString stringWithFormat:@"Session %d, %@\n", numDays, [dateFormatter stringFromDate:date]];
        [AppDelegate writeString:str];
        NSString *start = [AppDelegate getTimeString];
        NSString *str2 = [NSString stringWithFormat:@"Started Work %@\n",start];
        [AppDelegate writeString:str2];
        prefix = @"Working For: ";
        [self resetTimer];
    }
}

- (IBAction)startBreak:(id)sender {
    if (breaking) {
        [AppDelegate stopBreaking];
        [_workButton setEnabled:YES];
        [_changeButton setEnabled:YES];
        [_breakButton setTitle:@"Go On Break"];
        prefix = @"Working For: ";
    }
    else {
        breaking = true;
        if (slacking) {
            [AppDelegate stopSlacking];
            [_slackButton setTitle:@"Slack Off"];
        }
        [_breakButton setTitle:@"End Break"];
        [_workButton setEnabled:NO];
        [_changeButton setEnabled:NO];
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Break %@", start];
        [AppDelegate writeString:str];
        prefix = @"Break Time: ";
    }
    [self resetTimer];
}

- (IBAction)startSlack:(id)sender {
    if (slacking) {
        [AppDelegate stopSlacking];
        [_workButton setEnabled:YES];
        [_changeButton setEnabled:YES];
        [_slackButton setTitle:@"Slack Off"];
        prefix = @"Working For: ";
    }
    else {
        slacking = true;
        if (breaking) {
            [AppDelegate stopBreaking];
            [_breakButton setTitle:@"Go On Break"];
        }
        [_slackButton setTitle:@"Get Back To Work!"];
        [_workButton setEnabled:NO];
        [_changeButton setEnabled:NO];
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Wasted %@", start];
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
        }
        else {
            return nil;
        }
    } while ([result isEqual:@""]);
    return result;
}

- (IBAction)changeActivity:(id)sender {
    NSString* mss = [self inputBox:@"What are you working on?" allowCancel:(currentTask != nil)];
    if (mss) {
        NSLog(@"New Activity: %@\n", mss);
        currentTask = mss;
    }
}

- (void)updateTimer {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:timerStart];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSString *timeString = [timerFormatter stringFromDate:timerDate];
    [self.timeText setStringValue:[NSString stringWithFormat:@"%@%@", prefix, timeString]];
}

- (void)resetTimer {
    timerStart = [NSDate date];
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
             target:self selector:@selector(updateTimer)
             userInfo:nil repeats:YES];
}

- (IBAction)showStatistics:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:visualizationFile withApplication:@"Google Chrome.app"];
}
@end
