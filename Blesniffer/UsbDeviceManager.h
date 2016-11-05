//
//  UsbDeviceManager.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UsbDevice;


@interface UsbDeviceManager : NSObject

- (BOOL)open;
- (BOOL)close;
- (NSArray<UsbDevice *> *)deviceListWithVendorId: (NSInteger)vendorId productId:(NSInteger)producutId;

@end
