//
//  OpenCVCashShow.h
//  HQ Solver
//
//  Created by Konstantin Klitenik on 1/20/18.
//  Copyright © 2018 Konstantin Klitenik. All rights reserved.
//

#ifndef OpenCVCashShow_h
#define OpenCVCashShow_h

#import <Cocoa/Cocoa.h>
#import "OpenCVCommon.h"

@interface OpenCVCashShow : NSObject <OpenCV>

@property (nonatomic, nonnull) NSString *gameTitle;
@property (nonatomic, nonnull) NSArray *images;
@property bool questionMarkPresent;
@property int correctAnswer;

//- (instancetype _Nonnull)initWithImage:(nonnull NSImage *)image device:(int)device;
//- (void)convertColorSpace:(ConversionCode)code;
//- (void)cropTo:(CGRect) rect;
//- (void)threshold:(double)val;
//
//- (void)prepareForOcr;

@end

#endif /* OpenCVCashShow_h */
