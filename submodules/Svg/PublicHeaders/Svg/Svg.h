#ifndef Lottie_h
#define Lottie_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NSData * _Nullable prepareSvgImage(NSData * _Nonnull data, bool pattern);
UIImage * _Nullable renderPreparedImage(NSData * _Nonnull data, CGSize size, UIColor * _Nonnull backgroundColor, CGFloat scale, bool fit);

UIImage * _Nullable drawSvgImage(NSData * _Nonnull data, CGSize size, UIColor * _Nullable backgroundColor, UIColor * _Nullable foregroundColor, CGFloat scale, bool opaque);

#endif /* Lottie_h */
