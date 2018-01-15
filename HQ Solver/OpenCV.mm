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
#import "OpenCV.h"

static void NSImageToMat(NSImage *image, cv::Mat &mat);
static NSImage *MatToNSImage(cv::Mat &mat);
static void showImage(cv::String title, cv::Mat img);

static void showImage(cv::String title, cv::Mat img) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        cv::imshow(title, img);
    });
}

@interface OpenCV ()

@property double qTemplateScaleFactor;
@property int qHeightAdjust;
@property int qAnswerHeight;

@end

@implementation OpenCV

static cv::Mat _cvMatOrig;
static cv::Mat _cvMat;
static cv::Mat _qTemplate;
static bool _qTemplateLoaded = false;

- (instancetype)initWithImage:(nonnull NSImage *)image device:(int)device {
    if (device == 7) {                      // iPhone 7
        _qTemplateScaleFactor = 0.678;
        _qHeightAdjust = 80;
        _qAnswerHeight = 60;
    } else {                                // iPhone X
        _qTemplateScaleFactor = 1;
        _qHeightAdjust = 105;
        _qAnswerHeight = 90;
    }
    
    if (!_qTemplateLoaded) {
        printf("Loading Q template...\n");
        _qTemplate = cv::imread("/Users/kon/Developer/HQ Solver/HQ Solver/q_template2.png", cv::IMREAD_GRAYSCALE);
        _qTemplateLoaded = true;
        cv::resize(_qTemplate, _qTemplate, cv::Size(), _qTemplateScaleFactor, _qTemplateScaleFactor);
//        showImage("Q", _qTemplate);
    }
    
    _questionMarkPresent = false;
    _correctAnswer = 0;
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

- (std::vector<cv::Point>)getLargestContour:(std::vector<std::vector<cv::Point>>)contours {
    auto largestArea = 0.0;
    auto largestIndex = 0;
    
    for(int i = 0; i < contours.size(); i++) {
        auto area = cv::contourArea(contours[i]);
        if (area > largestArea) {
            largestArea = area;
            largestIndex = i;
        }
    }
    //    printf("Largest area: %.2f\n", largestArea);
    return largestArea > 0 ? contours[largestIndex] : std::vector<cv::Point>();;
}

- (int)detectCorrectAnswer:(cv::Mat)orig {
    cv::Mat range;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    
    cv::inRange(orig, cv::Scalar(130, 180, 30), cv::Scalar(170, 255, 150), range);
    cv::findContours(range, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

    cv::Rect boundsGreen = cv::boundingRect([self getLargestContour:contours]);
    printf("Green %d (h %d)\n", orig.size().height - boundsGreen.y, boundsGreen.height);
    cv::rectangle(_cvMat, boundsGreen, cv::Scalar(0,0,0));
    
    cv::inRange(orig, cv::Scalar(150, 100, 200), cv::Scalar(200, 160, 255), range);
    cv::findContours(range, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
//    cv::Rect boundsRed = cv::boundingRect([self getLargestContour:contours]);
//    printf("Red %d\n", orig.size().height - boundsRed.y);
//    cv::rectangle(_cvMat, boundsRed, cv::Scalar(0,0,0));
    
//    cv::imshow("Answers", orig);
    
    // assume each answer takes up 90 pixels
    // look at bounds position from the bottom of the image and calculate
    // answer, 1 being top-most, and 3 bottom-most
    int correctAnswer = 4 - floor((orig.size().height - boundsGreen.y) / self.qAnswerHeight);
//    printf("Answer: %d\n", correctAnswer);
    if (correctAnswer < 1 || correctAnswer > 3) {
        return 0;
    }
    return correctAnswer;
}

- (void)prepareForOcr {
    _cvMatOrig = _cvMat;
    cv::cvtColor(_cvMat, _cvMat, cv::COLOR_BGR2GRAY);
    cv::threshold(_cvMat, _cvMat, 200, 255, cv::THRESH_BINARY);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(_cvMat, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    auto largestContour = [self getLargestContour:contours];
    
    if (largestContour.size() == 0) {
        return;
    }
    
    cv::Rect bounds = cv::boundingRect(largestContour);
    // close in on the bounds a little to get rid of edges
    // also crop the top end (counter) of the question box
    bounds.x += 5;
    bounds.y += self.qHeightAdjust;
    bounds.width -= 10;
    bounds.height -= (self.qHeightAdjust + 5);
    if (bounds.height > 0 && bounds.width > 0) {
        _cvMat = _cvMat(bounds);
    }
    
    double min = 0.0, max = 0.0;
    if (_cvMat.size().height >= _qTemplate.size().height &&
        _cvMat.size().width >= _qTemplate.size().height) {
        cv::Mat result;
        cv::matchTemplate(_cvMat, _qTemplate, result, cv::TM_CCOEFF_NORMED);
        cv::minMaxLoc(result, &min, &max);
        printf("Min %f Max %f\n", min, max);
//        showImage("Match", result);
    }
    
    self.questionMarkPresent = max > 0.83;
    if (self.questionMarkPresent) {
        self.correctAnswer = [self detectCorrectAnswer:_cvMatOrig(bounds)];
    }
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
