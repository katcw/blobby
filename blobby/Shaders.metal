//
//  Shaders.metal
//  blobby
//
//  Created by kalen •ᴗ•  on 21/8/26.
//

#include <metal_stdlib>
#import "ShaderTypes.h"

using namespace metal;

// vertex input
struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

// vertex output and fragment shader input
struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
};

/**
 the vertex shader responsible for taking a point from the local model space and
 determining its location on screen
*/
vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    VertexOut out;
    
    // place vertex in world
    float4 worldPosition = u.modelMatrix * float4(in.position, 1.0);
     
    // convert from world space to camera-relative space, then apply perspective
    out.position = u.projectionMatrix * u.viewMatrix * worldPosition;
    
    // rotate normal
    out.worldNormal = normalize((u.modelMatrix * float4(in.normal, 0.0)).xyz);
    
    return out;
}

/**
 the fragment shader responsible for determining the colour
 for each pixel
*/
fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    // surface direction at this pixel
    float3 N = normalize(in.worldNormal);
    
    // direction towards the light source
    float3 L = normalize(float3(0.5, 0.8, 1.0));
    
    /**
     measures how much of the surface faces the light,
     clamp to 0 since there is no "negative light"
    */
    float diffuse = max(dot(N, L), 0.0);
    
    // flat base colour to apply to pixel
    float3 baseColour = float3(0.961, 0.961, 0.863);
    
    // ambient colour and scaling factor for diffuse
    float ambient = 0.2;
    float diffuseScaleFactor = 0.8;
    
    // scaled colour based on ambient and diffuse
    float3 colour = baseColour * (ambient + diffuseScaleFactor * diffuse);
    
    return float4(colour, 1.0);
  
}
