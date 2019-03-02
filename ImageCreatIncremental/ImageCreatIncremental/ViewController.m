//
//  ViewController.m
//  ImageCreatIncremental
//
//  Created by 李思远 on 2019/3/1.
//  Copyright © 2019年 nuckyLee. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>

@interface ViewController ()<NSURLSessionDelegate, NSURLSessionDataDelegate>{
    CGFloat _expectedLeght;
    CGImageSourceRef _imageSource;
    size_t _width, _height;
    UIImageOrientation _orientation;
    CFAbsoluteTime _after;
    CFAbsoluteTime _before;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSMutableData *recieveData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_imageSource) {
        _imageSource = CGImageSourceCreateIncremental(NULL);
    }
}

- (IBAction)starDownload:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1207/05/c0/12233333_1341470829710.jpg"];
    //3、url加载
//    _before = CFAbsoluteTimeGetCurrent();
//    self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
//    CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
//    NSLog(@"Decompress %.2f ms", (after - _before) * 1000);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue new]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
}

#pragma mark - NSURLSessionDelegate

//接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    
    _expectedLeght = response.expectedContentLength;
    NSLog(@"_expectedLeght   %f", _expectedLeght);
    
}

//接收到服务器的数据（可能调用多次）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (!self.recieveData) {
        self.recieveData = [[NSMutableData alloc] initWithCapacity:_expectedLeght];
        _before = CFAbsoluteTimeGetCurrent();
    }
    [self.recieveData appendData:data];
    
    CGFloat length = _expectedLeght;
    CGFloat dataLength = self.recieveData.length;
    NSLog(@"....%f",dataLength/length);
    
    BOOL isFinish = (self.recieveData.length >= _expectedLeght);
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)self.recieveData, isFinish);
//  1、强制解压缩方式
    /*
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &_orientation);
            CFRelease(properties);

            _orientation = UIImageOrientationUp;
        }
    }
    
    if (_width + _height > 0) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        if (imageRef) {
            const size_t partialHeight = CGImageGetHeight(imageRef);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef bmContext = CGBitmapContextCreate(NULL, _width, _height, 8, 0, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
            if (bmContext) {
                CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = _width, .size.height = partialHeight}, imageRef);
                CGImageRelease(imageRef);
                imageRef = CGBitmapContextCreateImage(bmContext);
                CGContextRelease(bmContext);
            } else {
                CGImageRelease(imageRef);
                imageRef = nil;
            }
        }
    
        if (imageRef) {
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:_orientation];
            CGImageRelease(imageRef);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    }*/
    //2、系统压缩方式
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
    if (imageRef) {
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    }
    
    if (isFinish) {
        if (_imageSource) {
            CFRelease(_imageSource);
            _imageSource = NULL;
        }
        CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
        NSLog(@"Decompress %.2f ms", (after - _before) * 1000);
    }
}

// 3.请求成功或者失败（如果失败，error有值）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 请求完成,成功或者失败的处理
}

@end
