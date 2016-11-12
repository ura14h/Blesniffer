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


static volatile BOOL readingCC2540CapturedRecord = YES;

static void signalHandler(int signal) {
	readingCC2540CapturedRecord = NO;
}

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		const char *argv0 = argv[0];

		int channelNumber = 0;
		int deviceNumber = 0;
		{
			int optch;
			extern char *optarg;
			extern int optind;
			extern int opterr;
			while ((optch = getopt(argc, (char **)argv, "c:d:")) != -1) {
				switch (optch) {
					case 'c':
						channelNumber = atoi(optarg);
						if (channelNumber < 0 || channelNumber > 39) {
							fprintf(stderr, "%s: Channel number is out of range.\n", argv0);
							exit(1);
						}
						break;
					case 'd':
						deviceNumber = atoi(optarg);
						break;
					default:
						exit(1);
						break;
				}
			}
			argc -= optind;
			argv += optind;
		}

		if (argc < 1) {
			NSString *applicationPath = [NSString stringWithCString:argv0 encoding:NSUTF8StringEncoding];
			NSString *applicationFile = [applicationPath lastPathComponent];
			const char *applicationName = [applicationFile UTF8String];
			
			fprintf(stderr, "Usage: %s [-c channel#] [-d device#] output.pcap\n", applicationName);
			fprintf(stderr, "  (!) control-c makes exiting packet capturing.\n");
			exit(1);
		}
		NSString *output = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
		if (![[output lowercaseString] hasSuffix:@".pcap"]) {
			output = [NSString stringWithFormat:@"%@.pcap", output];
		}
		const char *outputFile = [output UTF8String];

		
		UsbDeviceManager *manager = [UsbDeviceManager new];
		if (![manager open]) {
			fprintf(stderr, "%s: Could not open USB device manager.\n", argv0);
			exit(1);
		}
		
		NSInteger vendorId = [CC2540 vendorId];
		NSInteger productId = [CC2540 productId];
		NSArray<UsbDevice *> *deviceList = [manager deviceListWithVendorId:vendorId productId:productId];
		if (deviceList.count < 1) {
			fprintf(stderr, "%s: No CC2540 USB dongles.\n", argv0);
			exit(1);
		}
		
		if (deviceNumber < 0 || deviceNumber >= deviceList.count) {
			fprintf(stderr, "%s: Device number is out of range.\n", argv0);
			exit(1);
		}
	
		UsbDevice *device = deviceList[0];
		CC2540 *cc2540 = [[CC2540 alloc] initWithUsbDevice:device];
		if (![cc2540 open]) {
			fprintf(stderr, "%s: Could not open CC2540 USB dongle.\n", argv0);
			exit(1);
		}
		
		NSString *filename = [NSString stringWithCString:outputFile encoding:NSUTF8StringEncoding];
		PcapDumpFile *file = [[PcapDumpFile alloc] init];
		if (![file open:filename]) {
			fprintf(stderr, "%s: Could not open output.\n", argv0);
			exit(1);
		}
		if (![cc2540 start: channelNumber]) {
			fprintf(stderr, "%s: Could not start capturing packet.\n", argv0);
			exit(1);
		}

		signal(SIGINT, signalHandler);
		NSUInteger number = 0;
		while (readingCC2540CapturedRecord) {
			@autoreleasepool {
				CC2540Record *record = [cc2540 read];
				if (!record) {
					fprintf(stderr, "%s: Could not read data.\n", argv0);
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
