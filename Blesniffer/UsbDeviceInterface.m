//
//  UsbDeviceInterface.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import "UsbDeviceManager.h"
#import "UsbDevice.h"
#import "UsbDeviceInterface.h"
#import "UsbDevicePipe.h"

@interface UsbDevicePipe (UsbDeviceInterface)

- (instancetype)initWithInterface:(UsbDeviceInterface *)interface index:(NSUInteger)index;

@end

@interface UsbDeviceInterface ()

@property (strong) UsbDevice *device;
@property (assign) io_service_t service;
@property (assign) IOUSBInterfaceInterface245 **interfaceInterface;

@end

@implementation UsbDeviceInterface

- (instancetype)initWithDevice:(UsbDevice *)device service:(io_service_t)service {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_device = device;
	_service = service;
	IOObjectRetain(_service);
	
	_interfaceInterface = nil;

	return self;
}

- (void)dealloc {
	[self close];
	
	if (self.service) {
		IOObjectRelease(self.service);
	}
	self.service = 0;
	self.device = nil;
}

- (BOOL)open {
	if (self.interfaceInterface) {
		return YES;
	}

	IOReturn result;
	
	IOCFPlugInInterface **pluginInterface = nil;
	SInt32 score = 0;
	result = IOCreatePlugInInterfaceForService(self.service, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
	if (result != KERN_SUCCESS || pluginInterface == nil) {
		return NO;
	}

	IOUSBInterfaceInterface245 **interfaceInterface = nil;
	result = (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID245), (LPVOID)&interfaceInterface);
	IODestroyPlugInInterface(pluginInterface);
	if (result != KERN_SUCCESS || interfaceInterface == nil) {
		return NO;
	}
	
	result = (*interfaceInterface)->USBInterfaceOpen(interfaceInterface);
	if (result != KERN_SUCCESS) {
		(*interfaceInterface)->Release(interfaceInterface);
		return NO;
	}
	
	self.interfaceInterface = interfaceInterface;
	return YES;
}

- (BOOL)close {
	if (self.interfaceInterface) {
		(*(self.interfaceInterface))->USBInterfaceClose(self.interfaceInterface);
		(*(self.interfaceInterface))->Release(self.interfaceInterface);
	}

	self.interfaceInterface = nil;
	return YES;
}

- (NSArray<UsbDevicePipe *> *)pipeList {
	if (!self.interfaceInterface) {
		return nil;
	}
	
	IOUSBInterfaceInterface245 **interfaceInterface = self.interfaceInterface;
	UInt8 pipes = 0;
	IOReturn result = (*interfaceInterface)->GetNumEndpoints(interfaceInterface, &pipes);
	if (result != KERN_SUCCESS) {
		return NO;
	}
	
	NSMutableArray<UsbDevicePipe *> *pipeList = [NSMutableArray array];
	for (UInt8 index = 0; index <= pipes; index++) {
		UsbDevicePipe *pipe = [[UsbDevicePipe alloc] initWithInterface:self index:(NSUInteger)index];
		if (pipe) {
			[pipeList addObject:pipe];
		}
	}
	
	return pipeList;
}

@end
