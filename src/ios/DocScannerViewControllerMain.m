//
//  ViewController.m
//  IPDFCameraViewController
//
//  Created by Maximilian Mackh on 11/01/15.
//  Copyright (c) 2015 Maximilian Mackh. All rights reserved.
//
#import "DocScanner.h"
#import "DocScannerViewControllerMain.h"
#import "DocScannerViewControllerPreview.h"
#import "IPDFCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet IPDFCameraViewController *cameraViewController;
@property (weak, nonatomic) IBOutlet UIImageView *focusIndicator;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIButton *cropButton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;


- (IBAction)focusGesture:(id)sender;
- (IBAction)captureButton:(id)sender;
- (IBAction)dismissButton:(id)sender;

@end

@implementation ViewController

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.cameraViewController setupCameraView];
    [self.cameraViewController setEnableBorderDetection:YES];

    [self.cameraViewController setCameraViewType:IPDFCameraViewTypeNormal];

}

- (void)viewDidAppear:(BOOL)animated
{
    [self.cameraViewController start];

}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark CameraVC Actions

- (IBAction)focusGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [sender locationInView:self.cameraViewController];

        [self focusIndicatorAnimateToPoint:location];

        [self.cameraViewController focusAtPoint:location completionHandler:^
         {
             [self focusIndicatorAnimateToPoint:location];
         }];
    }
}

- (void)focusIndicatorAnimateToPoint:(CGPoint)targetPoint
{
    [self.focusIndicator setCenter:targetPoint];
    self.focusIndicator.alpha = 0.0;
    self.focusIndicator.hidden = NO;

    [UIView animateWithDuration:0.4 animations:^
    {
         self.focusIndicator.alpha = 1.0;
    }
    completion:^(BOOL finished)
    {
         [UIView animateWithDuration:0.4 animations:^
         {
             self.focusIndicator.alpha = 0.0;
         }];
     }];
}

- (IBAction)borderDetectToggle:(id)sender
{
    BOOL enable = !self.cameraViewController.isBorderDetectionEnabled;
    //[self changeButton:sender targetTitle:(enable) ? @"CROP On" : @"CROP Off" toStateEnabled:enable];
    [self changeButton:sender toStateEnabled:!enable]; //This is needed because selected is off.
    self.cameraViewController.enableBorderDetection = enable;
}

- (void)filterToggle
{
    [self.cameraViewController setCameraViewType:IPDFCameraViewTypeNormal];
    //[self updateTitleLabel];
}

- (IBAction)torchToggle:(id)sender
{
    BOOL enable = !self.cameraViewController.isTorchEnabled;
    [self changeButton:sender toStateEnabled:enable];
    self.cameraViewController.enableTorch = enable;
}

- (void)changeButton:(UIButton *)button toStateEnabled:(BOOL)enabled
{
    if(enabled){
        button.selected = YES;
    }else{
        button.selected = NO;
    }
}


#pragma mark -
#pragma mark CameraVC Capture Image

- (IBAction)captureButton:(id)sender
{
//    __weak typeof(self) weakSelf = self;

    [self.cameraViewController captureImageWithCompletionHander:^(NSString *imageFilePath)
    {

        // Get a reference to the captured image
        UIImage* image = [UIImage imageWithContentsOfFile:imageFilePath];

        //To resize the image; use this.
        double targetWidth = [self.plugin.options.targetWidth doubleValue];
        double targetHeight = [self.plugin.options.targetHeight doubleValue];
        if(targetWidth == 0 && targetHeight == 0){
            //NOTHING
            //XXX I know this can be done another way
        }else image = [self imageWithImage:image toTargetWidth:targetWidth toTargetHeight:targetHeight];

        //change orientation of the image to match device orientation
        //normal = 1 | upsidedown = 2 | left = 3 | right = 4
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        if(deviceOrientation != 1) image = [self rotate:image withOrientation:deviceOrientation]; //Just to reduce the latency

        // Get the image data (blocking; around 1 second)
        //Second parameter is the quality 0.8 = 80%
        float quality = [self.plugin.options.targetHeight floatValue] / 100;
        NSData* imageData = UIImageJPEGRepresentation(image, quality); //NGRepresentation(image);

        // Write the data to the file
        [imageData writeToFile:imageFilePath atomically:YES];


        // Save to photo album if needed
        if(self.plugin.options.saveToPhotoAlbum){
            UIImage* savedImage = [UIImage imageWithContentsOfFile:imageFilePath];
            UIImageWriteToSavedPhotosAlbum(savedImage, nil, nil, nil);
        }

        // Tell the plugin class that we're finished processing the image
        if(self.plugin.options.toBase64) [self.plugin capturedImageWithPath:imageData];
        else {
            UIImage* savedImage = [UIImage imageWithContentsOfFile:imageFilePath];
            [self.plugin captureImageWithFilePath:imageFilePath];
        }
    }];
}

-(void) dismissButton:(id)sender{
    [self.plugin dismissCamera];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//Not used anymore, still here for users that still want to enable this again.
// - (void)dismissPreview:(UITapGestureRecognizer *)dismissTap
// {
//     [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionAllowUserInteraction animations:^
//     {
//         dismissTap.view.frame = CGRectOffset(self.view.bounds, 0, self.view.bounds.size.height);
//     }
//     completion:^(BOOL finished)
//     {
//         [dismissTap.view removeFromSuperview];
//     }];
// }

-(UIImage*)imageWithImage: (UIImage*) sourceImage toTargetWidth: (float) targetWidth toTargetHeight:(float)targetHeight
{
    //image = [self.plugin imageWithImage:image resizeTo:CGSizeMake(targetWidth,targetWidth *image.size.height/image.size.width)];

    float oldWidth = sourceImage.size.width;
    float oldHeight = sourceImage.size.height;


    float newWidth = oldWidth;
    float newHeight = oldHeight;


    if((targetWidth != 0) && (targetWidth <= oldWidth)){
        newWidth = targetWidth * oldHeight/oldWidth;
    }

    if((targetHeight != 0) && (targetHeight <= oldHeight)){
        newHeight = targetHeight * oldWidth/oldHeight;
    }

    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


-(UIImage*) rotate:(UIImage*)src withOrientation:(UIDeviceOrientation)orientation
{

    bool perpendicular = false;

    UIGraphicsBeginImageContext(CGSizeMake(src.size.width, src.size.height));

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, src.size.width / 2, src.size.height / 2);
    if (orientation == 4) {
        CGContextRotateCTM (context, M_PI_2);
        perpendicular = true;
    } else if (orientation == 3) {
        CGContextRotateCTM (context, -M_PI_2);
        perpendicular = true;
    } else if (orientation == 1) {
        CGContextRotateCTM (context, 0.0);
    } else if (orientation == 2) {
        CGContextRotateCTM (context, M_PI);
    }

    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? src.size.height : src.size.width;
    float height = perpendicular ? src.size.width : src.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [src CGImage]);

    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -src.size.height / 2, -src.size.width / 2);
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


@end
