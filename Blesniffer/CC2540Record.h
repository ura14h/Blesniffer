//
//  CC2540Record.h
//  Blesniffer
//
//  Created by Hiroki Ishiura on 2016/11/10.
//  Copyright © 2016年 Hiroki Ishiura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CC2540Record : NSObject

@property (assign) NSTimeInterval timestamp;
@property (strong) NSData *packet;

@end
