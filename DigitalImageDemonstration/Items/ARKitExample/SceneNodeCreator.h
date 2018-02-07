//
//  SceneNodeCreator.h
//  DigitalImageDemonstration
//
//  Created by liubo on 2018/2/7.
//  Copyright © 2018年 devliubo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>

@interface SceneNodeCreator : NSObject

+ (SCNNode *)arrowNodeWithPosition:(SCNVector3)position1 andPosition:(SCNVector3)position2;
+ (SCNNode *)pathNodeWithPosition:(SCNVector3)position1 andPosition:(SCNVector3)position2;
+ (SCNNode *)imageNodeWithImage:(UIImage *)image position:(SCNVector3)position width:(double)width height:(double)height;

@end
