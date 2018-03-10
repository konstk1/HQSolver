//
//  OpenCVQB.mm
//  HQ Solver
//
//  Created by Konstantin Klitenik on 1/20/18.
//  Copyright © 2018 Konstantin Klitenik. All rights reserved.
//

#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
#import "OpenCVQB.h"

static void NSImageToMat(NSImage *image, cv::Mat &mat);
static NSImage *MatToNSImage(cv::Mat &mat);
static void showImage(cv::String title, cv::Mat img);

static void showImage(cv::String title, cv::Mat img) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        cv::imshow(title, img);
    });
}

static bool contourAreaCompare(std::vector<cv::Point> c1, std::vector<cv::Point> c2) {
    return cv::contourArea(c1) > cv::contourArea(c2);
}

static bool rectYCompare(cv::Rect r1, cv::Rect r2) {
    return r1.y < r2.y;
}

@interface OpenCVQB()

@property double qTemplateScaleFactor;
@property int qHeightAdjust;
@property int qAnswerHeight;

@property std::vector<cv::Rect> boundingRects;

@property cv::Mat cvMatOrig;
@property cv::Mat cvMat;

- (std::vector<cv::Rect>)sortContoursIntoRects:(std::vector<std::vector<cv::Point>>)contours;
- (int)detectCorrectAnswer:(cv::Mat)orig;

@end

@implementation OpenCVQB

static cv::Mat _qTemplate;
static bool _qTemplateLoaded = false;

- (instancetype)initWithImage:(nonnull NSImage *)image device:(int)device {
    _gameTitle = @"QuizBiz";
    
    if (device == 7) {                      // iPhone 7
        _qTemplateScaleFactor = 0.678;
        _qHeightAdjust = 80;
        _qAnswerHeight = 60;
    } else {                                // iPhone X
        _qTemplateScaleFactor = 0.5;
        _qHeightAdjust = 110;
        _qAnswerHeight = 90;
    }
    
    if (!_qTemplateLoaded) {
        printf("Loading Q template...\n");
        _qTemplate = cv::imread("/Users/kon/Developer/HQ Solver/HQ Solver/q_template_qb.png", cv::IMREAD_GRAYSCALE);
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

- (NSArray *)images {
    NSMutableArray *imgs = [NSMutableArray array];
    
    char *titles[] = {"Q", "1", "2", "3"};
    
    for (int i = 0; i < self.boundingRects.size(); i++) {
        cv::Mat mat = _cvMat(self.boundingRects[i]);
        [imgs addObject:MatToNSImage(mat)];
//        showImage(titles[i], mat);
    }
    return [NSArray arrayWithArray:imgs];
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

- (std::vector<cv::Rect>)sortContoursIntoRects:(std::vector<std::vector<cv::Point>>)contours {
    std::vector<cv::Rect> boundingRects;
    
    // 550 x 761
    cv::Rect rq = cv::Rect(30, 100, 490, 310);
    cv::Rect r1 = cv::Rect(30, 400, 490, 60);
    cv::Rect r2 = cv::Rect(30, 480, 490, 60);
    cv::Rect r3 = cv::Rect(30, 570, 490, 60);
//    if (contours.size() > 0) {
//        std::sort(contours.begin(), contours.end(), contourAreaCompare);
//
//        // get 4 largest contours
//        std::vector<std::vector<cv::Point>> sortedContours(contours.begin(), contours.begin() + MIN(contours.size()-1,4));
//
//        for(int i = 0; i < sortedContours.size(); i++) {
//            auto area = cv::contourArea(contours[i]);
//            if (area > 0) {
//                boundingRects.push_back(cv::boundingRect(contours[i]));
//            }
//        }
//
//        std::sort(boundingRects.begin(), boundingRects.end(), rectYCompare);            // sort by Y
//
//        for (int i = 0; i < boundingRects.size(); i++) {
//            // for answer bounding rectangles, take in width a little to get rid of angled corners
//            if (i >= 1) {
//                boundingRects[i].x += 35;
//                boundingRects[i].width = MAX(boundingRects[i].width - 80, 1);
//            }
////            printf("Rect %d - area: %d - Y: %d\n", i, boundingRects[i].area(), boundingRects[i].y);
//        }
//    }
    
    boundingRects.push_back(rq);
    boundingRects.push_back(r1);
    boundingRects.push_back(r2);
    boundingRects.push_back(r3);
    return boundingRects;
}

- (void)detectChoicesFromSortedContours:(std::vector<std::vector<cv::Point>>)contours {
    // contour[0] is largest, it's the question
    // contours[1-3] are the answers, need to sort by location (higest is choice 1)
    
}

- (int)detectCorrectAnswer {
    cv::Mat range;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;

    double maxMean = 0;
    int correctAnswer = 0;
    
    for (int i = 1; i < self.boundingRects.size(); i++) {
        cv::inRange(_cvMatOrig(self.boundingRects[i]), cv::Scalar(200, 220, 50), cv::Scalar(240, 255, 150), range);
        auto mean = cv::mean(range)[0];
        if (mean > maxMean) {
            maxMean = mean;
            correctAnswer = i;
        }
//        printf("Mean %d - %0.2f, %0.2f, %0.2f\n", i, mean[0], mean[1], mean[2]);
    }
    if (correctAnswer > 0) {
        printf("Correct answer %d (mean %0.1f)\n", correctAnswer, maxMean);
    }
    return correctAnswer;
}

- (void)prepareForOcr {
    _cvMatOrig = _cvMat;
    cv::cvtColor(_cvMat, _cvMat, cv::COLOR_BGR2GRAY);
    cv::threshold(_cvMat, _cvMat, 220, 255, cv::THRESH_BINARY);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(_cvMat, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

//    printf("Image %d x %d\n", _cvMat.size().width, _cvMat.size().height);
    self.boundingRects = [self sortContoursIntoRects:contours];
    if (self.boundingRects.size() == 0) {
        return;
    }
    
    cv::Rect qBounds = self.boundingRects[0];
    // close in on the bounds a little to get rid of edges
    // also crop the top end (counter) of the question box
    qBounds.x += 2;
    qBounds.y += self.qHeightAdjust;
    qBounds.width -= 4;
    qBounds.height -= (self.qHeightAdjust + 30);
    if (qBounds.height <= 0 || qBounds.width <= 0) {
        return;
    }
    
    _boundingRects[0] = qBounds;    // update q bounds
    
    cv::Mat qMat = _cvMat(qBounds);
    
    double min = 0.0, max = 0.0, maxAvg = 0.0;
    static double prevMax = 0.0;
    if (qMat.size().height >= _qTemplate.size().height &&
        qMat.size().width >= _qTemplate.size().height) {
        cv::Mat result;
        cv::matchTemplate(qMat, _qTemplate, result, cv::TM_CCOEFF_NORMED);
        cv::minMaxLoc(result, &min, &max);
        maxAvg = (max + prevMax) / 2;
        printf("Min %f Max %f Max Avg %f\n", min, max, maxAvg);
//        showImage("Match", result);
    }
    prevMax = max;

    self.questionMarkPresent = maxAvg > 0.82;
    if (self.questionMarkPresent) {
        self.correctAnswer = [self detectCorrectAnswer];
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
