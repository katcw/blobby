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
    
    // translates world space into camera's view
    matrix_float4x4 viewMatrix;
    
    // camera's position in world space
    vector_float3 cameraPosition;
    
    // projecting from 3d space to screen's 2d space
    matrix_float4x4 projectionMatrix;
    
    // random offset in the simplex noise field per launch
    vector_float3 seed;
    
    // seconds since launch, used for animations
    float time;
    
    // accumulated horizontal drag offset
    float horizontalMorphOffset;
} Uniforms;
