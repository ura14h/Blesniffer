//
//  CC2540Record.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/11.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CC2540Record : NSObject

+ (instancetype)cc2540recordWithBytes:(void *)bytes length:(NSInteger)length;

@end

// MARK: -

@interface CC2540CapturedRecord : CC2540Record

@property (assign) struct timeval packetTimestamp;
@property (assign) uint32 packetLength;
@property (assign) void *packetBytes;
@property (assign) int packetRssi;
@property (assign) int packetChannel;
@property (assign) int packetStatus;
@property (assign) int packetPduType;

@end

// MARK: -

@interface CC2540UnknownRecord : CC2540Record

// No extended implementations.

@end
