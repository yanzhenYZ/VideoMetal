//
//  YZProgram.m
//  test
//
//  Created by Work on 2019/8/29.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "YZProgram.h"

@implementation YZProgram
- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString;
{
    if ((self = [super init]))
    {
        _initialized = NO;
        
        attributes = [[NSMutableArray alloc] init];
        uniforms = [[NSMutableArray alloc] init];
//111111
        program = glCreateProgram();
//222222
        if (![self compileShader:&vertShader type:GL_VERTEX_SHADER string:vShaderString])
        {
            NSLog(@"Failed to compile vertex shader");
        }
//333333
        // Create and compile fragment shader
        if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:fShaderString])
        {
            NSLog(@"Failed to compile fragment shader");
        }
//444444
        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);
    }
    
    return self;
}

// END:init
// START:compile
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString
{
    //    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            if (shader == &vertShader)
            {
                self.vertexShaderLog = [NSString stringWithFormat:@"%s", log];
            }
            else
            {
                self.fragmentShaderLog = [NSString stringWithFormat:@"%s", log];
            }
            
            free(log);
        }
    }
    return status == GL_TRUE;
}
// END:compile
#pragma mark -
// START:addattribute
- (void)addAttribute:(NSString *)attributeName
{
    if (![attributes containsObject:attributeName])
    {
        [attributes addObject:attributeName];
//444444
        glBindAttribLocation(program, (GLuint)[attributes indexOfObject:attributeName], [attributeName UTF8String]);
    }
}
// END:addattribute
// START:indexmethods
- (GLuint)attributeIndex:(NSString *)attributeName
{
    return (GLuint)[attributes indexOfObject:attributeName];
}
- (GLuint)uniformIndex:(NSString *)uniformName
{
    return glGetUniformLocation(program, [uniformName UTF8String]);
}
// END:indexmethods
#pragma mark -
// START:link
- (BOOL)link
{
//555555
    GLint status;
    
    glLinkProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        return NO;
    
    if (vertShader)
    {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    self.initialized = YES;
    
    return YES;
}
// END:link
// START:use
- (void)use
{
    glUseProgram(program);
}
// END:use
#pragma mark -

- (void)validate;
{
    GLint logLength;
    
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        self.programLog = [NSString stringWithFormat:@"%s", log];
        free(log);
    }
}

#pragma mark -
// START:dealloc
- (void)dealloc
{
    if (vertShader)
        glDeleteShader(vertShader);
    
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (program)
        glDeleteProgram(program);
    
}
// END:dealloc
@end
