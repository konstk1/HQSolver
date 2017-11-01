//
//  OpenCV.m
//  HQ Solver
//
//  Created by Konstantin Klitenik on 10/25/17.
//  Copyright © 2017 Konstantin Klitenik. All rights reserved.
//
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
//#import <AppKit/AppKit.h>
#import "OpenCV.h"

static void NSImageToMat(NSImage *image, cv::Mat &mat);
static NSImage *MatToNSImage(cv::Mat &mat);

@interface OpenCV ()

@end

@implementation OpenCV

static cv::Mat _cvMat;

- (instancetype)initWithImage:(nonnull NSImage *)image {
    NSImageToMat(image, _cvMat);
    return self;
}

- (void)setImage:(nonnull NSImage *)image {
    NSImageToMat(image, _cvMat);
}

- (NSImage *)image {
    return MatToNSImage(_cvMat);
}

- (void)convertColorSpace:(ConversionCode)code {
    cv::cvtColor(_cvMat, _cvMat, code);
}

- (void)cropTo:(CGRect)rect {
    _cvMat = _cvMat(cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height));
}

- (void)threshold:(double)val {
    cv::threshold(_cvMat, _cvMat, val, 255, cv::THRESH_BINARY);
}

- (void)prepareForOcr {
    cv::Mat colorMat = _cvMat;
    cv::cvtColor(_cvMat, _cvMat, cv::COLOR_BGR2GRAY);
//    _cvMat = _cvMat(cv::Rect(380, 100, 220, 300));
    cv::threshold(_cvMat, _cvMat, 200, 255, cv::THRESH_BINARY);
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(_cvMat, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    printf("Found %lu contours\n", contours.size());
    cv::Scalar color = cv::Scalar(0, 255, 0);
    cv::drawContours(colorMat, contours, -1, color, 2, 8, hierarchy);
    _cvMat = colorMat;
    
    for(auto const &cnt: contours) {
        auto area = cv::contourArea(cnt);
        printf("Counter area = %0.2f\n", area);
    }
//    cv::fastNlMeansDenoising(_cvMat, _cvMat);
//    cv::GaussianBlur(_cvMat, _cvMat, cv::Size(3,3), .5, .5);
}

@end

/// Converts an NSImage to Mat.
static void NSImageToMat(NSImage *image, cv::Mat &mat) {
    // Create a pixel buffer.
    NSBitmapImageRep *bitmapImageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSInteger width = [bitmapImageRep pixelsWide];
    NSInteger height = [bitmapImageRep pixelsHigh];
    CGImageRef imageRef = [bitmapImageRep CGImage];
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);

    // Draw all pixels to the buffer.
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);

    mat = mat8uc3;
}

/// Converts a Mat to NSImage.
static NSImage *MatToNSImage(cv::Mat &mat) {
    
    // Create a pixel buffer.
    assert(mat.elemSize() == 1 || mat.elemSize() == 3);
    cv::Mat matrgb;
    if (mat.elemSize() == 1) {
        cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, CV_BGR2RGB);
    }
    
    // Change a image format.
    NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
    CGColorSpaceRef colorSpace;
    if (matrgb.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [[NSImage alloc]init];
    [image addRepresentation:bitmapImageRep];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}
