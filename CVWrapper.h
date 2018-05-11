//
//  CVWrapper.h
//  RepAR
//
//  Created by Guillaume Carré on 30/03/2018.
//  Copyright © 2018 ARFive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


@interface ImageDetected: NSObject

@property NSString* name;
@property NSMutableArray* boundingBox;

@end


@interface Transforms : NSObject

@property(nonatomic) GLKVector3 rotation;
@property(nonatomic) GLKVector3 translation;
@property(nonatomic) GLKVector3 scale;

@end

@interface CVWrapper : NSObject

/*
    =============================
    Methods below are for testing
    =============================
*/

//  This methods prints the features detected on an image
- (NSMutableArray*) processImage: (UIImage *) image boundingBox: (CGRect) rect;

- (NSMutableArray*) getBoundingBoxForFrame: (UIImage*) frame;

- (Transforms*) getCurrentTransform;

@end

