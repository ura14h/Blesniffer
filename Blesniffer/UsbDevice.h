//
//  UsbDevice.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/03.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UsbDeviceInterface;


@interface UsbDevice : NSObject

@property (strong) NSString *name;
@property (strong) NSString *path;

- (BOOL)open;
- (BOOL)close;
- (NSInteger)getConfiguration;
- (BOOL)setConfiguration:(NSInteger)value;
- (NSArray<UsbDeviceInterface *> *)interfaceList;

@end
