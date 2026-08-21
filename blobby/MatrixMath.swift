//
//  MatrixMath.swift
//  blobby
//
//  Created by kalen •ᴗ•  on 21/8/26.
//

import simd

extension matrix_float4x4 {

    /**
     builds a perspective projection matrix that projects from 3d to a flat 2d space
     
     - parameter fovRadians: vertical field of view in radians; zoom
     - parameter aspect:     view width / height aspect ratio
     - parameter near:       closest visible distance
     - parameter far:        furthest visible distance
     */
    init(perspectiveFOV fovRadians: Float, aspect: Float, near: Float, far: Float) {
        let ys = 1 / tan(fovRadians * 0.5)
        let xs = ys / aspect
        let zs = far / (near - far)
        
        // note! simd matrices are column-major: each simd4 below is one column
        self.init(SIMD4<Float>(xs, 0,  0,        0),
                  SIMD4<Float>(0,  ys, 0,        0),
                  SIMD4<Float>(0,  0,  zs,      -1),
                  SIMD4<Float>(0,  0,  zs * near, 0))
    }

    /**
     builds a translation matrix that moves/translates objects by `t`
     
     - parameter t: `x`, `y` and `z` values to translate
     */
    init(translation t: SIMD3<Float>) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(t.x, t.y, t.z, 1))
    }

    /**
     builds a rotation matrix that rotates around the vertical axis by `angle` radians
     
     - parameter angle: angle in radians to rotate around the vertical axis
     */
    init(rotationY angle: Float) {
        let c = cos(angle), s = sin(angle)
        self.init(SIMD4<Float>(c, 0, -s, 0),
                  SIMD4<Float>(0, 1,  0, 0),
                  SIMD4<Float>(s, 0,  c, 0),
                  SIMD4<Float>(0, 0,  0, 1))
    }
}
