//
//  PcapDumpFile.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/11.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <pcap/pcap.h>
#import "PcapDumpFile.h"
#import "CC2540Record.h"


@interface PcapDumpFile ()

@property (assign) pcap_t *handle;
@property (assign) pcap_dumper_t *dumper;

@end

@implementation PcapDumpFile

- (instancetype)init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_handle = nil;
	_dumper = nil;
	
	return self;
}

- (void)dealloc {
	[self close];
	
	_handle = nil;
	_dumper = nil;
}

- (BOOL)open:(NSString *)path {
	const int maxPacketSize = 4096;
	
	pcap_t *handle = pcap_open_dead(DLT_BLUETOOTH_LE_LL, maxPacketSize);
	if (!handle) {
		return NO;
	}
	pcap_dumper_t *dumper = pcap_dump_open(handle, [path cStringUsingEncoding:NSUTF8StringEncoding]);
	if (!dumper) {
		pcap_close(handle);
		return NO;
	}

	self.handle = handle;
	self.dumper = dumper;
	
	return YES;
}

- (BOOL)write: (CC2540CapturedRecord *)record {
	const time_t nanoSeconds = 1000000000;
	const time_t microSeconds = 1000000;
	const time_t nanoToMicro = nanoSeconds / microSeconds;
	
	uint32 length = (uint32)record.packet.length;
	u_char *bytes = (u_char *)record.packet.bytes;
	time_t timestampSecondsPart = (time_t)record.timestamp / nanoSeconds;
	suseconds_t timestampMicrosecondsPart = (record.timestamp % nanoSeconds) / nanoToMicro;
	struct timeval timestamp;
	timestamp.tv_sec = timestampSecondsPart;
	timestamp.tv_usec = timestampMicrosecondsPart;
	
	struct pcap_pkthdr header;
	header.caplen = length;
	header.len = length;
	header.ts = timestamp;
	pcap_dump((u_char *)self.dumper, &header, bytes);

	return YES;
}

- (BOOL)close {
	if (self.dumper) {
		pcap_dump_close(self.dumper);
	}
	if (self.handle) {
		pcap_close(self.handle);
	}
	self.dumper = nil;
	self.handle = nil;
	
	return YES;
}

@end
