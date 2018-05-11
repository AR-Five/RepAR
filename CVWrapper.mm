//
//  CVWrapper.m
//  RepAR
//
//  Created by Guillaume Carré on 30/03/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

#import "CVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>


using namespace cv;
using namespace std;

const int min_features = 12; // min feature

const double nn_match_ratio = 0.7f; // Nearest-neighbour matching ratio
const double ransac_thresh = 2.5f; // RANSAC inlier threshold


struct ImageDescriptor {
    NSString* name;
    Mat desc;
    vector<KeyPoint> keyPoints;
};

@implementation Transforms
@end

@implementation ImageDetected
@end

@implementation CVWrapper
{
    Ptr<FeatureDetector> detector;
    Ptr<DescriptorMatcher> matcher;
    
    vector<ImageDescriptor> images;
    
    vector<KeyPoint> imageKeyPoints;
    Mat imageDesc;
    vector<Point2f> boundingBox;
    
    Mat cHomography;
    
    Mat cameraMatrix;
}

- (id) init {
    self = [super init];
    if (self) {
        detector = ORB::create();
        matcher = DescriptorMatcher::create("BruteForce-Hamming");
    }
    return self;
}

- (NSMutableArray*) processImage: (UIImage*) image boundingBox: (CGRect) rect {
    Mat m;
    UIImageToMat(image, m);
    
    //
//    boundingBox.clear();
//    for (int i = 0; i < 4; i++) {
//        boundingBox.push_back(Point2f(bbox[i].x, bbox[i].y));
//    }
    boundingBox.push_back(Point2f(rect.origin.x, rect.origin.y));
    boundingBox.push_back(Point2f(rect.origin.x + rect.size.width, rect.origin.y));
    boundingBox.push_back(Point2f(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height));
    boundingBox.push_back(Point2f(rect.origin.x, rect.origin.y + rect.size.height));

    vector<KeyPoint> imgKp;
    Mat imgDesc;
    
    //if (save) {
       detector->detectAndCompute(m, noArray(), imageKeyPoints, imageDesc);
        imgKp = imageKeyPoints;
    //} else {
        //detector->detectAndCompute(m, noArray(), imgKp, imgDesc);
    //}
    
    NSMutableArray* arr = [NSMutableArray new];
    
    for (auto const& value: imgKp) {
        CGPoint p;
        p.x = value.pt.x;
        p.y = value.pt.y;
        
        NSValue* data = [NSValue valueWithBytes:&p objCType:@encode(CGPoint)];
        [arr addObject: data];
    }
    
    return arr;
}

- (NSMutableArray*) getBoundingBoxForFrame: (UIImage*) frame {
    
    vector<KeyPoint> frameKeyPoints;
    Mat f, desc;
    UIImageToMat(frame, f);
    
    detector->detectAndCompute(f, noArray(), frameKeyPoints, desc);
    
    vector< vector<DMatch> > matches;
    vector<KeyPoint> matched1, matched2;
    
    
    if (imageDesc.cols != desc.cols) {
        return nil;
    }
    
    
    matcher->knnMatch(imageDesc, desc, matches, 2);
    
    for(unsigned i = 0; i < matches.size(); i++) {
        if(matches[i][0].distance < nn_match_ratio * matches[i][1].distance) {
            matched1.push_back(imageKeyPoints[matches[i][0].queryIdx]);
            matched2.push_back(frameKeyPoints[matches[i][0].trainIdx]);
        }
    }
    
    Mat inlier_mask, homography;
    
    vector<Point2f> pmatched1, pmatched2;
    KeyPoint::convert(matched1, pmatched1);
    KeyPoint::convert(matched2, pmatched2);
    
    //cout << pmatched1.size() << endl;
    
    if (pmatched1.size() >= min_features && pmatched1.size() < 500) {
        homography = findHomography(pmatched1, pmatched2, RANSAC, ransac_thresh, inlier_mask);
        cHomography = homography;
    }
    
    if (pmatched1.size() < min_features || homography.empty()) {
        return nil;
    }
    
    vector<Point2f> new_bb;
    perspectiveTransform(boundingBox, new_bb, homography);
    
    double focal_length = f.cols; // Approximate focal length.
    Point2d center = cv::Point2d(f.cols/2, f.rows/2);
    cameraMatrix = (Mat_<double>(3,3) << focal_length, 0, center.x, 0 , focal_length, center.y, 0, 0, 1);

    NSMutableArray* arr = [NSMutableArray new];
    for (auto const& value: new_bb) {
        CGPoint p;
        p.x = value.x;
        p.y = value.y;
        
        NSValue* data = [NSValue valueWithBytes:&p objCType:@encode(CGPoint)];
        [arr addObject: data];
    }
    
    return arr;
}


- (Transforms*) getCurrentTransform {
    
    vector<Mat> rotation_decomp, translations_decomp, normals_decomp;
    decomposeHomographyMat(cHomography, cameraMatrix, rotation_decomp, translations_decomp, normals_decomp);
    
    Mat rotation_vec;
    Rodrigues(rotation_decomp[0], rotation_vec);
    
    Point3f rot(rotation_vec), transl(translations_decomp[0]), scale(normals_decomp[0]);
    
//    cout << "rotation: " << rot << endl;
//    cout << "translate: " << transl << endl;
//    cout << "normal: " << scale << endl;
    
    Transforms *t = [Transforms new];
    [t setRotation: GLKVector3Make(rot.x, rot.y, rot.z)];
    [t setTranslation: GLKVector3Make(transl.x, transl.y, transl.z)];
    [t setScale: GLKVector3Make(scale.x, scale.y, scale.z)];
    
    
    return t;
}

@end
