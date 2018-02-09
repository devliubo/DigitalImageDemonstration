//
//  SceneNodeCreator.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2018/2/7.
//  Copyright © 2018年 devliubo. All rights reserved.
//

#import "SceneNodeCreator.h"

@implementation SceneNodeCreator

+ (SCNNode *)arrowNodeWithPosition:(SCNVector3)position1 andPosition:(SCNVector3)position2 {
    double angle = [SceneNodeCreator angleForPosition:position1 andPosition:position2];
    
    SCNVector3 midPosition = SCNVector3Make((position1.x+position2.x)/2.0, (position1.y+position2.y)/2.0+1.0, (position1.z+position2.z)/2.0);
    
    SCNNode *arrowNode = [SceneNodeCreator imageNodeWithImage:[UIImage imageNamed:@"arrow"] position:midPosition width:2 height:2];
    arrowNode.rotation = SCNVector4Make(0, 1, 0, angle);
    
    return arrowNode;
}

+ (SCNNode *)pathNodeWithPosition:(SCNVector3)position1 andPosition:(SCNVector3)position2 {
    double dx = position2.x - position1.x;
    double dz = -(position2.z - position1.z);
    double angle = [SceneNodeCreator angleForPosition:position1 andPosition:position2];
    
    double width = sqrt((dx*dx + dz*dz));
    double height = 0.01;
    double length = 0.6;
    
    SCNBox *route = [SCNBox boxWithWidth:width height:height length:length chamferRadius:0];
    route.firstMaterial.diffuse.contents = [UIColor colorWithRed:0.3 green:0.63 blue:0.89 alpha:0.8];
    
    SCNVector3 midPosition = SCNVector3Make((position1.x+position2.x)/2.0, (position1.y+position2.y)/2.0, (position1.z+position2.z)/2.0);
    
    SCNNode *node = [SCNNode nodeWithGeometry:route];
    node.position = midPosition;
    node.rotation = SCNVector4Make(0, 1, 0, angle);
    
    return node;
}

+ (SCNNode *)imageNodeWithImage:(UIImage *)image position:(SCNVector3)position width:(double)width height:(double)height {
    SCNPlane *plane = [SCNPlane planeWithWidth:width height:height];
    plane.firstMaterial.diffuse.contents = image;
    plane.firstMaterial.lightingModelName = SCNLightingModelConstant;
    
    SCNNode *node = [SCNNode nodeWithGeometry:plane];
    node.position = position;
    return node;
}

#pragma mark - Helper

+ (double)angleForPosition:(SCNVector3)position1 andPosition:(SCNVector3)position2 {
    double dx = position2.x - position1.x;
    double dz = position2.z - position1.z;
    
    if (dx == 0) {
        return M_PI_2;
    } else {
        return atan(-dz/dx);
    }
}

@end
