//
//  OpenCV.h
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/25/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//

#ifndef OpenCV_h
#define OpenCV_h

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, ConversionCode) {
    BGR2GRAY = 6
};

@interface OpenCV : NSObject

@property (nonatomic, nonnull) NSImage *image;
@property bool questionMarkPresent;

- (nonnull instancetype)initWithImage:(nonnull NSImage *)image;
- (void)convertColorSpace:(ConversionCode)code;
- (void)cropTo:(CGRect) rect;
- (void)threshold:(double)val;

- (void)prepareForOcr;
    
@end

#endif /* OpenCV_h */
