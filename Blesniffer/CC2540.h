//
//  CC2540.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/10.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UsbDevice;
@class CC2540Record;

@interface CC2540 : NSObject

@property (assign) NSInteger channel;

+ (NSInteger)vendorId;
+ (NSInteger)productId;

- (CC2540 *)initWithUsbDevice: (UsbDevice *)device;
- (BOOL)open;
- (BOOL)close;
- (BOOL)start;
- (BOOL)stop;
- (CC2540Record *)read;

@end
