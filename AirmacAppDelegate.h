//
//  AirmacAppDelegate.h
//  Airmac
//
//  Created by Arend Jan Kramer on 08-05-11.
//  Copyright 2011 Sizzit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HTTPServer.h"
#import <QTKit/QTKit.h>

@interface AirmacAppDelegate : NSObject <NSApplicationDelegate,AirplayDelegate,NSWindowDelegate> {
    NSPanel *aboutWindow;
	
	// Image slideshow
	NSPanel *imageWindow;
	NSImageView *fullScreenbg;
	NSImageView *imageView1;
	NSImageView *imageView2;
	int CurrentImageView;
	NSTrackingArea *imageHoverTracker;
	NSView *hoverControls;
	NSButton *fullScreenBtn;
	CGPoint windowedModeLocation;
	BOOL imageFullscreen;
	BOOL videoFullscreen;
	int hideCounter;
	
	// Voorkeuren paneel
	NSWindow *prefWindow;
	NSButton *_startVideoFullScreenCheckBox;
	NSButton *_startImageSlideshowFullScreenCheckBox;
	
	// Error paneel
	NSPanel *errorWindow;
	NSTextField *errorTextField;
	
	HTTPServer *server;
	BOOL _serverIsStarted;
	// Menu icoontje
	NSStatusItem *myStatusItem;
	IBOutlet NSMenu *myStatusMenu;
	IBOutlet NSMenuItem *serverStatus;
	IBOutlet NSMenuItem *toggleServer;
	
	
}
- (void) checkForUpdates;

- (void) startServer;
- (void) toggleServerStatusMenuItem:(BOOL)started;
- (void)setImageWindowHoverActions;
- (IBAction) toggleFullScreen:(id)sender;
- (IBAction) toggleServer:(id)sender;
- (IBAction) about:(id)sender;
- (IBAction) quit:(id)sender;
- (IBAction) errorOk:(id)sender;
- (IBAction) preferences:(id)sender;

@property (assign) IBOutlet NSPanel *aboutWindow;
@property (assign) IBOutlet NSPanel *imageWindow;
@property (assign) IBOutlet NSView *hoverControls;
@property (assign) IBOutlet NSButton *fullScreenBtn;
@property (assign) IBOutlet NSWindow *prefWindow;
@property (assign) IBOutlet NSPanel *errorWindow;
@property (assign) IBOutlet NSTextField *errorTextField;
@property (assign) IBOutlet NSImageView *imageView1;
@property (assign) IBOutlet NSImageView *imageView2;
@property (assign) IBOutlet NSImageView *fullScreenbg;
@property (assign) IBOutlet NSButton *_startVideoFullScreenCheckBox;
@property (assign) IBOutlet NSButton *_startImageSlideshowFullScreenCheckBox;

@end
