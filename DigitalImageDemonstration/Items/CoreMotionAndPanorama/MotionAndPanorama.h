//
//  MotionAndPanorama.h
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/11/29.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <CoreMotion/CoreMotion.h>

@interface MotionAndPanorama : GLKView

- (void)startRenderer;
- (void)stopRenderer;

@end
