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

static const char *applicationName = nil;
static volatile BOOL readingCC2540CapturedRecord = YES;

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		NSString *applicationPath = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
		NSString *applicationFile = [applicationPath lastPathComponent];
		applicationName = [applicationFile UTF8String];
		
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
						if (channel < 0 || channel > 39) {
							showUsageAndExitApplication();
						}
						break;
					default:
						showUsageAndExitApplication();
						break;
				}
			}
			argc -= optind;
			argv += optind;
		}

		if (argc < 1) {
			showUsageAndExitApplication();
		}
		NSString *output = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
		if (![[output lowercaseString] hasSuffix:@".pcap"]) {
			output = [NSString stringWithFormat:@"%@.pcap", output];
		}
		const char *outputFile = [output UTF8String];

		
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
		
		NSString *filename = [NSString stringWithCString:outputFile encoding:NSUTF8StringEncoding];
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
	fprintf(stderr, "Usage: %s [-c channel] output.pcap\n", applicationName);
	fprintf(stderr, "  (!) control-c makes exiting packet capturing.\n");
	exit(1);
}

void signalHandler(int signal) {
	readingCC2540CapturedRecord = NO;
}
