//
//  ARExampleViewController.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/12/7.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "ARExampleViewController.h"
#import "SceneNodeCreator.h"
#import "CoordianteUtilities.h"

#pragma mark - CoordiantePoint

@interface CoordiantePoint : NSObject
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
+ (instancetype)coordiantePointWithLatitude:(double)latitude longitude:(double)longitude;
@end

@implementation CoordiantePoint
+ (instancetype)coordiantePointWithLatitude:(double)latitude longitude:(double)longitude {
    CoordiantePoint *reVal = [[CoordiantePoint alloc] init];
    reVal.latitude = latitude;
    reVal.longitude = longitude;
    return reVal;
}
@end

#pragma mark - WorldPosition

@interface WorldPosition : NSObject
@property (nonatomic, assign) double x;
@property (nonatomic, assign) double y;
@property (nonatomic, assign) double z;
@end

@implementation WorldPosition
@end

#pragma mark - ARExampleViewController

@interface ARExampleViewController ()<ARSessionDelegate, ARSCNViewDelegate, SCNSceneRendererDelegate, ARSessionObserver>

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) ARWorldTrackingConfiguration *config;

@property (nonatomic, strong) NSArray<NSArray<CoordiantePoint *> *> *pathPoints;
@property (nonatomic, strong) CoordiantePoint *currentPoint;

@property (nonatomic, strong) NSArray<NSArray<WorldPosition *> *> *worldPositions;
@property (nonatomic, strong) WorldPosition *currentPosition;

@end

@implementation ARExampleViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self initProperties];
    
    [self initSceneView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self buildScene];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.sceneView.session runWithConfiguration:self.config];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.sceneView.session pause];
}

- (void)initProperties {
    NSMutableArray *points = [[NSMutableArray alloc] init];
//    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993184 longitude:116.474674]];//116.474674,39.993184
//    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.991343 longitude:116.477495]];//116.477495,39.991343
//    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993982 longitude:116.480467]];//116.480467,39.993982
//    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.995872 longitude:116.477646]];//116.477646,39.995872
//    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.997335 longitude:116.475403]];//116.475403,39.997335
//    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.994648 longitude:116.472421]];//116.472421,39.994648

    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993033 longitude:116.473383]];//116.473383, 39.993033
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.992949 longitude:116.473285]];//116.473285, 39.992949
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.992814 longitude:116.473505]];//116.473505, 39.992814
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993047 longitude:116.473752]];//116.473752, 39.993047
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993089 longitude:116.473697]];//116.473697, 39.993089
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993173 longitude:116.473807]];//116.473807, 39.993173
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993674 longitude:116.473029]];//116.473029, 39.993674
    
    self.pathPoints = @[points];
    self.currentPoint = [points firstObject];
    
    [self buildWorldPositionFromPathPoints];
}

- (void)initSceneView {
    self.sceneView = [[ARSCNView alloc] initWithFrame:CGRectMake(10, 10, 300, 500)];
    
    self.sceneView.delegate = self;
    self.sceneView.session.delegate = self;
    self.sceneView.showsStatistics = YES;
    self.sceneView.autoenablesDefaultLighting = YES;
    self.sceneView.allowsCameraControl = NO;
    
    [self.view addSubview:self.sceneView];
    
    self.config = [[ARWorldTrackingConfiguration alloc] init];
    self.config.planeDetection = ARPlaneDetectionHorizontal;
    self.config.lightEstimationEnabled = YES;
    self.config.worldAlignment = ARWorldAlignmentGravityAndHeading;
    
    //Other
//    self.sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
}

#pragma mark - Scene

- (void)buildScene {
    if ([self.worldPositions count] <= 0) {
        return;
    }
    
    SCNScene *scene = [SCNScene scene];
    
    SCNVector3 lastPosition = SCNVector3Zero;
    for (NSArray<WorldPosition *> *section in self.worldPositions) {
        for (WorldPosition *position in section) {
            
            SCNVector3 arrowPosition = SCNVector3Make(position.x, position.y, position.z);
            SCNNode *arrowNode = [SceneNodeCreator arrowNodeWithPosition:lastPosition andPosition:arrowPosition];
            SCNNode *routeNode = [SceneNodeCreator pathNodeWithPosition:lastPosition andPosition:arrowPosition];
            
            [scene.rootNode addChildNode:arrowNode];
            [scene.rootNode addChildNode:routeNode];
            
            lastPosition = arrowPosition;
        }
    }
    
    if (self.currentPosition != nil) {
        SCNVector3 position = SCNVector3Make(self.currentPosition.x, self.currentPosition.y, self.currentPosition.z);
        SCNNode *currentNode = [SceneNodeCreator imageNodeWithImage:[UIImage imageNamed:@"destination"] position:position width:1 height:1];
        currentNode.scale = SCNVector3Make(1, 1, 1);
        [scene.rootNode addChildNode:currentNode];
    }
    
    self.sceneView.scene = scene;
}

#pragma mark - Geometry

- (void)buildWorldPositionFromPathPoints {
    if ([self.pathPoints count] <= 0 || [[self.pathPoints firstObject] count] <= 0) {
        return;
    }
    
    CoordiantePoint *basePoint = [[self.pathPoints firstObject] firstObject];
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSArray<CoordiantePoint *> *section in self.pathPoints) {
        NSMutableArray<WorldPosition *> *sectionPositions = [[NSMutableArray alloc] init];
        for (CoordiantePoint *point in section) {
            WorldPosition *position = [self convertCoordiantePointToWorldPosition:point basePoint:basePoint];
            [sectionPositions addObject:position];
        }
        [result addObject:sectionPositions];
    }
    
    self.worldPositions = result;
    self.currentPosition = [self convertCoordiantePointToWorldPosition:self.currentPoint basePoint:basePoint];
}

- (WorldPosition *)convertCoordiantePointToWorldPosition:(CoordiantePoint *)point basePoint:(CoordiantePoint *)basePoint {
    
    WorldPosition *result = [[WorldPosition alloc] init];
    
    CLLocation *originLocation = [[CLLocation alloc] initWithLatitude:basePoint.latitude longitude:basePoint.longitude];
    CLLocation *desLocation = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
    simd_float4x4 transform = [CoordianteUtilities transformMatrix:matrix_identity_float4x4 originLocation:originLocation desLocation:desLocation];
    SCNVector3 position = [CoordianteUtilities positionFromTransform:transform];
    
    result.x = position.x;
    result.y = position.y;
    result.z = position.z;
    return result;
}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
//    NSLog(@"didUpdateFrame");
}

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor*>*)anchors {
    NSLog(@"didAddAnchors");
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor*>*)anchors {
    NSLog(@"didUpdateAnchors");
}

- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor*>*)anchors {
    NSLog(@"didRemoveAnchors");
}

#pragma mark - ARSessionObserver

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError");
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    NSLog(@"cameraDidChangeTrackingState:%ld", (long)camera.trackingState);
}

- (void)sessionWasInterrupted:(ARSession *)session {
    NSLog(@"sessionWasInterrupted");
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    NSLog(@"sessionInterruptionEnded");
}

- (void)session:(ARSession *)session didOutputAudioSampleBuffer:(CMSampleBufferRef)audioSampleBuffer {
    NSLog(@"didOutputAudioSampleBuffer");
}

#pragma mark - ARSCNViewDelegate

//- (nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
//
//}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"didAddNode");
}

- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"willUpdateNode");
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"didUpdateNode");
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"didRemoveNode");
}

@end
