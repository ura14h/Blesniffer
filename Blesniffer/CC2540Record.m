//
//  CC2540Record.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/11.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import "CC2540Record.h"


struct CC2540CapturedRecordHeader {
	uint8  type;		// 0x00 is capture data.
	uint16 length;		// Hmmm... I don't use this field because its value may be corrupted.
	uint32 timestamp;
	uint8 preamble[1];	// BLE preamble?
	uint8 packet[0];	// BLE address?
} __attribute__((packed));

struct CC2540CapturedRecordFooter {
	uint8 fcs1;			// it contains RSSI ?
	uint8 fsc2;			// it contains that this frame is valid or invalid ?
} __attribute__((packed));

static const size_t MinimumRecordLength =
	sizeof(struct CC2540CapturedRecordHeader) + sizeof(struct CC2540CapturedRecordFooter);

// MARK: -

@interface CC2540Record ()

- (instancetype)initWithBytes:(void *)bytes length:(NSInteger)length;

@end

@implementation CC2540Record

+ (instancetype)cc2540recordWithBytes:(void *)bytes length:(NSInteger)length {
	if (length < 1) {
		return [[CC2540UnknownRecord alloc] initWithBytes:bytes length:length];
	}
	
	NSInteger type = *((uint8 *)bytes);
	if (length < MinimumRecordLength || type != 0x00) {
		return [[CC2540UnknownRecord alloc] initWithBytes:bytes length:length];
	}
	
	return [[CC2540CapturedRecord alloc] initWithBytes:bytes length:length];
}

- (instancetype)initWithBytes:(void *)bytes length:(NSInteger)length {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	return self;
}

@end

// MARK: -

@implementation CC2540CapturedRecord

- (instancetype)initWithBytes:(void *)bytes length:(NSInteger)length {
	self = [super initWithBytes:bytes length:length];
	if (!self) {
		return nil;
	}

	[self parseBytes:bytes length:length];
	
	return self;
}

- (void)dealloc {
	if (self.packetBytes) {
		free(self.packetBytes);
		self.packetBytes = nil;
	}
}

- (void)parseBytes: (void *)bytes length:(NSInteger)length {
	struct CC2540CapturedRecordHeader *header = (struct CC2540CapturedRecordHeader *)bytes;
	
	const time_t nanoSeconds = 1000000000;
	const time_t microSeconds = 1000000;
	const time_t nanoToMicro = nanoSeconds / microSeconds;
	struct timeval packetTimestamp;
	packetTimestamp.tv_sec = (time_t)header->timestamp / nanoSeconds;
	packetTimestamp.tv_usec = (header->timestamp % nanoSeconds) / nanoToMicro;
	
	uint32 packetLength = (uint32)((size_t)length - MinimumRecordLength);
	void *packetBytes = malloc(packetLength);
	memcpy(packetBytes, header->packet, packetLength);

	self.packetTimestamp = packetTimestamp;
	self.packetLength = packetLength;
	self.packetBytes = packetBytes;
}

@end

// MARK: -

@implementation CC2540UnknownRecord

// No implementations.

@end
