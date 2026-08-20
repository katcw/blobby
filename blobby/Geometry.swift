//
//  Geometry.swift
//  blobby
//
//  Created by kalen •ᴗ•  on 21/8/26.
//

import simd

/**
 describes a single point on the mesh surface
 */
struct Vertex {
    // the position in 3D space
    var position: SIMD3<Float>
    // the direction it faces
    var normal:   SIMD3<Float>
}

/**
 builds an icosphere: a sphere made of evenly-spaced triangles
 */
enum Icosphere {
    /**
     generates the sphere's geometry
     
     - parameter subdivisions: how many times to cut each triangle in 4. each step roughly quadriples the triangle count. if `subdivisons == 0`, a raw 20-sided icosphere is generated
     - returns:                a tuple of every vertex and the index buffer describing which three vertices form each triangle
     */
    static func generate(subdivisions: Int) -> (vertices: [Vertex], indices: [UInt32]) {
        // golden ratio
        let phi = Float((1.0 + sqrt(5.0)) / 2.0)
        
        // store positions of the 12 corners of a raw icosahedron using our golden ratio
        var positions: [SIMD3<Float>] = [
            [-1, phi, 0], [1, phi, 0], [-1, -phi, 0],
            [1, -phi, 0], [0, -1, phi], [0, 1, phi],
            [0, -1, -phi], [0, 1, -phi], [phi, 0, -1],
            [phi, 0, 1], [-phi, 0, -1], [-phi, 0, 1]
        ]
        
        // push each corner onto the unit sphere (of radius 1)
        for i in positions.indices {
            positions[i] = normalize(positions[i])
        }
        
        // the 20 triangular faces, as triples of indices into our positions array
        var indices: [UInt32] = [
            0, 11, 5,
            0, 5, 1,
            0, 1, 7,
            0, 7, 10,
            0, 10, 11,
            1, 5, 9,
            5, 11, 4,
            11, 10, 2,
            10, 7, 6,
            7, 1, 8,
            3, 9, 4,
            3, 4, 2,
            3, 2, 6,
            3, 6, 8,
            3, 8, 9,
            4, 9, 5,
            2, 4, 11,
            6, 2, 10,
            8, 6, 7,
            9, 8, 1,
        ]
        
        /**
         when we cut a triangle, its three edges get new midpoint vertices;
         two neighbouring triangles share an edge so we can cache midpoints to avoid creating the same vertex twice.
         the key packs the two endpoint indices into one number and produces a value
         */
        var midpointCache: [UInt64 : UInt32] = [:]
        
        /**
         returns the index of the midpoint vertex between vertices `a` and `b`, creating it once if it doesn't exist yet
         
         - parameter a: vertex `a`
         - parameter b: vertex `b`
         - returns:     the new index of the midpoint vertex between vertices `a` and `b`
         */
        func midpoint(_ a: UInt32, _ b: UInt32) -> UInt32 {
            // ensure that the smaller of a, b is always in the higher bits of the UInt64 key
            let key = a < b ? (Int64(a) << 32 | Int64(b)) : (Int64(b)) << 32 | (Int64(a))
            
            // check if a key exists in our midpoint cache, if it does then return its value
            if let existing = midpointCache[UInt64(key)] { return existing }
            
            // the raw midpoint between vertex a and b
            let raw = (positions[Int(a)] + positions[Int(b)]) * 0.5
            
            // normalise raw value
            let normalisedOnSphere = normalize(raw)
            
            // append the new normalised vertex into our vertex buffer
            positions.append(normalisedOnSphere)
            
            // register the new key and value/index into our midpoint cache
            let newIndex = UInt32(positions.count - 1)
            midpointCache[UInt64(key)] = newIndex
            
            return newIndex
        }
        
        // subdivide the whole mesh [subdivision] times
        for _ in 0..<subdivisions {
            // array of UInt32 to store our new indices
            var newIndices: [UInt32] = []
            
            /**
             since each subdivision divides a triangle into 4 smaller ones,
             we reserve `indices.count * 4` space for the new index buffer
            */
            newIndices.reserveCapacity(indices.count * 4)
            
            var i = 0
            // loop through the index buffer
            while i < indices.count {
                // get three vertexes a, b and c
                let a = indices[i], b = indices[i + 1], c = indices[i + 2]
                
                // calculate the midpoint vertex for all three edges
                let ab = midpoint(a, b), bc = midpoint(b, c), ca = midpoint(c, a)
                
                // append the new indices of our smaller, subdivided triangles in newIndices
                newIndices += [a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca]
                i += 3
            }
            
            // store newIndices into indices
            indices = newIndices
        }
        
        /**
         map each element in `positions` into a `Vertex` object which stores a `position` and `normal`
         `normal == position` because it's a unit sphere
         */
        let vertices = positions.map{ Vertex(position: $0, normal: $0)}
        
        return(vertices, indices)
    }
}
