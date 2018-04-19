//
//  CircleDetectIonVC.h
//  opencv_test
//
//  Created by Jasvir Singh on 20/02/17.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/highgui/ios.h>
#include <opencv2/imgproc/imgproc.hpp>


@interface CircleDetectIonVC : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *mImageView;

@end
