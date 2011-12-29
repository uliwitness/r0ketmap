//
//  ULIPointsView.m
//  r0ketmap
//
//  Created by Uli Kusterer on 28.12.11.
//  Copyright (c) 2011 The Void Software. All rights reserved.
//

#import "ULIPointsView.h"



@interface ULIPointsView ()

-(void)	commonInit;

@end


@interface ULITagEntry : NSObject
{
   NSInteger	tagID;
   NSPoint		tagPosition;
   NSInteger	tagFloor;
}

@property (assign) NSInteger	tagID;
@property (assign) NSPoint		tagPosition;
@property (assign) NSInteger	tagFloor;

@end


@implementation ULITagEntry

@synthesize tagID;
@synthesize tagPosition;
@synthesize tagFloor;

@end


#define ULI_USER			1093612292LL

#define LEON_USER 			0xc1897372LL

#define DEFAULT_SELECTED	ULI_USER


@implementation ULIPointsView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
   }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
  }
    
    return self;
}


-(void)	dealloc
{
	[tags release];
	
	[super dealloc];
}


-(void)	commonInit
{
	tags = [[NSMutableArray alloc] init];
	topRightCorner = NSPointFromString( [[NSUserDefaults standardUserDefaults] objectForKey: @"ULITopRightCorner"] );
	bottomLeftCorner = NSPointFromString( [[NSUserDefaults standardUserDefaults] objectForKey: @"ULIBottomLeftCorner"] );
	
	selectedTag = DEFAULT_SELECTED;
	
	houseBottomLeft = NSMakePoint( 650 /2, 579 /2 );
	houseBottomRight = NSMakePoint( 431 /2, 836 /2 );
	houseTopRight = NSMakePoint( 286 /2, 492 /2 );
	houseTopLeft = NSMakePoint( 434 /2, 327 /2 );
}


-(void)	removeAllTags
{
	[tags removeAllObjects];
}


-(void)	addTagWithID: (NSInteger)tagID atPoint: (NSPoint)position floor: (NSInteger)inFloor
{
	ULITagEntry		*	tag = [[ULITagEntry alloc] init];
	
	[tag setTagID: tagID];
	[tag setTagPosition: position];
	[tag setTagFloor: inFloor];
	
	[tags addObject: tag];
	
	[tag release];
}


-(ULITagEntry*)	drawOneTag: (ULITagEntry*)currTag
{
	ULITagEntry	*	myTag = nil;
	NSRect			tagBox = { { 0, 0 }, { 8, 8 } };
	
	tagBox.origin = currTag.tagPosition;
	tagBox.origin.x /= 2;
	tagBox.origin.y /= 2;
	
	if( currTag.tagFloor == 1 )
		[[NSColor blueColor] set];
	else if( currTag.tagFloor == 2 )
		[[NSColor greenColor] set];
	else if( currTag.tagFloor == 3 )
		[[NSColor yellowColor] set];
	else
		[[NSColor lightGrayColor] set];

	[NSBezierPath fillRect: tagBox];
	
	if( currTag.tagID == selectedTag )
	{
		myTag = currTag;
		[[NSColor redColor] set];
		[NSBezierPath strokeRect: tagBox];
		
		NSPoint		textPos = tagBox.origin;
		textPos.x = NSMaxX(tagBox);
		NSDictionary	*	attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName, [NSColor redColor], NSBackgroundColorAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
		[[NSString stringWithFormat: @" %llx ", currTag.tagID] drawAtPoint: textPos withAttributes: attrs];
	}

	
	return myTag;
}


- (void)drawRect: (NSRect)dirtyRect
{
	NSBezierPath	*	housePath = [NSBezierPath bezierPath];
	[housePath moveToPoint: houseBottomLeft];
	[housePath lineToPoint: houseBottomRight];
	[housePath lineToPoint: houseTopRight];
	[housePath lineToPoint: houseTopLeft];
	[housePath lineToPoint: houseBottomLeft];
	[[NSColor whiteColor] set];
	[housePath fill];
	
	NSRect	houseBox = NSZeroRect;
	houseBox.origin = bottomLeftCorner;
	houseBox.size.width = topRightCorner.x -bottomLeftCorner.x;
	houseBox.size.height = topRightCorner.y -bottomLeftCorner.y;
	
	[[NSColor greenColor] set];
	[NSBezierPath strokeRect: houseBox];
	
	ULITagEntry	*	myTag = nil;
	
    for( ULITagEntry * currTag in tags )
	{
		ULITagEntry	*	foundTag = [self drawOneTag: currTag];
		if( foundTag )
			myTag = foundTag;
	}
	
	if( myTag )
		[self drawOneTag: myTag];
}


-(void)	mouseDown:(NSEvent *)theEvent
{
	NSPoint	pos = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	if( [theEvent modifierFlags] & NSAlternateKeyMask )
	{
		topRightCorner = pos;
		[[NSUserDefaults standardUserDefaults] setObject: NSStringFromPoint(topRightCorner) forKey: @"ULITopRightCorner"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	else if( [theEvent modifierFlags] & NSCommandKeyMask )
	{
		bottomLeftCorner = pos;
		[[NSUserDefaults standardUserDefaults] setObject: NSStringFromPoint(bottomLeftCorner) forKey: @"ULIBottomLeftCorner"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	else if( [theEvent modifierFlags] & NSShiftKeyMask )
	{
		for( ULITagEntry * currTag in tags )
		{
			if( currTag.tagID == selectedTag )
			{
				pos = currTag.tagPosition;
				break;
			}
		}

		NSLog( @"%@", NSStringFromPoint(pos) );
	}
	else
	{
		for( ULITagEntry * currTag in tags )
		{
			NSRect			tagBox = { { 0, 0 }, { 8, 8 } };

			tagBox.origin = currTag.tagPosition;
			tagBox.origin.x /= 2;
			tagBox.origin.y /= 2;
			
			if( NSPointInRect( pos, tagBox ) )
				selectedTag = currTag.tagID;
		}
	}
	[self setNeedsDisplay: YES];
}

@end
