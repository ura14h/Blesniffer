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
	struct pcap_pkthdr header;
	header.caplen = record.packetLength;
	header.len = record.packetLength;
	header.ts = record.packetTimestamp;
	pcap_dump((u_char *)self.dumper, &header, record.packetBytes);

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
