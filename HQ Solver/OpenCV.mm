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
static cv::Mat _qTemplate;

- (instancetype)initWithImage:(nonnull NSImage *)image {
    _qTemplate = cv::imread("/Users/kon/Developer/HQ Solver/HQ Solver/q_template1.png", cv::IMREAD_GRAYSCALE);
    cv::resize(_qTemplate, _qTemplate, cv::Size(), 0.5, 0.5);

    _questionMarkPresent = false;
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
    cv::cvtColor(_cvMat, _cvMat, cv::COLOR_BGR2GRAY);
    cv::threshold(_cvMat, _cvMat, 200, 255, cv::THRESH_BINARY);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(_cvMat, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    auto largestArea = 0.0;
    auto largestIndex = 0;
    
    for(int i = 0; i < contours.size(); i++) {
        auto area = cv::contourArea(contours[i]);
        if (area > largestArea) {
            largestArea = area;
            largestIndex = i;
        }
    }
    
    cv::Rect bounds = cv::boundingRect(contours[largestIndex]);
    // close in on the bounds a little to get rid of edges
    // also crop the top end (counter) of the question box
    bounds.x += 5;
    bounds.y += 105;
    bounds.width -= 10;
    bounds.height -= 110;
    if (bounds.height > 0 && bounds.width > 0) {
        _cvMat = _cvMat(bounds);
    }
    
    double min = 0.0, max = 0.0;
    if (_cvMat.size().height >= _qTemplate.size().height &&
        _cvMat.size().width >= _qTemplate.size().height) {
        cv::Mat result;
        cv::matchTemplate(_cvMat, _qTemplate, result, cv::TM_CCOEFF_NORMED);
        cv::minMaxLoc(result, &min, &max);
//        printf("Min %f Max %f\n", min, max);
//        cv::imshow("Match", result);
    }

    self.questionMarkPresent = max > 0.85;
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
