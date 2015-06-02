//
//  WKBLineString.m
//  wkb-ios
//
//  Created by Brian Osborn on 6/2/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "WKBLineString.h"

@implementation WKBLineString

-(instancetype) initWithHasZ: (BOOL) hasZ andHasM: (BOOL) hasM{
    return [self initWithType:WKB_LINESTRING andHasZ:hasZ andHasM:hasM];
}

-(instancetype) initWithType: (enum WKBGeometryType) geometryType andHasZ: (BOOL) hasZ andHasM: (BOOL) hasM{
    self = [super initWithType:geometryType andHasZ:hasZ andHasM:hasM];
    if(self != nil){
        self.points = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) addPoint: (WKBPoint *) point{
    [self.points addObject:point];
}

-(NSUInteger) numPoints{
    return [self.points count];
}

@end
