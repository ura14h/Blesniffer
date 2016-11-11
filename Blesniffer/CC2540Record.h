//
//  CC2540Record.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/11.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CC2540Record : NSObject

@property (assign) NSInteger type;
@property (assign) NSInteger length;

+ (instancetype)cc2540recordWithBytes:(void *)bytes length:(NSInteger)length;

@end


@interface CC2540CapturedRecord : CC2540Record

@property (assign) NSInteger timestamp;
@property (strong) NSData *packet;

@end


@interface CC2540UnknownRecord : CC2540Record

// No extended implementations.

@end
