//
//  CoordianteUtilities.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2018/2/8.
//  Copyright © 2018年 devliubo. All rights reserved.
//

#import "CoordianteUtilities.h"

@implementation CoordianteUtilities

+ (SCNVector3)positionFromTransform:(matrix_float4x4)transform {
    return SCNVector3Make(transform.columns[3].x, transform.columns[3].y, transform.columns[3].z);
}

+ (matrix_float4x4)translationMatrix:(matrix_float4x4)originMatrix translation:(vector_float4)translation {
    matrix_float4x4 result = originMatrix;
    result.columns[3] = translation;
    return result;
}

+ (matrix_float4x4)rotateAroundY:(matrix_float4x4)originMatrix rotateDegree:(double)degree {
    matrix_float4x4 matrix = originMatrix;
    
    matrix.columns[0].x = cos(degree);
    matrix.columns[0].z = -sin(degree);
    matrix.columns[2].x = sin(degree);
    matrix.columns[2].z = cos(degree);
    
    return simd_inverse(matrix);
}

+ (simd_float4x4)transformMatrix:(simd_float4x4)originMatrix originLocation:(CLLocation *)originLocation desLocation:(CLLocation *)desLocation {
    double distance = [desLocation distanceFromLocation:originLocation];
    double bearing = [CoordianteUtilities bearingRadianBetweenLocation:originLocation toLocation:desLocation];
    vector_float4 position = {0.0, 0.0, -distance, 0.0};
    
    matrix_float4x4 translationMatrix = [CoordianteUtilities translationMatrix:matrix_identity_float4x4 translation:position];
    matrix_float4x4 rotationMatrix = [CoordianteUtilities rotateAroundY:matrix_identity_float4x4 rotateDegree:bearing];
    simd_float4x4 transformMatrix = simd_mul(rotationMatrix, translationMatrix);
    
    return simd_mul(originMatrix, transformMatrix);
}

+ (double)bearingRadianBetweenLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation {
    double lat1 = [CoordianteUtilities degreeToRadian:fromLocation.coordinate.latitude];
    double lon1 = [CoordianteUtilities degreeToRadian:fromLocation.coordinate.longitude];
    
    double lat2 = [CoordianteUtilities degreeToRadian:toLocation.coordinate.latitude];
    double lon2 = [CoordianteUtilities degreeToRadian:toLocation.coordinate.longitude];
    
    double deltaLon = lon2 - lon1;
    double y = sin(deltaLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);
    double radian = atan2(y, x);
    
    return radian;
}

#pragma mark - Geometry

+ (double)degreeToRadian:(double)degree {
    return degree * M_PI / 180.f;
}

+ (double)radianToDegree:(double)radian {
    return radian * 180.f / M_PI;
}

@end
