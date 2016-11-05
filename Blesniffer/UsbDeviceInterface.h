//
//  UsbDeviceInterface.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UsbDevicePipe;


@interface UsbDeviceInterface : NSObject

- (BOOL)open;
- (BOOL)close;
- (NSArray<UsbDevicePipe *> *)pipeList;

@end
