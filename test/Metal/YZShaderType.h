//
//  YZShaderType.h
//  test
//
//  Created by 闫振 on 2020/12/1.
//  Copyright © 2020 yanzhen. All rights reserved.
//

#ifndef YZShaderType_h
#define YZShaderType_h

#include <simd/simd.h>

typedef struct {
    //顶点坐标(x,y,z,w)
    vector_float4 position;
    //纹理坐标(s,t)
    vector_float2 textureCoordinate;
} YZVertex;

//转换矩阵
typedef struct {
    //三维矩阵
    matrix_float3x3 matrix;
    //偏移量
    vector_float3 offset;
} YZConvertMatrix;

//顶点函数输入索引
typedef enum YZVertexInputIndex {
    YZVertexInputIndexVertices = 0,
} YZVertexInputIndex;

//片元函数缓存区索引
typedef enum YZFragmentBufferIndex
{
    YZFragmentInputIndexMatrix = 0,
} YZFragmentBufferIndex;

//片元函数纹理索引
typedef enum YZFragmentTextureIndex
{
    YZFragmentTextureIndexTextureY  = 0,
    YZFragmentTextureIndexTextureUV = 1,
} YZFragmentTextureIndex;


#endif /* YZShaderType_h */
