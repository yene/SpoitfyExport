//
//  XXXAppDelegate.h
//  SpotifyExport
//
//  Created by Yannick Weiss on 16/03/14.
//  Copyright (c) 2014 Yannick Weiss. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XXXAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *username;
@property (weak) IBOutlet NSTextField *password;
@property (weak) IBOutlet NSTextField *spotifyLinks;
@property (weak) IBOutlet NSPathControl *destinationPath;
@property (weak) IBOutlet NSTextField *format;
@property (unsafe_unretained) IBOutlet NSTextView *textView;



- (IBAction)changePath:(id)sender;
- (IBAction)download:(id)sender;


@end
