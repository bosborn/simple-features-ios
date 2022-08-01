//
//  SFSweepLine.m
//  sf-ios
//
//  Created by Brian Osborn on 1/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "SFSweepLine.h"

@interface SFSweepLine()

/**
 * Polygon rings
 */
@property (nonatomic, strong) NSArray<SFLineString *> *rings;

/**
 * Tree of segments sorted by above-below order
 * TODO performance could be improved with a Red-Black or AVL tree
 */
@property NSMutableOrderedSet<SFSegment *> *tree;

/**
 * Mapping between ring, edges, and segments
 */
@property NSMutableDictionary<NSNumber *, NSMutableDictionary<NSNumber *, SFSegment *> *> *segments;

@end

@implementation SFSweepLine

-(instancetype) initWithRings: (NSArray<SFLineString *> *) rings{
    self = [super init];
    if(self != nil){
        self.rings = rings;
        self.tree = [[NSMutableOrderedSet alloc] init];
        self.segments = [NSMutableDictionary dictionary];
    }
    return self;
}

-(SFSegment *) addEvent: (SFEvent *) event{
    
    SFSegment *segment = [self createSegmentForEvent:event];
    
    // Add to the tree
    int insertLocation = [self locationOfSegment:segment atX:[event.point.x doubleValue]];
    [self.tree insertObject:segment atIndex:insertLocation];
    
    // Update the above and below pointers
    SFSegment *next = [self higherSegment:insertLocation];
    SFSegment *previous = [self lowerSegment:insertLocation];
    if (next != nil) {
        segment.above = next;
        next.below = segment;
    }
    if (previous != nil) {
        segment.below = previous;
        previous.above = segment;
    }
    
    // Add to the segments map
    NSNumber *ringNumber = [NSNumber numberWithInt:segment.ring];
    NSMutableDictionary<NSNumber *, SFSegment *> *edgeDictionary = [self.segments objectForKey:ringNumber];
    if (edgeDictionary == nil) {
        edgeDictionary = [NSMutableDictionary dictionary];
        [self.segments setObject:edgeDictionary forKey:ringNumber];
    }
    [edgeDictionary setObject:segment forKey:[NSNumber numberWithInt:segment.edge]];
    
    return segment;
}

/**
 * Get the location where the segment should be inserted or is located
 *
 * @param segment
 *            segment
 * @param x
 *            x value
 * @return index location
 */
-(int) locationOfSegment: (SFSegment *) segment atX: (double) x{
    
    NSUInteger insertLocation = [self.tree indexOfObject:segment inSortedRange:NSMakeRange(0, self.tree.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(SFSegment *segment1, SFSegment *segment2){
        
        double y1 = [self yValueAtX:x forSegment:segment1];
        double y2 = [self yValueAtX:x forSegment:segment2];
        
        NSComparisonResult compare;
        if (y1 < y2) {
            compare = NSOrderedAscending;
        } else if (y2 < y1) {
            compare = NSOrderedDescending;
        } else if (segment1.ring < segment2.ring) {
            compare = NSOrderedAscending;
        } else if (segment2.ring < segment1.ring) {
            compare = NSOrderedDescending;
        } else if (segment1.edge < segment2.edge) {
            compare = NSOrderedAscending;
        } else if (segment2.edge < segment1.edge) {
            compare = NSOrderedDescending;
        } else {
            compare = NSOrderedSame;
        }
        
        return compare;
    }];
    
    return (int)insertLocation;
}

/**
 * Get the segment lower than the location
 *
 * @param location
 *            segment location
 * @return lower segment
 */
-(SFSegment *) lowerSegment: (int) location{
    SFSegment *lower = nil;
    if(location - 1 > 0){
        lower = [self.tree objectAtIndex:location - 1];
    }
    return lower;
}

/**
 * Get the segment higher than the location
 *
 * @param location
 *            segment location
 * @return higher segment
 */
-(SFSegment *) higherSegment: (int) location{
    SFSegment *higher = nil;
    if(location + 1 < self.tree.count){
        higher = [self.tree objectAtIndex:location + 1];
    }
    return higher;
}

/**
 * Create a segment from the event
 *
 * @param event
 *            event
 * @return segment
 */
-(SFSegment *) createSegmentForEvent: (SFEvent *) event{

    int edgeNumber = event.edge;
    int ringNumber = event.ring;
    
    SFLineString *ring = [self.rings objectAtIndex:ringNumber];
    NSArray<SFPoint *> *points = ring.points;
    
    SFPoint *point1 = [points objectAtIndex:edgeNumber];
    SFPoint *point2 = [points objectAtIndex:(edgeNumber + 1) % points.count];
    
    SFPoint *left = nil;
    SFPoint *right = nil;
    if([SFSweepLine xyOrderWithPoint:point1 andPoint:point2] == NSOrderedAscending){
        left = point1;
        right = point2;
    } else {
        right = point1;
        left = point2;
    }
    
    SFSegment *segment = [[SFSegment alloc] initWithEdge:edgeNumber andRing:ringNumber andLeftPoint:left andRightPoint:right];
    
    return segment;
}

-(SFSegment *) findEvent: (SFEvent *) event{
    return [[self.segments objectForKey:[NSNumber numberWithInt:event.ring]] objectForKey:[NSNumber numberWithInt:event.edge]];
}

-(BOOL) intersectWithSegment: (SFSegment *) segment1 andSegment: (SFSegment *) segment2{

    BOOL intersect = NO;
    
    if (segment1 != nil && segment2 != nil) {
        
        int ring1 = segment1.ring;
        int ring2 = segment2.ring;
        
        BOOL consecutive = ring1 == ring2;
        if (consecutive) {
            int edge1 = segment1.edge;
            int edge2 = segment2.edge;
            int ringPoints = [[self.rings objectAtIndex:ring1] numPoints];
            consecutive = (edge1 + 1) % ringPoints == edge2
                || edge1 == (edge2 + 1) % ringPoints;
        }
        
        if (!consecutive) {
            
            double left = [SFSweepLine isPoint:segment2.leftPoint leftOfSegment:segment1];
            double right = [SFSweepLine isPoint:segment2.rightPoint leftOfSegment:segment1];
            
            if (left * right <= 0) {
                
                left = [SFSweepLine isPoint:segment1.leftPoint leftOfSegment:segment2];
                right = [SFSweepLine isPoint:segment1.rightPoint leftOfSegment:segment2];
                
                if (left * right <= 0) {
                    intersect = YES;
                }
            }
        }
    }
    
    return intersect;
}

-(void) removeSegment: (SFSegment *) segment{

    BOOL removed = [self removeSegment:segment atX:[segment.rightPoint.x doubleValue]];
    if (!removed) {
        removed = [self removeSegment:segment atX:[segment.leftPoint.x doubleValue]];
    }
    
    if (removed) {
        
        SFSegment *above = segment.above;
        SFSegment *below = segment.below;
        if (above != nil) {
            above.below = below;
        }
        if (below != nil) {
            below.above = above;
        }
        
        [[self.segments objectForKey:[NSNumber numberWithInt:segment.ring]] removeObjectForKey:[NSNumber numberWithInt:segment.edge]];
    }
}

/**
 * Remove the segment from the tree using the x value
 *
 * @param segment
 *            segment
 * @param x
 *            value
 * @return true if removed
 */
-(BOOL) removeSegment: (SFSegment *) segment atX: (double) x{
    
    BOOL removed = NO;
    
    int location = [self locationOfSegment:segment atX:x];
    if(location < self.tree.count){
        SFSegment *treeSegment = [self.tree objectAtIndex:location];
        if([treeSegment isEqual:segment]){
            [self.tree removeObjectAtIndex:location];
            removed = YES;
        }
    }
    
    return removed;
}

/**
 * Get the segment y value at the x location by calculating the line slope
 *
 * @param x
 *            current point x value
 * @param segment
 *            segment
 *
 * @return segment y value
 */
-(double) yValueAtX: (double) x forSegment: (SFSegment *) segment{
    
    SFPoint *left = segment.leftPoint;
    SFPoint *right = segment.rightPoint;
    
    double m = ([right.y doubleValue] - [left.y doubleValue]) / ([right.x doubleValue] - [left.x doubleValue]);
    double b = [left.y doubleValue] - (m * [left.x doubleValue]);
    
    double y = (m * x) + b;
    
    return y;
}

+(NSComparisonResult) xyOrderWithPoint: (SFPoint *) point1 andPoint: (SFPoint *) point2{
    NSComparisonResult value = NSOrderedSame;
    if ([point1.x doubleValue] > [point2.x doubleValue]) {
        value = NSOrderedDescending;
    } else if ([point1.x doubleValue] < [point2.x doubleValue]) {
        value = NSOrderedAscending;
    } else if ([point1.y doubleValue] > [point2.y doubleValue]) {
        value = NSOrderedDescending;
    } else if ([point1.y doubleValue] < [point2.y doubleValue]) {
        value = NSOrderedAscending;
    }
    return value;
}

/**
 * Check where the point is (left, on, right) relative to the line segment
 *
 * @param point
 *            point
 * @param segment
 *            segment
 * @return > 0 if left, 0 if on, < 0 if right
 */
+(double) isPoint: (SFPoint *) point leftOfSegment: (SFSegment *) segment{
    return [self isPoint:point leftOfPoint1:segment.leftPoint toPoint2:segment.rightPoint];
}

/**
 * Check where point is (left, on, right) relative to the line from point 1 to point 2
 *
 * @param point
 *            point
 * @param point1
 *            point 1
 * @param point2
 *            point 2
 * @return > 0 if left, 0 if on, < 0 if right
 */
+(double) isPoint: (SFPoint *) point leftOfPoint1: (SFPoint *) point1 toPoint2: (SFPoint *) point2{
    return ([point2.x doubleValue] - [point1.x doubleValue])
    * ([point.y doubleValue] - [point1.y doubleValue])
    - ([point.x doubleValue] - [point1.x doubleValue])
    * ([point2.y doubleValue] - [point1.y doubleValue]);
}

@end
