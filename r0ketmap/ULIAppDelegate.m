//
//  ULIAppDelegate.m
//  r0ketmap
//
//  Created by Uli Kusterer on 28.12.11.
//  Copyright (c) 2011 The Void Software. All rights reserved.
//

#import "ULIAppDelegate.h"
#import "JSONKit.h"

@implementation ULIAppDelegate

@synthesize window = _window;
@synthesize pointsView = _pointsView;
@synthesize timeSlider = _timeSlider;
@synthesize dateField = _dateField;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	archiveFilePaths = [[NSMutableArray alloc] init];
	
	NSString		*	archiveFolder = [@"~/r0ketmap" stringByExpandingTildeInPath];
	
	if( ![[NSFileManager defaultManager] fileExistsAtPath: archiveFolder] )
		[[NSFileManager defaultManager] createDirectoryAtPath: archiveFolder withIntermediateDirectories: NO attributes: nil error: nil];
	
	for( NSString *subpath in [[NSFileManager defaultManager] enumeratorAtPath: archiveFolder] )
	{
		if( [[subpath pathExtension] isEqualToString: @"json"] )
		{
			[archiveFilePaths addObject: [archiveFolder stringByAppendingPathComponent: subpath]];
		}
	}
	
	refreshTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0 target: self selector: @selector(fetchNewData:) userInfo: nil repeats: YES];
	
	[self fetchNewData: nil];
}


-(void)	fetchNewData: (NSTimer*)sender
{
	NSData	*	theData = [NSData dataWithContentsOfURL: [NSURL URLWithString: @"http://176.99.39.100/tracking.json"]];

	//NSLog( @"%@", theData );

	NSError		*	err = nil;
	JSONDecoder	*	theDecoder = [JSONDecoder decoder];
	NSDictionary*	decodedObject = [theDecoder objectWithData: theData error: &err];
	if( !decodedObject && err != nil )
		NSLog( @"%@", err );
	NSArray*		readers = [decodedObject objectForKey: @"reader"];
	
	//NSLog( @"%@", decodedObject );
	
	[self.pointsView removeAllTags];
	
	for( NSDictionary* theTag in [decodedObject objectForKey: @"tag"] )
	{
		NSInteger		theID = [[theTag objectForKey: @"id"] integerValue];
		
		NSPoint	pos = NSMakePoint( [[theTag objectForKey: @"px"] doubleValue], [[theTag objectForKey: @"py"] doubleValue] );
		
		NSInteger	floorNum = 0;
		NSInteger	readerID = [[theTag objectForKey: @"reader"] integerValue];
		for( NSDictionary* reader in readers )
		{
			if( [[reader objectForKey: @"id"] integerValue] == readerID )
				floorNum = [[reader objectForKey: @"floor"] integerValue];
		}
		
		[self.pointsView addTagWithID: theID atPoint: pos floor: floorNum name: [theTag objectForKey: @"nick"]];
	}
	
	[self.pointsView setNeedsDisplay: YES];
	
	NSString	*	fpath = [[NSString stringWithFormat: @"~/r0ketmap/archive%f.json", [NSDate timeIntervalSinceReferenceDate]] stringByExpandingTildeInPath];
	[theData writeToFile: fpath atomically: YES];
	
	[archiveFilePaths addObject: fpath];
	[_timeSlider setMaxValue: [archiveFilePaths count]];
	[_timeSlider setDoubleValue: [archiveFilePaths count]];
	
	//NSLog( @"%lu tags", [[decodedObject objectForKey: @"tag"] count] );
}


-(IBAction)	timeSliderChanged: (id)sender
{
	if( [sender doubleValue] >= [sender maxValue] )
	{
		[refreshTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
		[_dateField setStringValue: @"Live"];
	}
	else
	{
		[refreshTimer setFireDate: [NSDate distantFuture]];
		
		NSString	*	fpath = [archiveFilePaths objectAtIndex: [sender doubleValue]];
		NSData		*	theData = [NSData dataWithContentsOfFile: fpath];
		JSONDecoder	*	theDecoder = [JSONDecoder decoder];
		NSDictionary*	decodedObject = [theDecoder objectWithData: theData];
		NSArray		*	readers = [decodedObject objectForKey: @"reader"];
		
		[self.pointsView removeAllTags];
		
		for( NSDictionary* theTag in [decodedObject objectForKey: @"tag"] )
		{
			NSInteger		theID = [[theTag objectForKey: @"id"] integerValue];
			
			NSPoint	pos = NSMakePoint( [[theTag objectForKey: @"px"] doubleValue], [[theTag objectForKey: @"py"] doubleValue] );
			
			NSInteger	floorNum = 0;
			NSInteger	readerID = [[theTag objectForKey: @"reader"] integerValue];
			for( NSDictionary* reader in readers )
			{
				if( [[reader objectForKey: @"id"] integerValue] == readerID )
					floorNum = [[reader objectForKey: @"floor"] integerValue];
			}
			
			[self.pointsView addTagWithID: theID atPoint: pos floor: floorNum name: [theTag objectForKey: @"nick"]];
		}
		
		[self.pointsView setNeedsDisplay: YES];
		
		NSString	*	timeStampString = [[[fpath lastPathComponent] stringByDeletingPathExtension] substringFromIndex: 7];
		NSDate		*	date = [NSDate dateWithTimeIntervalSinceReferenceDate: [timeStampString	doubleValue]];
		NSString	*	dateStr = [NSDateFormatter localizedStringFromDate: date dateStyle: NSDateFormatterShortStyle timeStyle: NSDateFormatterMediumStyle];
		[_dateField setStringValue: dateStr];
	}
}

@end
