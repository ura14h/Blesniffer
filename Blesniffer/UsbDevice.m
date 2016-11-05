//
//  UsbDevice.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <mach/mach.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import "UsbDeviceManager.h"
#import "UsbDeviceInterface.h"
#import "UsbDevice.h"

@interface UsbDeviceInterface (UsbDevice)

- (instancetype)initWithDevice:(UsbDevice *)device service:(io_service_t)service;

@end

@interface UsbDevice ()

@property (strong) UsbDeviceManager *manager;
@property (assign) io_service_t service;
@property (assign) IOUSBDeviceInterface245 **deviceInterface;

@end

@implementation UsbDevice

- (instancetype)initWithManager:(UsbDeviceManager *)manager service:(io_service_t)service {
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_manager = manager;
	_service = service;
	IOObjectRetain(_service);

	_name = nil;
	{
		io_name_t name;
		kern_return_t result = IORegistryEntryGetName(_service, name);
		if (result == KERN_SUCCESS) {
			_name = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
		}
	}
	_path = nil;
	{
		io_string_t path;
		kern_return_t result = IORegistryEntryGetPath(_service, kIOUSBPlane, path);
		if (result == KERN_SUCCESS) {
			_path = [NSString stringWithCString:path encoding:NSASCIIStringEncoding];
		}
	}
	_deviceInterface = nil;
	
	return self;
}

- (void)dealloc {
	[self close];

	self.name = nil;
	self.path = nil;
	
	if (self.service) {
		IOObjectRelease(self.service);
	}
	self.service = 0;
	self.manager = nil;
}

- (BOOL)open {
	if (self.deviceInterface) {
		return YES;
	}

	IOReturn result;
	
	IOCFPlugInInterface **pluginInterface = nil;
	SInt32 score = 0;
	result = IOCreatePlugInInterfaceForService(self.service, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
	if (result != KERN_SUCCESS || pluginInterface == nil) {
		return NO;
	}

	IOUSBDeviceInterface245 **deviceInterface = nil;
	result = (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID245), (LPVOID)&deviceInterface);
	IODestroyPlugInInterface(pluginInterface);
	if (result != KERN_SUCCESS || deviceInterface == nil) {
		return NO;
	}

	result = (*deviceInterface)->USBDeviceOpen(deviceInterface);
	if (result != KERN_SUCCESS) {
		(*deviceInterface)->Release(deviceInterface);
		return NO;
	}
	
	self.deviceInterface = deviceInterface;
	return YES;
}

- (BOOL)close {
	if (self.deviceInterface) {
		(*(self.deviceInterface))->USBDeviceClose(self.deviceInterface);
		(*(self.deviceInterface))->Release(self.deviceInterface);
	}
	
	self.deviceInterface = nil;
	return YES;
}

- (NSInteger)numberOfConfigurations {
	if (!self.deviceInterface) {
		return NO;
	}
	IOUSBDeviceInterface245 **deviceInterface = self.deviceInterface;
	IOReturn result;
	
	UInt8 configurations = 0;
	
	result = (*deviceInterface)->GetNumberOfConfigurations(deviceInterface, &configurations);
	if (result != KERN_SUCCESS || configurations == 0) {
		return -1;
	}
	IOUSBConfigurationDescriptorPtr	configurationDescriptor = nil;
	result = (*deviceInterface)->GetConfigurationDescriptorPtr(deviceInterface, 0, &configurationDescriptor);
	if (result != KERN_SUCCESS || configurationDescriptor == nil) {
		return -1;
	}
	
	return configurations;
}

- (NSInteger)getConfiguration {
	NSInteger configurations = [self numberOfConfigurations];
	if (configurations < 1) {
		return NO;
	}

	UInt8 configuration = 0;
	
	IOUSBDeviceInterface245 **deviceInterface = self.deviceInterface;
	IOReturn result = (*deviceInterface)->GetConfiguration(deviceInterface, &configuration);
	if (result != KERN_SUCCESS) {
		return NO;
	}

	return (NSInteger)configuration;
}

- (BOOL)setConfiguration:(NSInteger)value {
	NSInteger configurations = [self numberOfConfigurations];
	if (configurations < 1) {
		return NO;
	}
	
	IOUSBDeviceInterface245 **deviceInterface = self.deviceInterface;
	IOReturn result = (*deviceInterface)->SetConfiguration(deviceInterface, (UInt8)value);
	if (result != KERN_SUCCESS) {
		return NO;
	}
	
	return YES;
}

- (NSArray<UsbDeviceInterface *> *)interfaceList {
	if (!self.deviceInterface) {
		return nil;
	}

	IOUSBDeviceInterface245 **deviceInterface = self.deviceInterface;
	IOUSBFindInterfaceRequest interfaceRequest = {
		.bInterfaceClass	= kIOUSBFindInterfaceDontCare,
		.bInterfaceSubClass	= kIOUSBFindInterfaceDontCare,
		.bInterfaceProtocol	= kIOUSBFindInterfaceDontCare,
		.bAlternateSetting	= kIOUSBFindInterfaceDontCare,
	};
	io_iterator_t iterator = 0;
	IOReturn result = (*deviceInterface)->CreateInterfaceIterator(deviceInterface, &interfaceRequest, &iterator);
	if (result != KERN_SUCCESS) {
		return nil;
	}
	
	NSMutableArray<UsbDeviceInterface *> *interfaceList = [NSMutableArray array];
	io_service_t service = 0;
	while ((service = IOIteratorNext(iterator)) != 0) {
		UsbDeviceInterface *interface = [[UsbDeviceInterface alloc] initWithDevice:self service:service];
		if (interface) {
			[interfaceList addObject:interface];
		}
		IOObjectRelease(service);
	}
	IOObjectRelease(iterator);
	
	return interfaceList;
}

@end
