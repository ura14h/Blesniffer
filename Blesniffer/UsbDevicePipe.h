//
//  UsbDevicePipe.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/04.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/usb/USB.h>

typedef NS_ENUM(NSUInteger, UsbDevicePipeType) {
	UsbDevicePipeTypeControl,
	UsbDevicePipeTypeInterrupt,
	UsbDevicePipeTypeBulk,
	UsbDevicePipeTypeIsochronous,
	UsbDevicePipeTypeAny,
	UsbDevicePipeTypeUnknown,
};

typedef NS_ENUM(NSUInteger, UsbDevicePipeDirection) {
	UsbDevicePipeDirectionIn,
	UsbDevicePipeDirectionOut,
	UsbDevicePipeDirectionUnknown,
};


@interface UsbDevicePipe : NSObject

@property (assign) UsbDevicePipeType type;
@property (assign) UsbDevicePipeDirection direction;
@property (assign) NSInteger maxPacketSize;

- (BOOL)clear;
- (BOOL)controlRequest:(IOUSBDevRequest *)request;
- (NSInteger)read:(void *)buffer length:(NSInteger)length;
- (NSInteger)write:(void *)buffer length:(NSInteger)length;

@end
