//
//  PcapDumpFile.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/11.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CC2540CapturedRecord;


@interface PcapDumpFile : NSObject

- (BOOL)open:(NSString *)path;
- (BOOL)write: (CC2540CapturedRecord *)record;
- (BOOL)close;

@end
