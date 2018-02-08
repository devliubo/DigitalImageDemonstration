//
//  CoordianteUtilities.h
//  DigitalImageDemonstration
//
//  Created by liubo on 2018/2/8.
//  Copyright © 2018年 devliubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CoordianteUtilities : NSObject

+ (SCNVector3)positionFromTransform:(matrix_float4x4)transform;
+ (matrix_float4x4)translationMatrix:(matrix_float4x4)originMatrix translation:(vector_float4)translation;
+ (matrix_float4x4)rotateAroundY:(matrix_float4x4)originMatrix rotateDegree:(double)degree;
+ (simd_float4x4)transformMatrix:(simd_float4x4)originMatrix originLocation:(CLLocation *)originLocation desLocation:(CLLocation *)desLocation;
+ (double)bearingRadianBetweenLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation;

@end
