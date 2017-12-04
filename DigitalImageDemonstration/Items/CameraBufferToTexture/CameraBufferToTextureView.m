//
//  CameraBufferToTextureView.m
//  DigitalImageDemonstration
//
//  Created by liubo on 2017/11/29.
//  Copyright © 2017年 devliubo. All rights reserved.
//

#import "CameraBufferToTextureView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

static const float textureCoordinates[] = {
    0, 1,
    1, 1,
    1, 0,
    0, 0,
};

static const float drawPoints[] = {
    -1, -1, 0,
    1, -1, 0,
    1,  1, 0,
    -1,  1, 0,
};

@interface CameraBufferToTextureView()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    GLuint _program;
    GLuint _vertexLocation;
    GLuint _viewMatrixLocation;
    GLuint _projectionMatrixLocation;
    GLuint _textureCoordinate;
    GLuint _colorLocation;
    
    GLuint _placeholderTextureID;
    CVOpenGLESTextureRef _captureTexture;
    CVOpenGLESTextureCacheRef _captureTextureCache;
}

@property (nonatomic, strong) EAGLContext *currentContext;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) AVCaptureSession *session;

@end

@implementation CameraBufferToTextureView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self buildRenderer];
    }
    return self;
}

- (void)dealloc {
    [self stopRenderer];
    
    [self cleanUpTextures];
    
    [self deleteTextureWithID:&_placeholderTextureID];
}

- (void)buildRenderer {
    _placeholderTextureID = 0;
    
    [self initOpenGLES];
}

- (void)initOpenGLES {
    self.currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [self setDrawableColorFormat:GLKViewDrawableColorFormatRGB565];
    [self setDrawableDepthFormat:GLKViewDrawableDepthFormat24];
    
    self.context = self.currentContext;
    [EAGLContext setCurrentContext:self.context];
}

- (void)startRenderer {
    if (self.displayLink == nil) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setNeedsDisplay)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        [self startCaptureSession];
    }
}

- (void)stopRenderer {
    if (self.displayLink != nil) {
        [self stopCaptureSession];
        
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

#pragma mark - Texture

- (void)deleteTextureWithID:(GLuint *)textureID {
    if (*textureID > 0) {
        glDeleteTextures(1, textureID);
        *textureID = 0;
    }
}

- (void)cleanUpTextures
{
    if (_captureTexture) {
        CFRelease(_captureTexture);
        _captureTexture = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(_captureTextureCache, 0);
}

- (GLuint)getTextureID {
    if (_captureTexture != NULL) {
        return CVOpenGLESTextureGetName(_captureTexture);
    }
    else {
        return _placeholderTextureID;
    }
}

#pragma mark - OpenGL

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
    uniform vec4 aColor;\n\
    void main(){\n\
    gl_FragColor = texture2D(aTextureUnit0, texture) * aColor;\n\
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
    _colorLocation = glGetUniformLocation(_program, "aColor");
}

- (void)drawRect:(CGRect)rect {
    if (_program == 0) {
        [self initShader];
        [self initCaptureTexture];
    }
    
    GLuint textureID = [self getTextureID];
    if (textureID <= 0) {
        return;
    }
    
    glUseProgram(_program);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glBlendColor(1.0f, 1.0f, 1.0f, 1.0f);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    glEnableVertexAttribArray(_vertexLocation);
    glEnableVertexAttribArray(_textureCoordinate);
    
    glVertexAttribPointer(_vertexLocation, 3, GL_FLOAT, GL_FALSE, 0, drawPoints);
    glVertexAttribPointer(_textureCoordinate, 2, GL_FLOAT, GL_FALSE, 0, textureCoordinates);
    
    glUniformMatrix4fv(_viewMatrixLocation, 1, GL_FALSE, (GLfloat *)&GLKMatrix4Identity);
    glUniformMatrix4fv(_projectionMatrixLocation, 1, GL_FALSE, (GLfloat *)&GLKMatrix4Identity);
    
    GLfloat alpha = 1.0;
    glUniform4f(_colorLocation, alpha, alpha, alpha, alpha);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDisable(GL_BLEND);
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisableVertexAttribArray(_vertexLocation);
    glDisableVertexAttribArray(_textureCoordinate);
    
    glUseProgram(0);
}

- (void)checkGLError:(NSString *)info {
    GLenum error = glGetError();
    if(error != 0) {
        NSLog(@"glGetError  %@ %d ", info, error);
    }
}

#pragma mark - Camera Capture

- (void)initCaptureTexture {
    if (_captureTextureCache == NULL) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &_captureTextureCache);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
}

- (void)startCaptureSession {
    if (self.session != nil) {
        return;
    }
    
    self.session = [[AVCaptureSession alloc] init];
    
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [self.session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setAlwaysDiscardsLateVideoFrames:YES];
    [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                         forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.session addOutput:output];
    
    [self.session commitConfiguration];
    [self.session startRunning];
}

- (void)stopCaptureSession {
    [self.session stopRunning];
    self.session = nil;
    
    [self cleanUpTextures];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self cleanUpTextures];
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    GLsizei width = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei height = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                _captureTextureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                width,
                                                                height,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &_captureTexture);
    
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_captureTexture), CVOpenGLESTextureGetName(_captureTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

@end
