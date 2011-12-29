//
//  ULIAppDelegate.h
//  r0ketmap
//
//  Created by Uli Kusterer on 28.12.11.
//  Copyright (c) 2011 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ULIPointsView.h"


@interface ULIAppDelegate : NSObject <NSApplicationDelegate>
{
	NSTimer			*	refreshTimer;
	NSMutableArray	*	archiveFilePaths;
}

@property (assign) IBOutlet NSWindow		*	window;
@property (assign) IBOutlet ULIPointsView	*	pointsView;
@property (assign) IBOutlet NSSlider		*	timeSlider;
@property (assign) IBOutlet NSTextField		*	dateField;

-(void)	fetchNewData: (NSTimer*)sender;

@end
