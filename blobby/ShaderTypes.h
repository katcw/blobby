//
//  ShaderTypes.h
//  blobby
//
//  Created by kalen •ᴗ•  on 21/8/26.
//

#pragma once

#include <simd/simd.h>

typedef struct {
    // blob's position
    matrix_float4x4 modelMatrix;
    
    // camera's position
    matrix_float4x4 viewMatrix;
    
    // projecting from 3d space to screen's 2d space
    matrix_float4x4 projectionMatrix;
    
    // seconds since launch, used for animations
    float time;
} Uniforms;
