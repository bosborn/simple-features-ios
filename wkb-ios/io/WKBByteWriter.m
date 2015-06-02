//
//  WKBByteWriter.m
//  wkb-ios
//
//  Created by Brian Osborn on 5/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "WKBByteWriter.h"

@implementation WKBByteWriter

-(instancetype) init{
    self = [super init];
    if(self != nil){
        self.os = [[NSOutputStream alloc] initToMemory];
        [self.os open];
    }
    return self;
}

-(void) close{
    [self.os close];
}

-(NSData *) getData{
    return [self.os propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}

-(int) size{
    return [[self getData] length];
}

-(void) writeString: (NSString *) value{
    NSData *data = [[NSData alloc] initWithData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    [self.os write:[data bytes] maxLength:[value length]];
}

-(void) writeByte: (NSNumber *) value{
    NSData *data = [NSData dataWithBytes:&value length:1];
    [self.os write:[data bytes]  maxLength:1];
}

-(void) writeInt: (NSNumber *) value{
    
    uint32_t v = [value intValue];
    
    if(self.byteOrder == CFByteOrderBigEndian){
        v = CFSwapInt32HostToBig(v);
    }else{
        v = CFSwapInt32HostToLittle(v);
    }
    
    NSData *data = [NSData dataWithBytes:v length:4];
    [self.os write:[data bytes]  maxLength:4];
}

-(void) writeDouble: (NSDecimalNumber *) value{
    
    union DoubleSwap {
        double v;
        uint64_t sv;
    } result;
    result.v = [value doubleValue];
    
    if(self.byteOrder == CFByteOrderBigEndian){
        result.sv = CFSwapInt64HostToBig(result.sv);
    }else{
        result.sv = CFSwapInt64HostToLittle(result.sv);
    }

    NSData *data = [NSData dataWithBytes:result.sv length:8];
    [self.os write:[data bytes]  maxLength:8];
}

@end
