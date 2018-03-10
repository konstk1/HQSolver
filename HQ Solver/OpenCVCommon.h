//
//  OpenCVCommon.h
//  HQ Solver
//
//  Created by Konstantin Klitenik on 2/22/18.
//  Copyright © 2018 Konstantin Klitenik. All rights reserved.
//

#ifndef OpenCVCommon_h
#define OpenCVCommon_h

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, ConversionCode) {
    BGR2GRAY = 6
};

@protocol OpenCV

@property (nonatomic, nonnull) NSString *gameTitle;
@property (nonatomic, nonnull) NSArray *images;
@property bool questionMarkPresent;
@property int correctAnswer;


- (instancetype _Nonnull)initWithImage:(nonnull NSImage *)image device:(int)device;
- (void)convertColorSpace:(ConversionCode)code;
- (void)cropTo:(CGRect) rect;
- (void)threshold:(double)val;
    
- (void)prepareForOcr;
@end

#endif /* OpenCVCommon_h */
