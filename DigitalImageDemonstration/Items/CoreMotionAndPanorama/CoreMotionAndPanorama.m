//
//  CoreMotionAndPanorama.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/11/29.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "CoreMotionAndPanorama.h"
#import "MotionAndPanorama.h"

@interface CoreMotionAndPanorama ()

@property (nonatomic, strong) MotionAndPanorama *aView;

@end

@implementation CoreMotionAndPanorama

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.aView = [[MotionAndPanorama alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.aView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.aView startRenderer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.aView stopRenderer];
}

@end
