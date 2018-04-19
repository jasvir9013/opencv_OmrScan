//
//  CircleDetectIonVC.m
//  opencv_test
//
//  Created by Jasvir Singh on 20/02/17.
//

#import "CircleDetectIonVC.h"
@interface CircleDetectIonVC ()

@end

@implementation CircleDetectIonVC

cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3];
    int x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1-x2) * (y3-y4)) - ((y1-y2) * (x3-x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2) * (x3-x4) - (x1-x2) * (x3*y4 - y3*x4)) / d;
        pt.y = ((x1*y2 - y1*x2) * (y3-y4) - (y1-y2) * (x3*y4 - y3*x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

bool comparator2(double a,double b){
    return a<b;
}
bool comparator3(cv::Vec3f a,cv::Vec3f b){
    return a[0]<b[0];
}

bool comparator(cv::Point2f a,cv::Point2f b){
    return a.x<b.x;
}
void sortCorners(std::vector<cv::Point2f>& corners, cv::Point2f center)
{
    std::vector<cv::Point2f> top, bot;
    for (int i = 0; i < corners.size(); i++)
    {
        if (corners[i].y < center.y)
            top.push_back(corners[i]);
        else
            bot.push_back(corners[i]);
    }
    
    
    sort(top.begin(),top.end(),comparator);
    sort(bot.begin(),bot.end(),comparator);
    
    cv::Point2f tl = top[0];
    cv::Point2f tr = top[top.size()-1];
    cv::Point2f bl = bot[0];
    cv::Point2f br = bot[bot.size()-1];
    corners.clear();
    corners.push_back(tl);
    corners.push_back(tr);
    corners.push_back(br);
    corners.push_back(bl);  
}  

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"omr.png"];
    cv::Mat img = [self cvMatGrayFromUIImage:image];
    
   // cv::Mat img = cv::imread("example.jpg",0);
    [self showImage:[self UIImageFromCVMat:img]];

    cv::Size size(3,3);
    cv::GaussianBlur(img,img,size,0);
    adaptiveThreshold(img, img,255,CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY,75,10);
    cv::bitwise_not(img, img);
    
    cv::Mat img2;
    cvtColor(img,img2, CV_GRAY2RGB);
    
    cv::Mat img3;
    cvtColor(img,img3, CV_GRAY2RGB);
    
    cv::vector<cv::Vec4i> lines;
    HoughLinesP(img, lines, 1, CV_PI/180, 80, 400, 10);
    for( size_t i = 0; i < lines.size(); i++ )
    {
        cv::Vec4i l = lines[i];
        line( img2, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cvScalar(0,0,255), 3, CV_AA);
    }
    
    
    [self showImage:[self UIImageFromCVMat:img2]];
    
   // imshow("example",img2);
 
    std::vector<cv::Point2f> corners;
    for (int i = 0; i < lines.size(); i++)
    {
        for (int j = i+1; j < lines.size(); j++)
        {
            cv::Point2f pt = computeIntersect(lines[i], lines[j]);
            if (pt.x >= 0 && pt.y >= 0 && pt.x < img.cols && pt.y < img.rows)
                corners.push_back(pt);
        }
    }
    
    // Get mass center
    cv::Point2f center(0,0);
    for (int i = 0; i < corners.size(); i++)
        center += corners[i];
    center *= (1. / corners.size());
    
    sortCorners(corners, center);
    
    cv::Rect r = boundingRect(corners);
    
    std::cout<<r<<std::endl;
    cv::Mat quad = cv::Mat::zeros(r.height, r.width, CV_8UC3);
    // Corners of the destination image
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
    quad_pts.push_back(cv::Point2f(0, quad.rows));
    
    // Get transformation matrix
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
    // Apply perspective transformation
    cv::warpPerspective(img3, quad, transmtx, quad.size());
    
   // imshow("example2",quad);
    [self showImage:[self UIImageFromCVMat:quad]];

    cv::Mat cimg;
    
    cvtColor(quad,cimg, CV_BGR2GRAY);
    cv::vector<cv::Vec3f> circles;
    HoughCircles(cimg, circles, CV_HOUGH_GRADIENT, 1, img.rows/8, 100, 75, 0, 0 );
    for( size_t i = 0; i < circles.size(); i++ ){
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        // circle center
        circle( quad, center, 3, cvScalar(0,255,0), -1, 8, 0 );
    }
    
   // imshow("example4",quad);
   // cv::waitKey();
    
    double averR = 0;
    cv::vector<double> row;
    cv::vector<double> col;
    
    //Find rows and columns of circles for interpolation
    for(int i=0;i<circles.size();i++){
        bool found = false;
        int r = cvRound(circles[i][2]);
        averR += r;
        int x = cvRound(circles[i][0]);
        int y = cvRound(circles[i][1]);
        for(int j=0;j<row.size();j++){
            double y2 = row[j];
            if(y - r < y2 && y + r > y2){
                found = true;
                break;
            }
        }
        if(!found){
            row.push_back(y);
        }
        found = false;
        for(int j=0;j<col.size();j++){
            double x2 = col[j];
            if(x - r < x2 && x + r > x2){
                found = true;
                break;
            }
        }
        if(!found){
            col.push_back(x);
        }
    }
    
    averR /= circles.size();
    
    sort(row.begin(),row.end(),comparator2);
    sort(col.begin(),col.end(),comparator2);
    
    for(int i=0;i<row.size();i++){
        double max = 0;
        double y = row[i];
        int ind = -1;
        for(int j=0;j<col.size();j++){
            double x = col[j];
            cv::Point c(x,y);
            
            //Use an actual circle if it exists
            for(int k=0;k<circles.size();k++){
                double x2 = circles[k][0];
                double y2 = circles[k][1];
                if(std::abs(y2-y)<averR && std::abs(x2-x)<averR){
                    x = x2;
                    y = y2;
                }
            }
            
            // circle outline
            circle( quad, c, averR, cvScalar(0,0,255), 3, 8, 0 );
            cv::Rect rect(x-averR,y-averR,2*averR,2*averR);
            cv::Mat submat = cimg(rect);
            double p =(double)countNonZero(submat)/(submat.size().width*submat.size().height);
            if(p>=0.3 && p>max){
                max = p;
                ind = j;
            }
        }
        if(ind==-1)printf("%d:-",i+1);
        else printf("%d:%c",i+1,'A'+ind);
        std::cout<<std::endl;
    }
    
    // circle outline*/
   // imshow("example3",quad);
    [self showImage:[self UIImageFromCVMat:quad]];

  //  cv::waitKey();

    
    // Do any additional setup after loading the view.
}


// cv::mat from UIImage

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    
    cv::Mat cvMat = [self cvMatFromUIImage:image];
    cv::Mat grayMat;
    
    if (cvMat.channels() == 1) {
        grayMat = cvMat;
    } else{
        grayMat = cv :: Mat(cvMat.rows,cvMat.cols, CV_8UC1);
        cv::cvtColor(cvMat, grayMat, CV_BGR2GRAY);
    }
    return grayMat;
    
    
//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
//    CGFloat cols = image.size.width;
//    CGFloat rows = image.size.height;
//    
//    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
//    
//    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
//                                                    cols,                       // Width of bitmap
//                                                    rows,                       // Height of bitmap
//                                                    8,                          // Bits per component
//                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
//                                                    kCGImageAlphaNoneSkipLast |
//                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
//    
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
//    CGContextRelease(contextRef);
//    
//    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}
// IplImage From UIImage

- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

-(void)showImage :(UIImage*)image{
    _mImageView.image = image;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
