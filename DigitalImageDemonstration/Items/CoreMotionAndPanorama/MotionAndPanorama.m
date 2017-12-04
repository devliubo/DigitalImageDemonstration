//
//  MotionAndPanorama.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/11/29.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "MotionAndPanorama.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#pragma mark - Generate Sphere

/// https://github.com/danginsburg/opengles-book-samples/blob/604a02cc84f9cc4369f7efe93d2a1d7f2cab2ba7/iPhone/Common/esUtil.h#L110
int esGenSphere(int numSlices, float radius, float **vertices, float **texCoords, uint16_t **indices, int *numVertices_out) {
    int numParallels = numSlices / 2;
    int numVertices = (numParallels + 1) * (numSlices + 1);
    int numIndices = numParallels * numSlices * 6;
    float angleStep = (2.0f * 3.14159265f) / ((float) numSlices);
    
    if (vertices != NULL) {
        *vertices = malloc(sizeof(float) * 3 * numVertices);
    }
    
    if (texCoords != NULL) {
        *texCoords = malloc(sizeof(float) * 2 * numVertices);
    }
    
    if (indices != NULL) {
        *indices = malloc(sizeof(uint16_t) * numIndices);
    }
    
    for (int i = 0; i < numParallels + 1; i++) {
        for (int j = 0; j < numSlices + 1; j++) {
            int vertex = (i * (numSlices + 1) + j) * 3;
            
            if (vertices) {
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
            }
            
            if (texCoords) {
                int texIndex = (i * (numSlices + 1) + j) * 2;
                (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
                (*texCoords)[texIndex + 1] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
        for (int i = 0; i < numParallels ; i++) {
            for (int j = 0; j < numSlices; j++) {
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                *indexBuf++ = i * (numSlices + 1) + (j + 1);
            }
        }
    }
    
    if (numVertices_out) {
        *numVertices_out = numVertices;
    }
    
    return numIndices;
}

#pragma mark - MotionAndPanorama

@interface MotionAndPanorama ()
{
    GLuint _indexCount;
    GLuint _indicesVBO;
    GLuint _verticesVBO;
    GLuint _texturesVBO;
    
    GLuint _program;
    GLuint _vertexLocation;
    GLuint _textureCoordinate;
    GLuint _viewMatrixLocation;
    GLuint _projectionMatrixLocation;
    
    GLKTextureInfo *_textureInfo;
    
    GLuint _indicatorProgram;
    GLuint _indicatorVertexLocation;
    GLuint _indicatorColorLocation;
    GLuint _indicatorViewMatrixLocation;
    GLuint _indicatorProjectionMatrixLocation;
}

@property (nonatomic, strong) EAGLContext *currentContext;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@property (nonatomic, assign) double panX;
@property (nonatomic, assign) double panY;
@property (nonatomic, assign) double scale;

@end

@implementation MotionAndPanorama

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self buildMotionAndPanoView];
    }
    return self;
}

- (void)buildMotionAndPanoView {
    [self initOpenGLES];
    
    [self initMotionManager];
    
    [self initGestures];
    
    [self startMotion];
}

- (void)dealloc {
    
}

- (void)initOpenGLES {
    self.currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [self setDrawableColorFormat:GLKViewDrawableColorFormatRGB565];
    [self setDrawableDepthFormat:GLKViewDrawableDepthFormat24];
    
    self.context = self.currentContext;
    [EAGLContext setCurrentContext:self.context];
}

- (void)initMotionManager {
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager setDeviceMotionUpdateInterval:1.0/60.0];
}

- (void)initGestures {
    self.panGesture =[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self addGestureRecognizer:self.panGesture];
    
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureAction:)];
    [self addGestureRecognizer:self.pinchGesture];
    self.scale = 1.0;
}

#pragma mark - Draw

- (void)initIndicatorShader {
    NSString *vertexShader = @"precision highp float;\n\
    attribute vec3 aVertex;\n\
    attribute vec4 aColor;\n\
    uniform mat4 aViewMatrix;\n\
    uniform mat4 aProjectionMatrix;\n\
    varying vec4 color;\n\
    void main(){\n\
    gl_Position = aProjectionMatrix * aViewMatrix * vec4(aVertex, 1.0);\n\
    color = aColor;\n\
    }";
    
    NSString *fragmentShader = @"precision highp float;\n\
    varying vec4 color;\n\
    void main(){\n\
    gl_FragColor = color;\n\
    }";
    
    _indicatorProgram = glCreateProgram();
    
    GLuint vShader = glCreateShader(GL_VERTEX_SHADER);
    GLuint fShader = glCreateShader(GL_FRAGMENT_SHADER);
    
    GLint vLength = (GLint)[vertexShader length];
    GLint fLength = (GLint)[fragmentShader length];
    const GLchar *vByte = [vertexShader UTF8String];
    const GLchar *fByte = [fragmentShader UTF8String];
    
    glShaderSource(vShader, 1, &vByte, &vLength);
    glShaderSource(fShader, 1, &fByte, &fLength);
    
    glCompileShader(vShader);
    glCompileShader(fShader);
    
    glAttachShader(_indicatorProgram, vShader);
    glAttachShader(_indicatorProgram, fShader);
    
    glLinkProgram(_indicatorProgram);
    
    _indicatorVertexLocation = glGetAttribLocation(_indicatorProgram, "aVertex");
    _indicatorColorLocation = glGetAttribLocation(_indicatorProgram, "aColor");
    _indicatorViewMatrixLocation = glGetUniformLocation(_indicatorProgram, "aViewMatrix");
    _indicatorProjectionMatrixLocation = glGetUniformLocation(_indicatorProgram, "aProjectionMatrix");
}

- (void)initShader {
    NSString *vertexShader = @"precision highp float;\n\
    attribute vec3 aVertex;\n\
    attribute vec2 aTextureCoord;\n\
    uniform mat4 aViewMatrix;\n\
    uniform mat4 aProjectionMatrix;\n\
    varying vec2 texture;\n\
    void main(){\n\
    gl_Position = aProjectionMatrix * aViewMatrix * vec4(aVertex, 1.0);\n\
    texture = aTextureCoord;\n\
    }";
    
    NSString *fragmentShader = @"precision highp float;\n\
    varying vec2 texture;\n\
    uniform sampler2D aTextureUnit0;\n\
    void main(){\n\
    gl_FragColor = texture2D(aTextureUnit0, texture);\n\
    }";
    
    _program = glCreateProgram();
    
    GLuint vShader = glCreateShader(GL_VERTEX_SHADER);
    GLuint fShader = glCreateShader(GL_FRAGMENT_SHADER);
    
    GLint vLength = (GLint)[vertexShader length];
    GLint fLength = (GLint)[fragmentShader length];
    const GLchar *vByte = [vertexShader UTF8String];
    const GLchar *fByte = [fragmentShader UTF8String];
    
    glShaderSource(vShader, 1, &vByte, &vLength);
    glShaderSource(fShader, 1, &fByte, &fLength);
    
    glCompileShader(vShader);
    glCompileShader(fShader);
    
    glAttachShader(_program, vShader);
    glAttachShader(_program, fShader);
    
    glLinkProgram(_program);
    
    _vertexLocation = glGetAttribLocation(_program, "aVertex");
    _textureCoordinate = glGetAttribLocation(_program, "aTextureCoord");
    _viewMatrixLocation = glGetUniformLocation(_program, "aViewMatrix");
    _projectionMatrixLocation = glGetUniformLocation(_program, "aProjectionMatrix");
}

- (void)initVBO {
    GLfloat *vertices;
    GLfloat *textureCoords;
    GLushort *indices;
    GLint vertexCount;
    _indexCount = esGenSphere(360, 1.0, &vertices, &textureCoords, &indices, &vertexCount);
    
    /// 索引数据
    glGenBuffers(1, &_indicesVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indicesVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort)*_indexCount, indices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    /// 顶点数据
    glGenBuffers(1, &_verticesVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _verticesVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*vertexCount*3, vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    /// 纹理数据
    glGenBuffers(1, &_texturesVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texturesVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*vertexCount*2, textureCoords, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    if (indices != NULL) free(indices);
    if (vertices != NULL) free(vertices);
    if (textureCoords != NULL) free(textureCoords);
}

- (void)initTexture {
    NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"texturify_pano-3" ofType:@"jpg"];
    /// 由于OpenGL的默认坐标系设置在左下角, 而GLKit在左上角, 因此需要转换
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil];
    _textureInfo = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:nil];
}

- (void)drawRect:(CGRect)rect {
    if (_textureInfo == nil) {
        [self initTexture];
    }
    
    if (_program == 0) {
        [self initShader];
        [self initVBO];
    }
    
    /// 创建投影矩阵
    double fovy = MIN(1000/180.0*M_PI, MAX(50/180.0*M_PI, 90/180.0*M_PI/self.scale));
    float aspect = fabs(rect.size.width / rect.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fovy, aspect, 0.1f, 100.f);/// 构造平截头体
    
    /// 创建模型矩阵
    CMAttitude *attitude = self.motionManager.deviceMotion.attitude;
    double w = attitude.quaternion.w;
    double wx = attitude.quaternion.x;
    double wy = attitude.quaternion.y;
    double wz = attitude.quaternion.z;
    //NSLog(@"w = %f, wx = %f, wy = %f, wz = %f", w, wx, wy,wz);
    
    /// CoreMotion返回的四元数表示手机(eye/camera)的姿态，将这个四元数应用的modelViewMatrix上的时候需要注意旋转方向的问题，so，也可以使用:GLKQuaternionMake(-wx, -wy, -wz, w);
    GLKQuaternion quaternion = GLKQuaternionMake(wx, wy, wz, -w);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(quaternion);
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;/// 注意矩阵变为左乘，操作矩阵需要逆序
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, M_PI_2);/// 为了保证在手机水平放置(eye向-z轴)的时候看到地板, 因此首先将object沿着x轴旋转90度
    /// CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
//    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, -0.01*self.panY);/// 屏幕像素向右为正, 而object在Y轴逆时针旋转为正
//    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, -0.01*self.panX);/// 屏幕像素向下为正, 而object在X轴逆时针旋转为正
    /// CMAttitudeReferenceFrameXTrueNorthZVertical
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, -0.01*self.panY);/// 屏幕像素向右为正, 而object在Y轴逆时针旋转为正
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, -0.01*self.panX);/// 屏幕像素向下为正, 而object在X轴逆时针旋转为正
    
    /// 执行全景图
    glUseProgram(_program);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindTexture(GL_TEXTURE_2D, _textureInfo.name);
    
    glBindBuffer(GL_ARRAY_BUFFER, _verticesVBO);
    glEnableVertexAttribArray(_vertexLocation);
    glVertexAttribPointer(_vertexLocation, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, _texturesVBO);
    glEnableVertexAttribArray(_textureCoordinate);
    glVertexAttribPointer(_textureCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
    
    glUniformMatrix4fv(_viewMatrixLocation, 1, GL_FALSE, (GLfloat *)&modelViewMatrix);
    glUniformMatrix4fv(_projectionMatrixLocation, 1, GL_FALSE, (GLfloat *)&projectionMatrix);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indicesVBO);
    glDrawElements(GL_TRIANGLES, _indexCount, GL_UNSIGNED_SHORT, 0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glDisableVertexAttribArray(_vertexLocation);
    glDisableVertexAttribArray(_textureCoordinate);
    
    glUseProgram(0);
    
    
    /// 绘制一个立方体
    GLfloat vertices[] = {
        -0.5f, -0.5f, 0.5f, 1.0, 0.0, 0.0, 0.5,     // red
        -0.5f, 0.5f, 0.5f, 1.0, 1.0, 0.0, 0.5,      // yellow
        0.5f, 0.5f, 0.5f, 0.0, 0.0, 1.0, 0.5,       // blue
        0.5f, -0.5f, 0.5f, 1.0, 1.0, 1.0, 0.5,      // white
        
        0.5f, -0.5f, -0.5f, 1.0, 1.0, 0.0, 0.5,     // yellow
        0.5f, 0.5f, -0.5f, 1.0, 0.0, 0.0, 0.5,      // red
        -0.5f, 0.5f, -0.5f, 1.0, 1.0, 1.0, 0.5,     // white
        -0.5f, -0.5f, -0.5f, 0.0, 0.0, 1.0, 0.5,    // blue
    };
    
    GLubyte indices[] = {
        0, 3, 2, 0, 2, 1,   // Front face
        7, 5, 4, 7, 6, 5,   // Back face
        0, 1, 6, 0, 6, 7,   // Left face
        3, 4, 5, 3, 5, 2,   // Right face
        1, 2, 5, 1, 5, 6,   // Up face
        0, 7, 4, 0, 4, 3,   // Down face
    };
    
    if (_indicatorProgram == 0) {
        [self initIndicatorShader];
    }
    
    glUseProgram(_indicatorProgram);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glVertexAttribPointer(_indicatorVertexLocation, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), vertices);
    glVertexAttribPointer(_indicatorColorLocation, 4, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), vertices + 3);
    glEnableVertexAttribArray(_indicatorVertexLocation);
    glEnableVertexAttribArray(_indicatorColorLocation);
    
    GLKMatrix4 indicatorProjectionMatrix = projectionMatrix;
    
    GLKQuaternion indicatorQuaternion = GLKQuaternionMake(wx, wy, wz, -w);
    GLKMatrix4 indicatorRotation = GLKMatrix4MakeWithQuaternion(indicatorQuaternion);
    
    GLKMatrix4 indicatorModelViewMatrix = GLKMatrix4Identity;
    indicatorModelViewMatrix = GLKMatrix4Multiply(indicatorModelViewMatrix, indicatorRotation);
    indicatorModelViewMatrix = GLKMatrix4Translate(indicatorModelViewMatrix, 0, -5, 1);/// 在-y轴绘(即正东方向)制立方体
    indicatorModelViewMatrix = GLKMatrix4RotateY(indicatorModelViewMatrix, 0.01*self.panY);
    indicatorModelViewMatrix = GLKMatrix4RotateZ(indicatorModelViewMatrix, 0.01*self.panX);
    
    glUniformMatrix4fv(_indicatorViewMatrixLocation, 1, GL_FALSE, (GLfloat *)&indicatorModelViewMatrix);
    glUniformMatrix4fv(_indicatorProjectionMatrixLocation, 1, GL_FALSE, (GLfloat *)&indicatorProjectionMatrix);
    
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
    
    glDisableVertexAttribArray(_indicatorVertexLocation);
    glDisableVertexAttribArray(_indicatorColorLocation);
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);
    
    glUseProgram(0);
    
    
    /// 绘制坐标轴
    GLfloat axisVertices[] = {
        -5.0f, 0.0f, 0.0f, 1.0, 0.0, 0.0, 1.0,
        5.0f, 0.0f, 0.0f, 1.0, 0.0, 0.0, 1.0,
        4.0f, 1.0f, 0.0f, 1.0, 0.0, 0.0, 1.0,
        4.0f, -1.0f, 0.0f, 1.0, 0.0, 0.0, 1.0,
        
        0.0f, -5.0f, 0.0f, 0.0, 1.0, 0.0, 1.0,
        0.0f, 5.0f, 0.0f, 0.0, 1.0, 0.0, 1.0,
        1.0f, 4.0f, 0.0f, 0.0, 1.0, 0.0, 1.0,
        -1.0f, 4.0f, 0.0f, 0.0, 1.0, 0.0, 1.0,
        
        0.0f, 0.0f, -5.0f, 0.0, 0.0, 1.0, 1.0,
        0.0f, 0.0f, 5.0f, 0.0, 0.0, 1.0, 1.0,
    };
    
    GLubyte axisIndices[] = {
        0, 1, 1, 2, 1, 3,
        4, 5, 5, 6, 5, 7,
        8, 9,
    };
    
    glUseProgram(_indicatorProgram);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glVertexAttribPointer(_indicatorVertexLocation, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), axisVertices);
    glVertexAttribPointer(_indicatorColorLocation, 4, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), axisVertices + 3);
    glEnableVertexAttribArray(_indicatorVertexLocation);
    glEnableVertexAttribArray(_indicatorColorLocation);
    
    GLKMatrix4 axisProjectionMatrix = projectionMatrix;
    
    GLKQuaternion axisQuaternion = GLKQuaternionMake(wx, wy, wz, -w);
    GLKMatrix4 axisRotation = GLKMatrix4MakeWithQuaternion(axisQuaternion);
    
    GLKMatrix4 axisModelViewMatrix = GLKMatrix4Identity;
    axisModelViewMatrix = GLKMatrix4Multiply(axisModelViewMatrix, axisRotation);
    axisModelViewMatrix = GLKMatrix4Translate(axisModelViewMatrix, 0, 0, -10);/// 在地面绘制坐标轴
    
    glUniformMatrix4fv(_indicatorViewMatrixLocation, 1, GL_FALSE, (GLfloat *)&axisModelViewMatrix);
    glUniformMatrix4fv(_indicatorProjectionMatrixLocation, 1, GL_FALSE, (GLfloat *)&axisProjectionMatrix);
    
    glLineWidth(6.0);
    glDrawElements(GL_LINES, sizeof(axisIndices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, axisIndices);
    
    glDisableVertexAttribArray(_indicatorVertexLocation);
    glDisableVertexAttribArray(_indicatorColorLocation);
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_BLEND);
    
    glUseProgram(0);
}

#pragma mark - Interface

- (void)startRenderer {
    if (self.displayLink == nil) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setNeedsDisplay)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopRenderer {
    if (self.displayLink != nil) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)startMotion {
    if (!self.motionManager.deviceMotionActive) {
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    }
}

- (void)stopMotion {
    if (self.motionManager.deviceMotionActive) {
        [self.motionManager startDeviceMotionUpdates];
    }
}

#pragma mark - Gesture Action

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture {
    CGPoint point = [panGesture translationInView:self];
    self.panX += point.x;
    self.panY += point.y;
    
    [panGesture setTranslation:CGPointZero inView:self];
}

- (void)pinchGestureAction:(UIPinchGestureRecognizer *)pinchGesture {
    if (pinchGesture.state == UIGestureRecognizerStateBegan) {
        pinchGesture.scale = self.scale;
    }
    else if (pinchGesture.state == UIGestureRecognizerStateChanged) {
        self.scale = pinchGesture.scale;
    }
}

@end
