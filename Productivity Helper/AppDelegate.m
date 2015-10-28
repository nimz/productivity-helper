//
//  AppDelegate.m
//  Productivity Helper
//
//  Created by Nimit Sohoni on 6/19/15.
//  Copyright (c) 2015 Nimit Sohoni. All rights reserved.
//

#import "AppDelegate.h"

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
NSString *visualizationName = @"Productivity Helper/Stats.html";

NSString *filePath;
NSString *visualizationFile;
NSFileManager *fileManager;
NSDateFormatter *dateFormatter;
NSDateFormatter *outputFormatter;
NSDateFormatter *timerFormatter;

int initialNumDays = 0;
int prevNumDays = 0;
int numDays = 0;

+(int) numDigitsH:(int)n {
    if (n == 0) return 0;
    return 1 + [AppDelegate numDigitsH:(n / 10)];
}

+(int) numDigits:(int)n {
    if (n == 0) return 1;
    return [AppDelegate numDigitsH:n];
}

+(void) updateNumDays {
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

+(void) initializeFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        NSString *documentsDirPath = [paths objectAtIndex:0];
        filePath = [documentsDirPath stringByAppendingPathComponent:fileName];
        visualizationFile = [documentsDirPath stringByAppendingPathComponent:visualizationName];
        fileManager = [NSFileManager defaultManager];
    }
}

+ (void)writeString:(NSString *)str {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (0 < [paths count]) {
        NSString *documentsDirPath = [paths objectAtIndex:0];
        filePath = [documentsDirPath stringByAppendingPathComponent:fileName];
        
        fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:filePath]) {
            // Add the text at the end of the file.
            NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
            [fileHandler seekToEndOfFile];
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandler writeData:data];
            [fileHandler closeFile];
        } else {
            // Create the file and write text to it.
            str = [NSString stringWithFormat:@"%@/%@", @"0\n", str];
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            [data writeToFile:filePath atomically:YES];
        }
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_timeText setAlignment:NSCenterTextAlignment];
    [_slackButton setEnabled:NO];
    [_breakButton setEnabled:NO];
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
    //bool w = [ [ NSWorkspace sharedWorkspace ] launchApplication: @"Google Chrome.app" ];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [AppDelegate stopWorking];
    NSLog(@"Application exited");
    return NSTerminateNow;
}

+ (NSString *) getTimeString {
    NSDate * now = [NSDate date];
    NSString *start = [outputFormatter stringFromDate:now];
    return start;
}

+ (void) stopSlacking {
    if (!slacking) return;
    slacking = false;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

+ (void) stopBreaking {
    if (!breaking) return;
    breaking = false;
    NSString *start = [AppDelegate getTimeString];
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

+ (void) stopSlacking:(NSString *)start {
    if (!slacking) return;
    slacking = false;
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

+ (void) stopBreaking:(NSString *)start {
    if (!breaking) return;
    breaking = false;
    NSString *str = [NSString stringWithFormat:@", %@\n",start];
    [AppDelegate writeString:str];
}

+ (void) stopWorking {
    if (!working) return;
    working = false;
    NSString *start = [AppDelegate getTimeString];
    [AppDelegate stopSlacking:start];
    [AppDelegate stopBreaking:start];
    NSString *stop = [NSString stringWithFormat:@"stopped work %@\n",start];
    [AppDelegate writeString:stop];
    [AppDelegate updateNumDays];
}

NSString *prefix = @"";

- (IBAction)startWork:(id)sender {
    if (working) {
        [AppDelegate stopWorking];
        [_breakButton setTitle:@"Go On Break"];
        [_slackButton setTitle:@"Slack Off"];
        [_workButton setTitle:@"Start Work Session"];
        [_slackButton setEnabled:NO];
        [_breakButton setEnabled:NO];
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
        [_workButton setTitle:@"Stop Work Session"];
        //        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        //        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        NSDate *date = [NSDate date];
        //        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        //        [dateFormatter setLocale:usLocale];
        NSString *str = [NSString stringWithFormat:@"Session %d, %@\n", numDays, [dateFormatter stringFromDate:date]];
        [AppDelegate writeString:str];
        NSString *start = [AppDelegate getTimeString];
        NSString *str2 = [NSString stringWithFormat:@"started work %@\n",start];
        [AppDelegate writeString:str2];
        prefix = @"Working For: ";
        //counter = 0;
        timerStart = [NSDate date];
        [timer invalidate];
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                         target:self selector:@selector(updateTimer)
                         userInfo:nil repeats:YES];
    }
}

- (IBAction)startBreak:(id)sender {
    if (breaking) {
        [AppDelegate stopBreaking];
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
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Break %@", start];
        [AppDelegate writeString:str];
        prefix = @"Break Time: ";
    }
    timerStart = [NSDate date];
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                     target:self selector:@selector(updateTimer)
                     userInfo:nil repeats:YES];
}

- (IBAction)startSlack:(id)sender {
    if (slacking) {
        [AppDelegate stopSlacking];
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
        NSString *start = [AppDelegate getTimeString];
        NSString *str = [NSString stringWithFormat:@"Wasted %@", start];
        [AppDelegate writeString:str];
        prefix = @"Time Wasted: ";
    }
    timerStart = [NSDate date];
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                     target:self selector:@selector(updateTimer)
                     userInfo:nil repeats:YES];
}

NSDate *timerStart;
- (void)updateTimer {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:timerStart];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSString *timeString = [timerFormatter stringFromDate:timerDate];
    [self.timeText setStringValue:[NSString stringWithFormat:@"%@%@", prefix, timeString]];
}

NSTimer *timer;
- (void) resetTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                     target:self selector:@selector(updateTimer)
                     userInfo:nil repeats:YES];
}

- (IBAction)showStatistics:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:visualizationFile withApplication:@"Google Chrome.app"];
}
@end
