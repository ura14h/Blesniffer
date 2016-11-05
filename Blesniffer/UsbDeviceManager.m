//
//  UsbDeviceManager.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <mach/mach.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import "UsbDeviceManager.h"
#import "UsbDevice.h"

@interface UsbDevice (UsbDeviceManager)

- (instancetype)initWithManager:(UsbDeviceManager *)manager service:(io_service_t)service;

@end


@interface UsbDeviceManager ()

@property (assign) mach_port_t masterPort;

@end

@implementation UsbDeviceManager

- (instancetype)init {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_masterPort = 0;
	
	return self;
}

- (void)dealloc {
	[self close];
}

- (BOOL)open {
	if (self.masterPort != 0) {
		return YES;
	}
	
	kern_return_t result = IOMasterPort(MACH_PORT_NULL, &_masterPort);
	if (result != KERN_SUCCESS) {
		return NO;
	}
	
	return YES;
}

- (BOOL)close {
	if (self.masterPort == 0) {
		return YES;
	}
	
	kern_return_t result = mach_port_deallocate(mach_host_self(), self.masterPort);
	if (result != KERN_SUCCESS) {
		return NO;
	}
	self.masterPort = 0;
	
	return YES;
}

- (NSArray<UsbDevice *> *)deviceListWithVendorId: (NSInteger)vendorId productId:(NSInteger)producutId {
	if (self.masterPort == 0) {
		return nil;
	}

	NSMutableDictionary *matching = (__bridge NSMutableDictionary *)IOServiceMatching(kIOUSBDeviceClassName);
	matching[@kUSBVendorID] = @(vendorId);
	matching[@kUSBProductID] = @(producutId);
	
	io_iterator_t iterator = 0;
	kern_return_t result = IOServiceGetMatchingServices(self.masterPort, (__bridge CFDictionaryRef)matching, &iterator);
	if (result != KERN_SUCCESS) {
		return nil;
	}
	
	NSMutableArray<UsbDevice *> *deviceList = [NSMutableArray array];
	io_service_t service = 0;
	while ((service = IOIteratorNext(iterator)) != 0) {
		UsbDevice *device = [[UsbDevice alloc] initWithManager:self service:service];
		if (device) {
			[deviceList addObject:device];
		}
		IOObjectRelease(service);
	}
	IOObjectRelease(iterator);
	
	return deviceList;
}

@end
