//
//  XXXAppDelegate.m
//  SpotifyExport
//
//  Created by Yannick Weiss on 16/03/14.
//  Copyright (c) 2014 Yannick Weiss. All rights reserved.
//

#import "XXXAppDelegate.h"

@implementation XXXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // Insert code here to initialize your application
  self.destinationPath.URL = [NSURL fileURLWithPath:[@"~/Music" stringByExpandingTildeInPath]];
  
}

- (IBAction)changePath:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setCanChooseDirectories:YES];
  if ([openPanel runModal] == NSOKButton) {
    self.destinationPath.URL = [[openPanel URLs] lastObject];
  }
}

- (IBAction)download:(id)sender {
  
  [[[self.textView superview] superview] setHidden:NO];
  
  NSArray *spotifyLinks = [self.spotifyLinks.stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
  NSString *path = [environmentDict objectForKey:@"PATH"];
  NSDictionary *dictionary = @{ @"PATH" : [path stringByAppendingString:@":/usr/local/bin:/usr/local/share/npm/bin/"] };
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
  dispatch_async(queue, ^{
    for (NSString *spotifyURL in spotifyLinks) {
      NSTask *task = [[NSTask alloc] init];
      [task setEnvironment:dictionary];
      [task setLaunchPath: @"/usr/local/share/npm/bin/spotify-to-mp3"];
      
      [task setArguments: @[spotifyURL, @"-u", self.username.stringValue, @"-p", self.password.stringValue, @"-f", self.format.stringValue, @"-d", [self.destinationPath.URL path]]];
      
      NSPipe *pipe = [NSPipe pipe];
      [task setStandardOutput:pipe];
      
      NSFileHandle *file = [pipe fileHandleForReading];
      [file waitForDataInBackgroundAndNotify];
      

      
      //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readCompleted:) name:NSFileHandleReadToEndOfFileCompletionNotification object:file];
      [task launch];
      //[task waitUntilExit];
      
      NSData *data = [file readDataToEndOfFile];
      NSString *string;
      string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      dispatch_sync(dispatch_get_main_queue(), ^{
        [self.textView insertText:string];
      });
    }
  });
  
}

- (void)receivedData:(NSNotification *)notif {
  NSFileHandle *fh = [notif object];
  NSData *data = [fh availableData];
  NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]; //NSUTF8StringEncoding or NSASCIIStringEncoding ?
  [self.textView insertText:str];
  [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
}

- (void)readCompleted:(NSNotification *)notification {
  [[[self.textView superview] superview] setHidden:YES];
  [self.textView setString:@""];
}

@end
