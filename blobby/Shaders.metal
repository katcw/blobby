//
//  Shaders.metal
//  blobby
//
//  Created by kalen •ᴗ•  on 21/8/26.
//

#include <metal_stdlib>
#include "SimplexNoise.h"
#import "ShaderTypes.h"

using namespace metal;

// MARK: vertex input
struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
};

// MARK: vertex output, fragment shader input
struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
};

// MARK: other shaders

/**
 looping rgb gradient using inigo quilez's procedural cosine palette,
 maps `t` to a colour built from cosine waves so it flows smoothly
 
 - parameter t: position along the colour gradient
*/
float3 iridescentPalette(float t) {
    // the middle colour the gradient oscillates around per channel
    float3 averageTint      = float3(0.62, 0.52, 0.80);
    
    // amplitude of per channel cosine wave
    float3 colourAmplitude  = float3(0.33, 0.26, 0.12);
    
    // the number of times the gradient cycles
    float3 colourFrequency  = float3(1.00, 1.00, 1.00);
    
    // shifts which colours land along t
    float3 colourPhase      = float3(0.00, 0.50, 0.02);
    
    return averageTint + colourAmplitude * cos(6.28318 * (colourFrequency * t + colourPhase));
}

float genesisDisplacement(float3 position, float time, float3 seed) {
    /**
     frequency of deformations across the sphere
     the higher the frequency, the more deformations across the sphere
     */
    float frequency = 0.45;
    
    /**
     how high or deep the deformations peak/dent
     the higher the amplitude, the higher and deeper the deformations are
     */
    float amplitude = 0.5;
    
    // idle morph speed
    float driftSpeed = 0.15;
    
    float drift = time * driftSpeed;
    
    /**
     slide the point across the simplex noise field over time
     this allows the blob to morph over time
    */
    float n = snoise(position * frequency + seed + float3(0.0, drift, 0.0));
    
    // return in range ~[-amplitude, amplitude], either pull or push
    return n * amplitude;
}

/**
 where a point on the base sphere ends up after being displaced by `GenesisDisplacement`
 
 // random offset in the simplex noise field per launch
 vector_float3 seed;
 
 // seconds since launch, used for animations

 - parameter sphereDirection: a unit length direction (a point on the base unit sphere)
 - parameter time:            seconds since launch, passed straight through the simplex noise
 - parameter seed:            random offset in the simplex noise field per launch, passed straight through the simplex noise
 
 - returns:                   the displaced point
*/
float3 displacedPoint(float3 sphereDirection, float time, float3 seed) {
    float height = genesisDisplacement(sphereDirection, time, seed);
    
    // push displacement along the normal
    return sphereDirection + sphereDirection * height;
}

/**
 the vertex shader responsible for taking a point from the local model space and
 determining its location on screen
*/
vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    VertexOut out;
    
    // MARK: placing vertex in world
    
    // MARK: apply displacement
    // base sphere normal
    float3 baseSphereNormal = in.normal;
    
    // build two directions that lie along the sphere surface, perpendicular to baseSphereNormal
    float3 helper = abs(baseSphereNormal.y) < 0.99 ? float3(0, 1, 0) : float3(1, 0, 0);
    float3 tangent = normalize(cross(helper, baseSphereNormal));
    float3 bitangent = cross(baseSphereNormal, tangent);
     
    /**
     step to both sides along each tangent,
     this produces a symmetric, low-noise normal
    */
    float sampleStep = 0.1;
    
    float3 pTp = displacedPoint(normalize(baseSphereNormal + tangent * sampleStep),   u.time, u.seed);
    float3 pTm = displacedPoint(normalize(baseSphereNormal - tangent * sampleStep),   u.time, u.seed);
    float3 pBp = displacedPoint(normalize(baseSphereNormal + bitangent * sampleStep), u.time, u.seed);
    float3 pBm = displacedPoint(normalize(baseSphereNormal - bitangent * sampleStep), u.time, u.seed);

    // the cross product of two surface edges produces a normal perpendicular to the surface
    float3 newNormal = normalize(cross((pTp - pTm), (pBp - pBm)));

    float3 displacedPosition = displacedPoint(baseSphereNormal, u.time, u.seed);

    // feed displaced point into the model matrix
    float4 worldPosition = u.modelMatrix * float4(displacedPosition, 1.0);
    
    // pass vertex world space position
    out.worldPosition = worldPosition.xyz;
    
    // convert from world space to camera-relative space, then apply perspective
    out.position = u.projectionMatrix * u.viewMatrix * worldPosition;
    
    // rotate normal
    out.worldNormal = normalize((u.modelMatrix * float4(newNormal, 0.0)).xyz);
    
    return out;
}

/**
 the fragment shader responsible for determining the colour for each pixel
 incorporates fresnel computation
*/
fragment float4 fragment_main(VertexOut in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    // surface direction at this pixel
    float3 N = normalize(in.worldNormal);
    
    // direction from the current pixel towards the camera
    float3 V = normalize(u.cameraPosition - in.worldPosition);
    
    /**
     compute how much the current pixel faces the camera:
     1.0 = pixels faces straight at the camera, 0.0 = pixel is at the edge, not facing the camera
    */
    float facing = clamp(dot(N, V), 0.0, 1.0);
    
    /**
     computes the fresnel where our viewing angle affects light reflectivity:
     ~0 (reflectivity) = when we look straight at the surface,
     ~1 (reflectivity) = when we look at its edge
    */
    // a higher reflectivity exponent restricts the edge glow, works conversely
    float reflectivityExponent = 3.0;
    float fresnel = pow(1.0 - facing, reflectivityExponent);
    
    // how much surface direction drives colour
    const float spatialWeight     = 0.6;
    // how much the view angle shifts the hue
    const float iridescenceWeight = 0.4;
    // speed of colour shift while idle, driven by time
    const float shimmerSpeed      = 0.03;

    /**
     spatial flow:
     0 = bottom of the blob, 1 = top of the blob
     */
    float spatial = 0.5 + 0.5 * N.y;
    
    // iridescent palette input t
    float t = spatial * spatialWeight
            + fresnel * iridescenceWeight
            + u.time  * shimmerSpeed;
    
    // feed iridescent palette and obtain colour
    float3 colour = iridescentPalette(t);
    
    return float4(colour, 1.0);
    //MARK: temporary, show fresnel as greyscale so we can verify before adding colour
//    return float4(float3(fresnel), 1.0);
    
// MARK: deprecated solid colour
//    // direction towards the light source
//    float3 L = normalize(float3(0.5, 0.8, 1.0));
//    
//    /**
//     measures how much of the surface faces the light,
//     clamp to 0 since there is no "negative light"
//    */
//    float diffuse = max(dot(N, L), 0.0);
//    
//    // flat base colour to apply to pixel
//    float3 baseColour = float3(0.961, 0.961, 0.863);
//    
//    // ambient colour and scaling factor for diffuse
//    float ambient = 0.2;
//    float diffuseScaleFactor = 0.8;
//    
//    // scaled colour based on ambient and diffuse
//    float3 colour = baseColour * (ambient + diffuseScaleFactor * diffuse);
//    
//    return float4(colour, 1.0);
}
