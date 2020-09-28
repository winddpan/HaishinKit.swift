//
//  STGLPreview.h
//
//  Created by sluin on 2017/1/11.
//  Copyright © 2017年 SenseTime. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreMedia/CoreMedia.h>

@interface STGLPreview : UIView

@property (nonatomic , strong) EAGLContext *glContext;
@property (nonatomic , assign) BOOL mirrored;

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context;

- (void)renderTexture:(GLuint)texture;
- (void)renderSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
