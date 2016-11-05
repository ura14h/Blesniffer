//
//  main.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UsbDeviceManager.h"
#import "UsbDevice.h"
#import "UsbDeviceInterface.h"
#import "UsbDevicePipe.h"

static volatile BOOL readingPackets = YES;
static void sig_handler(int signo);
static void dump_packet(uint8 *buffer, int length);

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		
		UsbDeviceManager *manager = [UsbDeviceManager new];
		if (![manager open]) {
			return 1;
		}
		
		NSInteger vendorId = 0x0451;
		NSInteger productId = 0x16B3;
		NSArray<UsbDevice *> *deviceList = [manager deviceListWithVendorId:vendorId productId:productId];
		if (deviceList.count < 1) {
			return 1;
		}
		UsbDevice *device = deviceList[0];
		if (![device open]) {
			return 1;
		}

		NSInteger configuration = [device getConfiguration];
		if (configuration < 0) {
			return 1;
		}
		if (![device setConfiguration:configuration]) {
			return 1;
		}
		
		NSArray<UsbDeviceInterface *> *interfaceList = [device interfaceList];
		if (interfaceList.count < 1) {
			return 1;
		}
		UsbDeviceInterface *interface = interfaceList[0];
		if (![interface open]) {
			return 1;
		}
		
		NSArray<UsbDevicePipe *> *pipeList = [interface pipeList];
		if (pipeList.count < 1) {
			return 1;
		}
		NSPredicate *controlPredicate = [NSPredicate predicateWithFormat:@"%K = %d", @"type", UsbDevicePipeTypeControl];
		NSArray<UsbDevicePipe *> *controls = [pipeList filteredArrayUsingPredicate:controlPredicate];
		if (controls.count < 1) {
			return 1;
		}
		UsbDevicePipe *control = controls[0];
		NSPredicate *blukinPredicate = [NSPredicate predicateWithFormat:@"%K = %d and %K = %d", @"type", UsbDevicePipeTypeBulk, @"direction", UsbDevicePipeDirectionIn];
		NSArray<UsbDevicePipe *> *bulkins = [pipeList filteredArrayUsingPredicate:blukinPredicate];
		if (bulkins.count < 1) {
			return 1;
		}
		UsbDevicePipe *bulkin = bulkins[0];
		
		{
			uint8 data[8] = { 0 };
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBIn, kUSBVendor, kUSBDevice),
				.bRequest		= 0xc0,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 8,
				.pData			= data,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}

		if (![bulkin clear]) {
			return 1;
		}
		
		{
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xc5,
				.wValue			= 0,
				.wIndex			= 4,
				.wLength		= 0,
				.pData			= nil,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}
		uint8 requestC6 = 0;
		while (requestC6 != 0x04) {
			uint8 data[1] = { 0 };
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBIn, kUSBVendor, kUSBDevice),
				.bRequest		= 0xc6,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 1,
				.pData			= data,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
			requestC6 = data[0];
		}
		{
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xc9,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 0,
				.pData			= nil,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}
		{
			uint8 data[1] = { 0x25 };
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xd2,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 1,
				.pData			= data,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}
		{
			uint8 data[1] = { 0x00 };
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xd2,
				.wValue			= 0,
				.wIndex			= 1,
				.wLength		= 1,
				.pData			= data,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}
		{
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xd0,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 0,
				.pData			= nil,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}

		signal(SIGINT, sig_handler);
		printf("start to capture.\n");
		while (readingPackets) {
			int length = (int)bulkin.maxPacketSize;
			uint8 buffer[length];
			int readLength = (int)[bulkin read:buffer length:length];
			if (readLength < 0) {
				break;
			}
			dump_packet(buffer, readLength);
		}
		printf("finish to capture.\n");
		
		{
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xd1,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 0,
				.pData			= nil,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}
		{
			IOUSBDevRequest request = {
				.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
				.bRequest		= 0xc5,
				.wValue			= 0,
				.wIndex			= 0,
				.wLength		= 0,
				.pData			= nil,
				.wLenDone		= 0,
			};
			if (![control controlRequest:&request]) {
				return 1;
			}
		}

		[interface close];
		[device close];
		[manager close];
		
	}
    return 0;
}

void sig_handler(int signo) {
	readingPackets = NO;
}

struct packet_header {
	uint8  unknown0;
	uint8  unknown1;
	uint8  information;
	uint16 number;
	uint64 timestamp;
	uint8  length;
} __attribute__((packed));

struct packet_crc {
	uint8 crc0;
	uint8 crc1;
	uint8 crc2;
} __attribute__((packed));

struct packet_footer {
	struct packet_crc crc;
	uint8 rf_rssi;
	uint8 rf_crc;
} __attribute__((packed));


// Hmm..., I don't know how to parse this buffer.
void dump_packet(uint8 *buffer, int length) {
	
	struct packet_header *header = (struct packet_header *)buffer;
	printf("unknown0=%03d: ", header->unknown0);
	printf("unknown1=%03d: ", header->unknown1);
	printf("information=%03d: ", header->information);
	printf("number=%05d: ", header->number);
	printf("timestamp=%020llu: ", header->timestamp);
	printf("length=%03d: ", header->length);
	buffer += sizeof(struct packet_header);

	struct packet_footer *footer = (struct packet_footer *)(buffer + header->length);
	long crc = ((long)footer->crc.crc2) << 16 | ((long)footer->crc.crc1) << 8 | (long)footer->crc.crc0;
	printf("crc=%08ld: ", crc);
	printf("rf_rssi=%03d: ", footer->rf_rssi);
	printf("rf_crc=%03d: ", footer->rf_crc);
	buffer += sizeof(struct packet_footer);
	
	// Perhaps, This part includes BLE packet.
	printf("data=\"");
	for (int index = 0; index < header->length; index++) {
#if 0
		uint8 ch = *buffer;
		if (isalnum(ch)) {
			printf("%c", ch);
		} else {
			printf(".");
		}
#else
		printf("%02X", *buffer);
		if (index < (header->length - 1)) {
			printf(",");
		}
#endif
		buffer++;
	}
	printf("\" ");
	
	printf("\n");
}
