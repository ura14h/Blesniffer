//
//  UsbDevicePipe.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/04.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import "UsbDeviceManager.h"
#import "UsbDevice.h"
#import "UsbDeviceInterface.h"
#import "UsbDevicePipe.h"

@interface UsbDeviceInterface (UsbDevicePipe)

@property (assign) IOUSBInterfaceInterface245 **interfaceInterface;

@end

@interface UsbDevicePipe ()

@property (assign) UsbDeviceInterface *interface;
@property (assign) NSUInteger index;

@end

@implementation UsbDevicePipe

- (instancetype)initWithInterface:(UsbDeviceInterface *)interface index:(NSUInteger)index {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_interface = interface;
	_index = index;

	IOUSBInterfaceInterface245 **interfaceInterface = interface.interfaceInterface;
	UInt8 direction = 0;
	UInt8 number = 0;
	UInt8 transferType = 0;
	UInt16 maxPacketSize = 0;
	UInt8 interval = 0;
	IOReturn result = (*interfaceInterface)->GetPipeProperties(interfaceInterface, _index, &direction, &number, &transferType, &maxPacketSize, &interval);
	if (result != KERN_SUCCESS) {
		return nil;
	}
	
	switch (direction) {
		case kUSBOut:
			_direction = UsbDevicePipeDirectionOut;
			break;
		case kUSBIn:
			_direction = UsbDevicePipeDirectionIn;
			break;
		default:
			_direction = UsbDevicePipeDirectionUnknown;
			break;
	}
	switch (transferType) {
		case kUSBControl:
			_type = UsbDevicePipeTypeControl;
			break;
		case kUSBIsoc:
			_type = UsbDevicePipeTypeIsochronous;
			break;
		case kUSBBulk:
			_type = UsbDevicePipeTypeBulk;
			break;
		case kUSBInterrupt:
			_type = UsbDevicePipeTypeInterrupt;
			break;
		case kUSBAnyType:
			_type = UsbDevicePipeTypeAny;
			break;
		default:
			_type = UsbDevicePipeTypeUnknown;
			break;
	}
	_maxPacketSize = (NSInteger)maxPacketSize;
	
	return self;
}

- (void)dealloc {
	self.interface = nil;
}

- (BOOL)clear {
	
	IOUSBInterfaceInterface245 **interfaceInterface = self.interface.interfaceInterface;
	IOReturn result = (*interfaceInterface)->ClearPipeStall(interfaceInterface, self.index);
	if (result != KERN_SUCCESS) {
		return NO;
	}
	
	return YES;
}

- (BOOL)controlRequest:(IOUSBDevRequest *)request {
	if (self.type != UsbDevicePipeTypeControl) {
		return NO;
	}

	IOUSBInterfaceInterface245 **interfaceInterface = self.interface.interfaceInterface;
	IOReturn result = (*interfaceInterface)->ControlRequest(interfaceInterface, self.index, request);
	if (result != KERN_SUCCESS) {
		return NO;
	}
	
	return YES;
}

- (NSInteger)read:(void *)buffer length:(NSInteger)length {
	if (self.type != UsbDevicePipeTypeBulk && self.type != UsbDevicePipeTypeInterrupt) {
		return -1;
	}
	if (self.direction != UsbDevicePipeDirectionIn) {
		return -1;
	}

	IOUSBInterfaceInterface245 **interfaceInterface = self.interface.interfaceInterface;
	UInt32 readLength = (UInt32)length;
	IOReturn result = (*interfaceInterface)->ReadPipe(interfaceInterface, self.index, buffer, &readLength);
	if (result != KERN_SUCCESS) {
		return -1;
	}
	
	return (NSInteger)readLength;
}

- (NSInteger)write:(void *)buffer length:(NSInteger)length {
	if (self.type != UsbDevicePipeTypeBulk && self.type != UsbDevicePipeTypeInterrupt) {
		return -1;
	}
	if (self.direction != UsbDevicePipeDirectionOut) {
		return -1;
	}

	IOUSBInterfaceInterface245 **interfaceInterface = self.interface.interfaceInterface;
	UInt32 writeLength = (UInt32)length;
	IOReturn result = (*interfaceInterface)->WritePipe(interfaceInterface, self.index, buffer, writeLength);
	if (result != KERN_SUCCESS) {
		return -1;
	}
	
	return (NSInteger)writeLength;
}

@end
