#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define FFMPEG_AVSEEK_SIZE 0x10000

extern int FFMPEG_CONSTANT_AVERROR_EOF;

@interface FFMpegAVIOContext : NSObject

- (instancetype _Nullable)initWithBufferSize:(int32_t)bufferSize opaqueContext:(void * const _Nullable)opaqueContext readPacket:(int (* _Nullable)(void * _Nullable opaque, uint8_t * _Nullable buf, int buf_size))readPacket writePacket:(int (* _Nullable)(void * _Nullable opaque, uint8_t const * _Nullable buf, int buf_size))writePacket seek:(int64_t (*)(void * _Nullable opaque, int64_t offset, int whence))seek isSeekable:(bool)isSeekable;

- (void *)impl;

@end

NS_ASSUME_NONNULL_END
