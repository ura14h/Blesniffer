//
//  main.m
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <unistd.h>
#import "UsbDeviceManager.h"
#import "UsbDevice.h"
#import "CC2540.h"
#import "CC2540Record.h"
#import "PcapDumpFile.h"


static void showUsageAndExitApplication();
static void signalHandler(int signal);
static volatile BOOL readingCC2540CapturedRecord = YES;

int main(int argc, const char * argv[]) {

	int channel = 0;
	{
		int optch;
		extern char *optarg;
		extern int optind;
		extern int opterr;
		while ((optch = getopt(argc, (char **)argv, "c:")) != -1) {
			switch (optch) {
				case 'c':
					channel = atoi(optarg);
					break;
				default:
					showUsageAndExitApplication();
					break;
			}
		}
	}
	argc -= optind;
	argv += optind;
	if (argc < 1) {
		showUsageAndExitApplication();
	}
	const char *output = argv[0];
	
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
		
		NSString *filename = [NSString stringWithCString:output encoding:NSUTF8StringEncoding];
		PcapDumpFile *file = [[PcapDumpFile alloc] init];
		if (![file open:filename]) {
			return 1;
		}
		if (![cc2540 start: channel]) {
			return 1;
		}

		signal(SIGINT, signalHandler);
		NSUInteger number = 0;
		while (readingCC2540CapturedRecord) {
			@autoreleasepool {
				CC2540Record *record = [cc2540 read];
				if (!record) {
					break;
				}
				if ([record isKindOfClass:[CC2540CapturedRecord class]]) {
					[file write:(CC2540CapturedRecord *)record];
				}
			}
			number++;
		}

		[cc2540 stop];
		[file close];
		[cc2540 close];
		[manager close];
		
	}
	
    exit(0);
}

void showUsageAndExitApplication() {
	fprintf(stderr, "This is a Bluetooth LE sniffer for CC2540 USB dongle and macOS.\n");
	fprintf(stderr, "  Usage: Blesniffer [-c channel] output\n");
	fprintf(stderr, "    Control-C makes exiting packet capturing.\n");
	fprintf(stderr, "  Copyright (c) 2016 Hiroki Ishiura\n");
	exit(1);
}

void signalHandler(int signal) {
	readingCC2540CapturedRecord = NO;
}
