//
//  SFPolyhedralSurface.m
//  sf-ios
//
//  Created by Brian Osborn on 6/2/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "SFPolyhedralSurface.h"

@implementation SFPolyhedralSurface

-(instancetype) init{
    self = [self initWithHasZ:false andHasM:false];
    return self;
}

-(instancetype) initWithHasZ: (BOOL) hasZ andHasM: (BOOL) hasM{
    return [self initWithType:SF_POLYHEDRALSURFACE andHasZ:hasZ andHasM:hasM];
}

-(instancetype) initWithType: (enum SFGeometryType) geometryType andHasZ: (BOOL) hasZ andHasM: (BOOL) hasM{
    self = [super initWithType:geometryType andHasZ:hasZ andHasM:hasM];
    if(self != nil){
        self.polygons = [[NSMutableArray alloc] init];
    }
    return self;
}

-(NSMutableArray<SFPolygon *> *) patches{
    return [self polygons];
}

-(void) setPatches: (NSMutableArray<SFPolygon *> *) patches{
    [self setPolygons:patches];
}

-(void) addPolygon: (SFPolygon *) polygon{
    [self.polygons addObject:polygon];
}

-(void) addPatch: (SFPolygon *) patch{
    [self addPolygon:patch];
}

-(void) addPolygons: (NSArray<SFPolygon *> *) polygons{
    [self.polygons addObjectsFromArray:polygons];
}

-(void) addPatches: (NSArray<SFPolygon *> *) patches{
    [self addPolygons:patches];
}

-(int) numPolygons{
    return (int)self.polygons.count;
}

-(int) numPatches{
    return [self numPolygons];
}

-(SFPolygon *) polygonAtIndex: (int) n{
    return [self.polygons objectAtIndex:n];
}

-(SFPolygon *) patchAtIndex: (int) n{
    return [self polygonAtIndex:n];
}

-(BOOL) isEmpty{
    return self.polygons.count == 0;
}

-(BOOL) isSimple{
    [NSException raise:@"Unsupported" format:@"Is Simple not implemented for Polyhedral Surface"];
    return NO;
}

-(id) mutableCopyWithZone: (NSZone *) zone{
    SFPolyhedralSurface *polyhedralSurface = [[SFPolyhedralSurface alloc] initWithHasZ:self.hasZ andHasM:self.hasM];
    for(SFPolygon *polygon in self.polygons){
        [polyhedralSurface addPolygon:[polygon mutableCopy]];
    }
    return polyhedralSurface;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    
    [encoder encodeObject:self.polygons forKey:@"polygons"];
}

- (id) initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        _polygons = [decoder decodeObjectForKey:@"polygons"];
    }
    return self;
}

- (BOOL)isEqualToPolyhedralSurface:(SFPolyhedralSurface *)polyhedralSurface {
    if (self == polyhedralSurface)
        return YES;
    if (polyhedralSurface == nil)
        return NO;
    if (![super isEqual:polyhedralSurface])
        return NO;
    if (self.polygons == nil) {
        if (polyhedralSurface.polygons != nil)
            return NO;
    } else if (![self.polygons isEqual:polyhedralSurface.polygons])
        return NO;
    return YES;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[SFPolyhedralSurface class]]) {
        return NO;
    }
    
    return [self isEqualToPolyhedralSurface:(SFPolyhedralSurface *)object];
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = [super hash];
    result = prime * result
        + ((self.polygons == nil) ? 0 : [self.polygons hash]);
    return result;
}

@end