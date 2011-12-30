//
//  ULIPointsView.m
//  r0ketmap
//
//  Created by Uli Kusterer on 28.12.11.
//  Copyright (c) 2011 The Void Software. All rights reserved.
//

#import "ULIPointsView.h"


#define ULI_USER			1093612292LL

#define LEON_USER 			0xc1897372LL

#define DEFAULT_SELECTED	ULI_USER


@interface ULIPointsView ()

-(void)	commonInit;

@end


@interface ULITagEntry : NSObject
{
   NSInteger	tagID;
   NSPoint		tagPosition;
   NSInteger	tagFloor;
   NSString	*	nickName;
}

@property (assign) NSInteger	tagID;
@property (assign) NSPoint		tagPosition;
@property (assign) NSInteger	tagFloor;
@property (copy) NSString	*	nickName;
@property (readonly) NSString*	hashString;

-(NSString*)	searchString;

@end


static void 		sha_simple(uint32_t* digest, char* message, uint32_t len);
static  uint32_t	rol32(uint32_t word, int shift);
static void			sha_transform(uint32_t *digest, const unsigned char *in, uint32_t *W);
static void			sha_init(uint32_t *buf);
void 				hash(uint32_t uid, uint16_t* hashes);
static int			delta(uint16_t crc1, uint16_t crc2);

#define HASHCOUNT		18


uint32_t prefix[HASHCOUNT];
uint16_t myhashes[HASHCOUNT];
uint16_t best[HASHCOUNT];
static bool		havePrefixes = false;


void hash(uint32_t uid, uint16_t* hashes) {
	
	if( !havePrefixes )
	{
		havePrefixes = true;
		
		// initialize prefixes
		prefix[ 0] = 0x6220ddaf;
		prefix[ 1] = 0x4f94e8fc;
		prefix[ 2] = 0x540aa8ab;
		prefix[ 3] = 0x728fefad;
		prefix[ 4] = 0xc5a14b8e;
		prefix[ 5] = 0xa0ac8310;
		prefix[ 6] = 0xf20b27dc;
		prefix[ 7] = 0xd539d677;
		prefix[ 8] = 0x145f8491;
		prefix[ 9] = 0xbce8d16e;
		prefix[10] = 0x4a5efcc1;
		prefix[11] = 0xc4da23cf;
		prefix[12] = 0x90c7e131;
		prefix[13] = 0x9e19ea94;
		prefix[14] = 0x7f20073a;
		prefix[15] = 0x5366be65;
		prefix[16] = 0xb53f096f;
		prefix[17] = 0x57f28a08;
		
		// compute my hash
		uint32_t myid = DEFAULT_SELECTED;
		hash(myid, myhashes);
		for(int i = 0; i < HASHCOUNT; i++) {
			best[i] = 0xffff ^ myhashes[i];
		}
	}
	
    uint32_t digest[5];
    uint32_t message[2];

    for (int i = 0; i < HASHCOUNT; i++) {
        message[0] = prefix[i];
        message[1] = uid;
        sha_simple(digest, (char*) message, 8);
        digest[0] ^= digest[1] ^ digest[2] ^ digest[3] ^ digest[4];
        hashes[i] = (digest[0] ^ (digest[1] >> 16)) & 0xffff;
    }
}


static void sha_simple(uint32_t* digest, char* message, uint32_t len) {
    // use the sha1 transform without padding
    uint32_t tmp[80];
    char buf[64];
    int offset;
    sha_init(digest);
    for(offset = 0; offset + 64 < len; offset += 64) {
        memcpy(buf, message + offset - 8, 64);
        memset(tmp, 0, sizeof(tmp));
        sha_transform(digest, (const unsigned char*)buf, tmp);
    }
    memcpy(buf, message + offset, len - offset);
    buf[len - offset] = 128;
    memset(buf + 1 + (len - offset), 0, 63 - (len-offset));
    memset(tmp, 0, sizeof(tmp));
    sha_transform(digest, (const unsigned char*)buf, tmp);
}

/*
 * SHA transform algorithm, originally taken from code written by
 * Peter Gutmann, and placed in the public domain.
 */

static  uint32_t
rol32(uint32_t word, int shift)
{
	return (word << shift) | (word >> (32 - shift));
}

/* The SHA f()-functions.  */

#define f1(x,y,z)   (z ^ (x & (y ^ z)))		/* x ? y : z */
#define f2(x,y,z)   (x ^ y ^ z)			/* XOR */
#define f3(x,y,z)   ((x & y) + (z & (x ^ y)))	/* majority */

/* The SHA Mysterious Constants */

#define K1  1518500249
#define K2  1859775393
#define K3  2400959708
#define K4  3395469782

// #define K1  0x5A827999L			/* Rounds  0-19: sqrt(2) * 2^30 */
// #define K2  0x6ED9EBA1L			/* Rounds 20-39: sqrt(3) * 2^30 */
// #define K3  0x8F1BBCDCL			/* Rounds 40-59: sqrt(5) * 2^30 */
// #define K4  0xCA62C1D6L			/* Rounds 60-79: sqrt(10) * 2^30 */

/**
 * sha_transform - single block SHA1 transform
 *
 * @digest: 160 bit digest to update
 * @data:   512 bits of data to hash
 * @W:      80 words of workspace (see note)
 *
 * This function generates a SHA1 digest for a single 512-bit block.
 * Be warned, it does not handle padding and message digest, do not
 * confuse it with the full FIPS 180-1 digest algorithm for variable
 * length messages.
 *
 * Note: If the hash is security sensitive, the caller should be sure
 * to clear the workspace. This is left to the caller to avoid
 * unnecessary clears between chained hashing operations.
 */
static void sha_transform(uint32_t *digest, const unsigned char *in, uint32_t *W)
{
	uint32_t a, b, c, d, e, t, i;

	for (i = 0; i < 16; i++) {
		int ofs = 4 * i;

		/* word load/store may be unaligned here, so use bytes instead */
		W[i] =
			(in[ofs+0] << 24) |
			(in[ofs+1] << 16) |
			(in[ofs+2] << 8) |
			 in[ofs+3];
	}

	for (i = 0; i < 64; i++)
		W[i+16] = rol32(W[i+13] ^ W[i+8] ^ W[i+2] ^ W[i], 1);

	a = digest[0];
	b = digest[1];
	c = digest[2];
	d = digest[3];
	e = digest[4];

	for (i = 0; i < 20; i++) {
		t = f1(b, c, d) + K1 + rol32(a, 5) + e + W[i];
		e = d; d = c; c = rol32(b, 30); b = a; a = t;
	}

	for (; i < 40; i ++) {
		t = f2(b, c, d) + K2 + rol32(a, 5) + e + W[i];
		e = d; d = c; c = rol32(b, 30); b = a; a = t;
	}

	for (; i < 60; i ++) {
		t = f3(b, c, d) + K3 + rol32(a, 5) + e + W[i];
		e = d; d = c; c = rol32(b, 30); b = a; a = t;
	}

	for (; i < 80; i ++) {
		t = f2(b, c, d) + K4 + rol32(a, 5) + e + W[i];
		e = d; d = c; c = rol32(b, 30); b = a; a = t;
	}

	digest[0] += a;
	digest[1] += b;
	digest[2] += c;
	digest[3] += d;
	digest[4] += e;
}

/**
 * sha_init - initialize the vectors for a SHA1 digest
 * @buf: vector to initialize
 */
static void sha_init(uint32_t *buf)
{
    buf[0] = 1732584193;
    buf[1] = 4023233417;
    buf[2] = 2562383102;
    buf[3] =  271733878;
    buf[4] = 3285377520;
}


static int delta(uint16_t crc1, uint16_t crc2) {
    if (crc1 == crc2) {
        return 0;
    }
    uint16_t xor = crc1 ^ crc2;
    int result = 15;
    if (xor > 255) {
        xor >>= 8;
        result -= 8;
    }
    if (xor > 15) {
        xor >>= 4;
        result -= 4;
    }
    if (xor > 3) {
        xor >>= 2;
        result -= 2;
    }
    if (xor > 1) {
        xor >>= 1;
        result -= 1;
    }
    return result;
}



@implementation ULITagEntry

@synthesize tagID;
@synthesize tagPosition;
@synthesize tagFloor;
@synthesize nickName;
@synthesize hashString;

-(void)	dealloc
{
	[hashString release];
	hashString = nil;
	
	[nickName release];
	nickName = nil;
	
	[super dealloc];
}


-(NSString*)	hashString
{
	if( !hashString )
	{
		uint16_t		hashes[HASHCOUNT] = { 0 };
		hash( (uint32_t) tagID, hashes );
		
		NSMutableString	*	hashesStr = [NSMutableString string];
		for( int x = 0; x < HASHCOUNT; x++ )
		{
			int	theDelta = delta( myhashes[x], hashes[x] );
			[hashesStr appendFormat: @" %d", theDelta];
		}
		[hashesStr appendString: @" "];
		hashString = [hashesStr retain];
	}
	
	return hashString;
}


-(NSString*)	searchString
{
	return [NSString stringWithFormat: @"%lX %@ %@", self.tagID, (self.nickName ? self.nickName : @""), self.hashString];
}

@end


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
	[foundTags release];
	
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
	
	foundTags = [[NSMutableIndexSet alloc] init];
}


-(void)	removeAllTags
{
	[tags removeAllObjects];
}


-(void)	addTagWithID: (NSInteger)tagID atPoint: (NSPoint)position floor: (NSInteger)inFloor name: (NSString*)nickName
{
	ULITagEntry		*	tag = [[ULITagEntry alloc] init];
	
	[tag setTagID: tagID];
	[tag setTagPosition: position];
	[tag setTagFloor: inFloor];
	[tag setNickName: nickName];
	
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
	
	if( currTag.tagID == selectedTag || [foundTags containsIndex: currTag.tagID] )
	{
		myTag = currTag;
		NSColor	*	hlColor = [NSColor grayColor];
		if( currTag.tagID == selectedTag )
			hlColor = [NSColor redColor];
		[hlColor set];
		[NSBezierPath strokeRect: tagBox];
		
		NSPoint		textPos = tagBox.origin;
		textPos.x = NSMaxX(tagBox);
		NSDictionary	*	attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName, hlColor, NSBackgroundColorAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
		[[NSString stringWithFormat: @" %llx %@ ", currTag.tagID, currTag.nickName ? currTag.nickName : @""] drawAtPoint: textPos withAttributes: attrs];
		
		NSDictionary	*	attrs2 = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName, [NSColor darkGrayColor], NSForegroundColorAttributeName, nil];
		textPos.y += 16;
		[currTag.hashString drawAtPoint: textPos withAttributes: attrs2];
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


-(IBAction)	takeSearchStringFrom: (id)sender
{
	NSString	*	searchString = [[sender stringValue] lowercaseString];
	[foundTags removeAllIndexes];
	
	for( ULITagEntry * currTag in tags )
	{
		NSString	*	targetString = [[currTag searchString] lowercaseString];
		if( [targetString rangeOfString: searchString].location != NSNotFound )
		{
			[foundTags addIndex: currTag.tagID];
		}
	}
	
	[self setNeedsDisplay: YES];
}

@end
