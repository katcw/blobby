//
//  MorphController.swift
//  blobby
//
//  Created by kalen •ᴗ•  on 22/8/26.
//

import Foundation

/**
 owns the blob's horizontal morph offset and its momentum.
 it is shared between the swiftui gesture layer and the renderer
 */
final class MorphController {
    /**
     accumulated horizontal offset into the noise field
     this is what the shader reads
     */
    private(set) var horizontalOffset: Float = 0
    
    // current morph speed, in offset units per second
    private var velocity: Float = 0
    
    // the offset the moment the current drag begins
    private var dragStartHorizontalOffset: Float = 0
    
    // true while finger is down
    private var isDragging = false
    
    // drag sensitivity
    private let sensitivity: Float = 0.002
    
    // momentum friction control
    private let friction: Float = 1.5
    
    // speed's lower bound such that any speed below this is snapped to a stop
    private let restSpeed: Float = 0.0005
    
    /// when a finger touch is registered, remember where it started
    /// and kill any glide that is in progress
    func beginDrag() {
        isDragging = true;
        dragStartHorizontalOffset = horizontalOffset
        velocity = 0;
    }
    
    /// when a finger is moving/dragging across
    ///
    /// - parameter translation: total horizontal drag distance in screen points for this drag only
    func updateDrag(translation: Float) {
        horizontalOffset = dragStartHorizontalOffset + translation * sensitivity
    }
    
    /// when a finger is lifted, converts the release speed into morph momentum
    ///
    /// - parameter screenVelocity: horizontal gesture velocity in screen points per second
    func endDrag(velocity screenVelocity: Float) {
        isDragging = false;
        velocity = screenVelocity * sensitivity
    }
    
    /// advance the glide by one frame, does nothing while a finger is pressed down
    ///
    /// - parameter deltaTime: seconds since the previous frame
    func step(deltaTime: Float) {
        guard !isDragging, velocity != 0 else { return }
        
        // advance horizontal offset by velocity
        horizontalOffset += velocity * deltaTime
        
        // shrink velocity by friction
        velocity *= exp(-friction * deltaTime)
        
        // if velocity hits our speed's lower bound, stop gliding
        if abs(velocity) < restSpeed { velocity = 0 }
    }
 }
