//
//  AirmacAppDelegate.m
//  Airmac
//
//  Created by Arend Jan Kramer on 08-05-11.
//  Copyright 2011 Sizzit. All rights reserved.
//

#import "AirmacAppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <AppKit/AppKit.h>

@implementation AirmacAppDelegate

@synthesize aboutWindow, imageWindow, imageView1, imageView2, errorWindow, errorTextField, fullScreenbg, hoverControls, fullScreenBtn, prefWindow;
@synthesize _startImageSlideshowFullScreenCheckBox, _startVideoFullScreenCheckBox;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	

	[self checkForUpdates];
	
	[NSTimer scheduledTimerWithTimeInterval:1.0
									 target:self
								   selector:@selector(autohideFullScreenBtn)
								   userInfo:nil
									repeats:YES];
	
	myStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	NSImage *statusImage = [NSImage imageNamed:@"icon.png"];
	[myStatusItem setImage:statusImage];
	[myStatusItem setHighlightMode:YES];
	[myStatusItem setMenu:myStatusMenu];

	// We switchen steeds van view zodat we animaties kunnen doen
	CurrentImageView = 1;

	CAAnimation *anim = [CABasicAnimation animation];
    [anim setDelegate:self];
    [imageView1 setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
    [imageView2 setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
	[hoverControls setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
	
	[self setImageWindowHoverActions];
	
	// Server starten
	server = [[HTTPServer alloc] init];
    [server setType:@"_airplay._tcp."]; // Registreren van airplay service
	[server setPort:7000]; // Maakt geen reet uit
	
	NSString *name = NSMakeCollectable(SCDynamicStoreCopyComputerName(NULL, NULL));
	
    [server setName:[NSString stringWithFormat:@"%@ - Airmac",name]]; // Naam
	[server setAirplayDelegate:self];
	[server setDelegate:self];
	
	[self startServer];
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs synchronize];
	
	imageFullscreen = ([[NSUserDefaults standardUserDefaults] integerForKey:@"_startImageSlideshowFullScreenCheckBox"] == NSOnState);
	videoFullscreen = ([[NSUserDefaults standardUserDefaults] integerForKey:@"_startVideoFullScreenCheckBox"] == NSOnState);

	
}

- (void) checkForUpdates
{
	NSError *err = [[[NSError alloc] init] autorelease];
	NSString *url = [[NSString stringWithFormat:@"http://sizzit.nl/airmacversion.txt"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *myTxtFile = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&err];
	if(err.code != 0) {
		
	}
	else {
		
		int newVersion = [myTxtFile intValue];
		int currentVersion = [[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] intValue];
		
		NSLog(@"Version : %i",newVersion);
		NSLog(@"Curent version: %i",currentVersion);

		if (newVersion > currentVersion)
		{
			[errorWindow makeKeyAndOrderFront:self];
			
			
			[errorTextField setStringValue:[NSString stringWithFormat:@"New version available. The new version is V%i", newVersion]];
			
		}
		
		
	}

	
}

- (void) startServer
{

	NSError *startError = nil;
    if (![server start:&startError] ) {
		
		[self toggleServerStatusMenuItem:NO];
		_serverIsStarted = FALSE;
		[errorWindow makeKeyAndOrderFront:self];
		
		NSString *errorDescription = @"";
		if ([startError code] == kTCPServerCouldNotBindToIPv4Address)
		{
			errorDescription = @"Could not bind to IPv4 Address";
		}
		else if ([startError code] == kTCPServerCouldNotBindToIPv6Address)
		{
			errorDescription = @"Could not bind to IPv6 Address";
		}
		else if ([startError code] == kTCPServerNoSocketsAvailable)
		{
			errorDescription = @"There were no sockets available";
		}
		else {
			errorDescription = [startError description];
		}

		
		[errorTextField setStringValue:[NSString stringWithFormat:@"The server could not be started:\n%@\n\nMake sure the port is not in use by another application.", errorDescription]];
		
		
    } else {
		_serverIsStarted = TRUE;
		[self toggleServerStatusMenuItem:YES];
        NSLog(@"Server gestart op poort %d", [server port]);
    }
	
}

- (IBAction) errorOk:(id)sender
{
	[errorWindow close];
}
- (void) toggleServerStatusMenuItem:(BOOL)started
{

	if (started)
	{
		[serverStatus setTitle:@"Server successfully started"];
		[serverStatus setImage:[NSImage imageNamed:@"Started.png"]];
		[toggleServer setTitle:@"Stop server"]; 
	}
	else {
		[serverStatus setTitle:@"Server not started"];
		[serverStatus setImage:[NSImage imageNamed:@"Notstarted.PNG"]];
		[toggleServer setTitle:@"Start server"]; 
	}

	
}

- (IBAction) toggleServer:(id)sender
{
	if (_serverIsStarted)
	{
		[server stop];
		_serverIsStarted = FALSE;
		[self toggleServerStatusMenuItem:NO];
	}
	else {
		[self startServer];
	}

}

- (IBAction) about:(id)sender
{
	
		[aboutWindow makeKeyAndOrderFront:self];

	
}

-(void) windowWillClose:(NSNotification *)notification
{
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	[prefs setInteger:[_startImageSlideshowFullScreenCheckBox state] forKey:@"_startImageSlideshowFullScreenCheckBox"];
	[prefs setInteger:[_startVideoFullScreenCheckBox state] forKey:@"_startVideoFullScreenCheckBox"];

	imageFullscreen = ([_startImageSlideshowFullScreenCheckBox state] == NSOnState);
	videoFullscreen = ([_startVideoFullScreenCheckBox state] == NSOnState);

	[prefs synchronize];
	
}

- (IBAction) preferences:(id)sender
{
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs synchronize];

	[_startVideoFullScreenCheckBox setState:([[NSUserDefaults standardUserDefaults] integerForKey:@"_startVideoFullScreenCheckBox"] == NSOnState)];
	[_startImageSlideshowFullScreenCheckBox setState:([[NSUserDefaults standardUserDefaults] integerForKey:@"_startImageSlideshowFullScreenCheckBox"] == NSOnState)];

	
	[prefWindow makeKeyAndOrderFront:self];
	[prefWindow setDelegate:self];

}


- (IBAction) quit:(id)sender
{
	
	[server stop];
	[NSApp terminate: nil];
}


// Airplay interaction with Quicktime
- (void)videoSent:(NSString*)url startPosition:(float)start{
	
/*	[videoWindow makeKeyAndOrderFront:nil];
	[moviePlayer setMovie:[QTMovie movieWithURL:[NSURL URLWithString:url] error:nil]];
	[moviePlayer setDelegate:self]; */
	
	NSString *_fullscreenScript = @"";
	if (videoFullscreen)
	{
//			_fullscreenScript = @"tell application \"System Events\" to keystroke \"f\" using command down\n";
			_fullscreenScript = @"delay 0.5 \n \
									set presenting of document 1 to true \n";
	}
	
	NSString *script = [NSString stringWithFormat:@"tell application \"QuickTime Player\"\n\
						stop every document \n \
						close every window \n \
						open URL \"%@\"\n\
						activate \n \
						play document 1 \n \
						%@ \
						end tell",url, _fullscreenScript];
	NSAppleScript *openScript = [[NSAppleScript alloc] initWithSource:script];
	[openScript executeAndReturnError:NULL];
	[openScript release]; 
	
	
}

- (void)videoDidPauseOrPlay:(BOOL)pause
{
	
	NSString *playpause = @"play";
	if (pause)
	{
		playpause = @"pause";
	}
	
	NSString *script = [NSString stringWithFormat:@"tell application \"QuickTime Player\"\n\
						%@ document 1 \n \
						end tell",playpause];
	NSAppleScript *openScript = [[NSAppleScript alloc] initWithSource:script];
	[openScript executeAndReturnError:NULL];
	[openScript release]; 

}

- (void)videoDidScrubTo:(float)seconds
{
	
	NSString *script = [NSString stringWithFormat:@"tell application \"QuickTime Player\"\n\
						set current time of document 1 to %f \n \
						end tell",seconds/1000000];
		
	NSAppleScript *openScript = [[NSAppleScript alloc] initWithSource:script];
	[openScript executeAndReturnError:NULL];
	[openScript release];

	
}

- (float)airplayDidAskPosition
{
	
	
	NSString *appleScriptSource = [NSString stringWithFormat:@"tell application\"QuickTime Player\"\n \
								   set this_time to the current time of document 1 \n \
								   return this_time \n \
								   end tell"];
	NSDictionary *anError;
	NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource:appleScriptSource];
	NSAppleEventDescriptor *aDescriptor = [aScript executeAndReturnError:&anError];
	
	[aScript release];
	
	float finalPosition;
	if ([aDescriptor stringValue])
	{	
		finalPosition = (float)[aDescriptor int32Value]; // iPod trekt er altijd 1 seconde vanaf
	}
	else {
		finalPosition = 0;
	}

	
	return finalPosition;
	
}


- (float)airplayDidAskRate
{
	
	
	NSString *appleScriptSource = [NSString stringWithFormat:@"tell application\"QuickTime Player\"\n \
								   set this_rate to the rate of document 1 \n \
								   return this_rate \n \
								   end tell"];
	NSDictionary *anError;
	NSAppleScript *aScript = [[NSAppleScript alloc] initWithSource:appleScriptSource];
	NSAppleEventDescriptor *aDescriptor = [aScript executeAndReturnError:&anError];
	
	[aScript release];
	
	float finalRate;
	if ([aDescriptor stringValue])
	{	
		finalRate = (float)[aDescriptor int32Value]; 
	}
	else {
		finalRate = 0;
	}
	
	
	return finalRate;
	
}



- (void)videoClosed
{
	[imageWindow close];
	

	NSDictionary *fullScreenOptions = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																   forKey:NSFullScreenModeSetting] retain];

	[fullScreenbg setHidden:TRUE];
	[[imageWindow contentView] exitFullScreenModeWithOptions:fullScreenOptions];


	// Quicktime killen
	NSString *script = [NSString stringWithFormat:@"tell application \"QuickTime Player\"\n\
						close document 1\n \
						end tell"];
		
	NSAppleScript *openScript = [[NSAppleScript alloc] initWithSource:script];
	[openScript executeAndReturnError:NULL];
	[openScript release];
	
	imageFullscreen = ([[NSUserDefaults standardUserDefaults] integerForKey:@"_startImageSlideshowFullScreenCheckBox"] == NSOnState);
	videoFullscreen = ([[NSUserDefaults standardUserDefaults] integerForKey:@"_startVideoFullScreenCheckBox"] == NSOnState);

	
}
// Image gedeelte
-(void)enterimageSlideshowfullscreen
{
	
	NSScreen *mainScreen = [NSScreen mainScreen];
	
	NSDictionary *fullScreenOptions = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																   forKey:NSFullScreenModeSetting] retain];
	
	[fullScreenbg setHidden:FALSE];
	[[imageWindow contentView] enterFullScreenMode:mainScreen withOptions:fullScreenOptions];
	[NSCursor setHiddenUntilMouseMoves:YES];
	
	[fullScreenBtn setImage:[NSImage imageNamed:@"windowed.png"]];
	
}

-(void)exitimageSlideshowfullscreen
{
	NSDictionary *fullScreenOptions = [[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																   forKey:NSFullScreenModeSetting] retain];
	
	[fullScreenbg setHidden:TRUE];
	[[imageWindow contentView] exitFullScreenModeWithOptions:fullScreenOptions];
	
	[fullScreenBtn setImage:[NSImage imageNamed:@"fullscreen.png"]];
	
}

- (IBAction) toggleFullScreen:(id)sender
{
	
	NSLog(@"toggleFullScreen");
	
	if (!imageFullscreen)
	{
		
		[self enterimageSlideshowfullscreen];
		
	}
	else {

		[self exitimageSlideshowfullscreen];
		
//		windowedModeLocation = CGPointMake([imageWindow frame].origin.x, [imageWindow frame].origin.y);
	}
	imageFullscreen = !imageFullscreen;

	
}


// Image slideshow!
- (void)photoSent:(NSData*)photoData
{
	
	// We wisselen steeds van imageview, zodat we dat mooi kunnen animeren
	NSImage *img = [[NSImage alloc] initWithData:photoData];
	NSBitmapImageRep *rep = [[img representations] objectAtIndex: 0];
	
	if (CurrentImageView == 1)
	{
		[imageView2.animator setAlphaValue:1.0];
		[imageView1.animator setAlphaValue:0.0];
		CurrentImageView = 2;
		[imageView2 setImage:img];
	}
	else {
		[imageView2.animator setAlphaValue:0.0];
		[imageView1.animator setAlphaValue:1.0];
		CurrentImageView = 1;
		[imageView1 setImage:img];
	}

	
//	NSRect screenRect = [mainScreen visibleFrame];
//	CGFloat xPos = (screenRect.size.width/2) - ([rep pixelsWide]/2);
//	CGFloat yPos = (screenRect.size.height/2) + ([rep pixelsHigh]/2)+10+25; // Voor bovenbalk en menubalk
	
	CGFloat xPos = [imageWindow frame].origin.x;
	CGFloat yPos = [imageWindow frame].origin.y;
	
	

	
	if (imageFullscreen)
	{
		
		[self enterimageSlideshowfullscreen];

		
	}
	else {
		[imageWindow setFrame:NSMakeRect(xPos, yPos, [rep pixelsWide] , [rep pixelsHigh]) display:YES animate:YES];
	}

		
		
	[imageWindow makeKeyAndOrderFront:nil];

	[img release];
}

// Voor de mouseover van de imageslideshow, wat de controls laat zien
- (void)setImageWindowHoverActions
{
	[[imageWindow contentView] updateTrackingAreas];
	
	if (imageHoverTracker)
	{
		[[imageWindow contentView] removeTrackingArea:imageHoverTracker];
		[imageHoverTracker release];
	}
	
	NSTrackingAreaOptions options = NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways;
	imageHoverTracker = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:options owner:self userInfo:nil];
	[[imageWindow contentView] addTrackingArea:imageHoverTracker];
	[[imageWindow contentView] updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent *)event
{
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.2f];
	
	[[hoverControls animator] setAlphaValue:0.7];
	
	[NSAnimationContext endGrouping];
	
	hideCounter = 3;

}



-(void) autohideFullScreenBtn
{
	

	// Word iedere seconde uitgevoerd
	
	if (hideCounter > 0)
	{
		hideCounter--;
	}
	
	
	if (hideCounter  == 0)
	{	
		[[hoverControls animator] setAlphaValue:0.0];
	}
	
}


-(void) hideFullScreenBtn
{
	[[hoverControls animator] setAlphaValue:0.0];

}

- (void)mouseMoved:(NSEvent *)event
{
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.2f];
	
	[[hoverControls animator] setAlphaValue:0.7];
	
	[NSAnimationContext endGrouping];

	
	hideCounter = 3;
	
}

- (void)mouseExited:(NSEvent *)event
{
	
	hideCounter = 3;

}



@end
