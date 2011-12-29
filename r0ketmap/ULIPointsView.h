//
//  ULIPointsView.h
//  r0ketmap
//
//  Created by Uli Kusterer on 28.12.11.
//  Copyright (c) 2011 The Void Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ULIPointsView : NSView
{
	NSMutableArray	*	tags;
	NSPoint				topRightCorner;
	NSPoint				bottomLeftCorner;
	NSInteger			selectedTag;
	NSPoint				houseBottomLeft;
	NSPoint				houseBottomRight;
	NSPoint				houseTopRight;
	NSPoint				houseTopLeft;
}

-(void)	removeAllTags;
-(void)	addTagWithID: (NSInteger)tagID atPoint: (NSPoint)position floor: (NSInteger)floor name: (NSString*)nickName;

@end
