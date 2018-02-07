//
//  ARExampleViewController.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/12/7.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "ARExampleViewController.h"
#import "SceneNodeCreator.h"

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

@interface ARExampleViewController ()<ARSessionDelegate, ARSCNViewDelegate>

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
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993184 longitude:116.474674]];//116.474674,39.993184
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.991343 longitude:116.477495]];//116.477495,39.991343
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.993982 longitude:116.480467]];//116.480467,39.993982
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.995872 longitude:116.477646]];//116.477646,39.995872
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.997335 longitude:116.475403]];//116.475403,39.997335
    [points addObject:[CoordiantePoint coordiantePointWithLatitude:39.994648 longitude:116.472421]];//116.472421,39.994648
    
    self.pathPoints = @[points];
    self.currentPoint = [CoordiantePoint coordiantePointWithLatitude:39.993415 longitude:116.474266];//116.474266,39.993415
    
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
    self.sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
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
        SCNNode *currentNode = [SceneNodeCreator imageNodeWithImage:[UIImage imageNamed:@"destination"] position:position width:10 height:10];
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
    double factor = [self metersPerLongitudeAtLatitude:((point.latitude + basePoint.latitude)/2.0)]/8.0;
    
    WorldPosition *worldPosition = [[WorldPosition alloc] init];
    worldPosition.x = (point.longitude - basePoint.longitude) * factor;
    worldPosition.y = 0;
    worldPosition.z = -1.0 * (point.latitude - basePoint.latitude) * factor;
    
    return worldPosition;
}

- (double)metersPerLongitudeAtLatitude:(double)latitude {
#define kEarthCircle        40075016.6855785724052f
    return kEarthCircle / 360.0 * cos(latitude * M_PI / 180.f);
}

@end
