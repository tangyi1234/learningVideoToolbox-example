//
//  TYToGetData.m
//  TYVideoToolbox_demo
//
//  Created by 汤义 on 2018/11/14.
//  Copyright © 2018年 汤义. All rights reserved.
//

//#import "TYToGetData.h"
#include "TYToGetData.h"
const uint8_t KStartCode[4] = {0, 0, 0, 1};
@implementation TYVideoPacket
- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}
@end

@interface TYToGetData(){
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
}
@property NSString *fileName;
@property NSInputStream *fileStream;
@end
@implementation TYToGetData
-(BOOL)open:(NSString *)fileName
{
    _bufferSize = 0;
    //    _bufferCap = 512 * 1024;
    //    _bufferCap = 1080 * 1920;
    _bufferCap = 720 * 1280;
    _buffer = malloc(_bufferCap);
    self.fileName = fileName;
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:fileName];
    [self.fileStream open];
    
    return YES;
}

-(TYVideoPacket*)nextPacket
{
    if(_bufferSize < _bufferCap && self.fileStream.hasBytesAvailable) {
        NSInteger readBytes = [self.fileStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        NSLog(@"这一段的数据:%ld _buffer:%s _bufferSize:%ld _bufferCap:%ld",(long)readBytes,_buffer,(long)_bufferSize ,(long)_bufferCap);
        _bufferSize += readBytes;
    }
    
    if(memcmp(_buffer, KStartCode, 4) != 0) {
        return nil;
    }
    
    if(_bufferSize >= 5) {
        uint8_t *bufferBegin = _buffer + 4;
        uint8_t *bufferEnd = _buffer + _bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - _buffer - 3;
                    TYVideoPacket *vp = [[TYVideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _buffer, packetSize);
                    
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    
    return nil;
}

-(void)close
{
    free(_buffer);
    [self.fileStream close];
}

@end
