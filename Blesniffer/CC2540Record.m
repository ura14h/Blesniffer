//
//  CC2540Record.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/11.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import "CC2540Record.h"


struct CC2540CapturedRecordHeader {
	uint8  command;		// 0x00 for capture data.
	uint16 length;		// Hmmm... I don't use this field because its value may be corrupted.
	uint32 timestamp;
	uint8 preamble[1];	// BLE preamble?
	uint8 packet[0];	// BLE address?
} __attribute__((packed));

struct CC2540CapturedRecordFooter {
	uint8 fcs1;			// it contains RSSI ?
	uint8 fsc2;			// it contains that this frame is valid or invalid ?
} __attribute__((packed));

static const NSInteger MinimumRecordLength =
	sizeof(struct CC2540CapturedRecordHeader) + sizeof(struct CC2540CapturedRecordFooter);


@interface CC2540Record ()

- (instancetype)initWithBytes:(void *)bytes length:(NSInteger)length;

@end

@implementation CC2540Record

+ (instancetype)cc2540recordWithBytes:(void *)bytes length:(NSInteger)length {
	if (length < 1) {
		return [[CC2540UnknownRecord alloc] initWithBytes:bytes length:length];
	}
	NSInteger recordType = *((uint8 *)bytes);
	if (length < MinimumRecordLength || recordType != 0x00) {
		return [[CC2540UnknownRecord alloc] initWithBytes:bytes length:length];
	}
	
	return [[CC2540CapturedRecord alloc] initWithBytes:bytes length:length];
}

- (instancetype)initWithBytes:(void *)bytes length:(NSInteger)length {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_type = *((uint8 *)bytes);
	_length = length;
	
	return self;
}

- (NSString *)description {
	NSString *description = [NSString stringWithFormat:@"<%@: %p> type=%ld, length=%ld", [self class], self, self.type, self.length];
	return description;
}

@end


@implementation CC2540CapturedRecord

- (instancetype)initWithBytes:(void *)bytes length:(NSInteger)length {
	self = [super initWithBytes:bytes length:length];
	if (!self) {
		return nil;
	}
	
	struct CC2540CapturedRecordHeader *header = (struct CC2540CapturedRecordHeader *)bytes;
	NSUInteger timestamp = (NSUInteger)(header->timestamp);
	void *packetAddress = header->packet;
	NSUInteger packetLength = length - MinimumRecordLength;
	
	_timestamp = timestamp;
	_packet = [NSData dataWithBytes:packetAddress length:packetLength];
	
	return self;
}

@end


@implementation CC2540UnknownRecord

// No implementations.

@end
