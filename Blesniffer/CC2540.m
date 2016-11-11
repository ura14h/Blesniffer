//
//  CC2540.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/10.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import "UsbDevice.h"
#import "UsbDeviceInterface.h"
#import "UsbDevicePipe.h"
#import "CC2540.h"
#import "CC2540Record.h"


@interface CC2540 ()

@property (strong) UsbDevice *device;
@property (strong) UsbDeviceInterface *interface;
@property (strong) UsbDevicePipe *control;
@property (strong) UsbDevicePipe *bulk;

@end

@implementation CC2540

+ (NSInteger)vendorId {
	return 0x0451;
}

+ (NSInteger)productId {
	return 0x16B3;
}

- (CC2540 *)initWithUsbDevice: (UsbDevice *)device {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_device = device;
	_interface = nil;
	_control = nil;
	_bulk = nil;
	
	return self;
}

- (void)dealloc {
	[self close];
	
	_device = nil;
}

- (BOOL)open {

	if (![self.device open]) {
		return NO;
	}
	
	NSInteger configuration = [self.device getConfiguration];
	if (configuration < 0) {
		return NO;
	}
	if (![self.device setConfiguration:configuration]) {
		return NO;
	}
	NSArray<UsbDeviceInterface *> *interfaceList = [self.device interfaceList];
	if (interfaceList.count < 1) {
		return NO;
	}
	UsbDeviceInterface *interface = interfaceList[0];
	if (![interface open]) {
		return NO;
	}
	NSArray<UsbDevicePipe *> *pipeList = [interface pipeList];
	if (pipeList.count < 1) {
		return NO;
	}
	NSPredicate *controlPredicate = [NSPredicate predicateWithFormat:@"%K = %d", @"type", UsbDevicePipeTypeControl];
	NSArray<UsbDevicePipe *> *controls = [pipeList filteredArrayUsingPredicate:controlPredicate];
	if (controls.count < 1) {
		return NO;
	}
	UsbDevicePipe *control = controls[0];
	NSPredicate *blukPredicate = [NSPredicate predicateWithFormat:@"%K = %d and %K = %d", @"type", UsbDevicePipeTypeBulk, @"direction", UsbDevicePipeDirectionIn];
	NSArray<UsbDevicePipe *> *bulks = [pipeList filteredArrayUsingPredicate:blukPredicate];
	if (bulks.count < 1) {
		return NO;
	}
	UsbDevicePipe *bulk = bulks[0];
	
	self.interface = interface;
	self.control = control;
	self.bulk = bulk;
	
	return YES;
}

- (BOOL)close {
	[self stop];

	self.control = nil;
	self.bulk = nil;
	
	if (self.interface) {
		[self.interface close];
	}

	self.interface = nil;
	
	if (self.device) {
		[self.device close];
	}
	
	return YES;
}

- (BOOL)start: (NSInteger)channel {
	if (channel == 0) {
		channel = 37;
	}

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
		if (![self.control controlRequest:&request]) {
			return NO;
		}
	}
	if (![self.bulk clear]) {
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
		if (![self.control controlRequest:&request]) {
			return NO;
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
		if (![self.control controlRequest:&request]) {
			return NO;
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
		if (![self.control controlRequest:&request]) {
			return NO;
		}
	}
	{
		uint8 data[1] = { (uint8)channel };
		IOUSBDevRequest request = {
			.bmRequestType	= USBmakebmRequestType(kUSBOut, kUSBVendor, kUSBDevice),
			.bRequest		= 0xd2,
			.wValue			= 0,
			.wIndex			= 0,
			.wLength		= 1,
			.pData			= data,
			.wLenDone		= 0,
		};
		if (![self.control controlRequest:&request]) {
			return NO;
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
		if (![self.control controlRequest:&request]) {
			return NO;
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
		if (![self.control controlRequest:&request]) {
			return NO;
		}
	}

	return YES;
}

- (BOOL)stop {
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
		if (![self.control controlRequest:&request]) {
			return NO;
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
		if (![self.control controlRequest:&request]) {
			return NO;
		}
	}
	
	return YES;
}

- (CC2540Record *)read {
	NSInteger bufferLength = (NSInteger)(self.bulk.maxPacketSize);
	uint8 buffer[bufferLength];
	NSInteger readLength = (NSInteger)[self.bulk read:buffer length:bufferLength];
	if (readLength < 0) {
		return nil;
	}
	
	CC2540Record *record = [CC2540Record cc2540recordWithBytes:buffer length:readLength];
	return record;
}

@end
