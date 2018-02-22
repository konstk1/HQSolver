//
//  OpenCVCashShow.h
//  HQ Solver
//
//  Created by Konstantin Klitenik on 1/20/18.
//  Copyright © 2018 Konstantin Klitenik. All rights reserved.
//

#ifndef OpenCVQB_h
#define OpenCVQB_h

#import <Cocoa/Cocoa.h>
#import "OpenCVCommon.h"

@interface OpenCVQB : NSObject

@property (nonatomic, nonnull) NSArray *images;

@property bool questionMarkPresent;
@property int correctAnswer;

- (instancetype _Nonnull)initWithImage:(nonnull NSImage *)image device:(int)device;
- (void)convertColorSpace:(ConversionCode)code;
- (void)cropTo:(CGRect) rect;
- (void)threshold:(double)val;

- (void)prepareForOcr;

@end

#endif /* OpenCVQB_h */
