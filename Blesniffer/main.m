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
#import "CC2540.h"

static volatile BOOL readingPackets = YES;
static void sig_handler(int signo);

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		
		UsbDeviceManager *manager = [UsbDeviceManager new];
		if (![manager open]) {
			return 1;
		}
		
		NSInteger vendorId = [CC2540 vendorId];
		NSInteger productId = [CC2540 productId];
		NSArray<UsbDevice *> *deviceList = [manager deviceListWithVendorId:vendorId productId:productId];
		if (deviceList.count < 1) {
			return 1;
		}
		UsbDevice *device = deviceList[0];
		CC2540 *cc2540 = [[CC2540 alloc] initWithUsbDevice:device];
		if (![cc2540 open]) {
			return 1;
		}
		if (![cc2540 start]) {
			return 1;
		}

		signal(SIGINT, sig_handler);
		printf("start to capture.\n");
		NSUInteger number = 0;
		while (readingPackets) {
			@autoreleasepool {
				CC2540Record *record = [cc2540 read];
				if (record) {
					NSLog(@"%ld: %@", number, record);
				}
			}
			number++;
		}
		printf("finish to capture.\n");

		[cc2540 stop];
		[cc2540 close];
		[manager close];
		
	}
    return 0;
}

void sig_handler(int signo) {
	readingPackets = NO;
}
