//
//  CameraBufferToTexture.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/11/29.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "CameraBufferToTexture.h"
#import "CameraBufferToTextureView.h"

@interface CameraBufferToTexture ()

@property (nonatomic, strong) CameraBufferToTextureView *aView;

@end

@implementation CameraBufferToTexture

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.aView = [[CameraBufferToTextureView alloc] initWithFrame:self.view.bounds];
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
