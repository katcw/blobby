//
//  Renderer.swift
//  blobby
//
//  Created by kalen •ᴗ•  on 20/8/26.
//

import MetalKit

/**
 our `Renderer` object is responsible for building up a list of instructions for our gpu to execute
 each time our screen is refreshed
 */
final class Renderer: NSObject, MTKViewDelegate {
    // private variable to store our device
    private let device: MTLDevice
    // private variable to store our queue/line of gpu instructions
    private let commandQueue: MTLCommandQueue
    
    /**
     similar to a constructor in c++,
     this executes when a `Renderer` object is created
     
     - parameter device: a reference to the device's gpu
     */
    init(device: MTLDevice) {
        // store our passed device
        self.device = device
        // instruct the gpu to create a command queue
        guard let queue = device.makeCommandQueue()
        else { fatalError("could not create a metal command queue :(") }
        // store the created queue
        self.commandQueue = queue
        
        let mesh = Icosphere.generate(subdivisions: 4)
        print("vertices: \(mesh.vertices.count), triangles: \(mesh.indices.count / 3)")
        
        super.init()
    }
    
    /**
     called automatically whenever the size of the drawable area changes (e.g., when the window is resized or rotated); used to update anything that depends on the view's pixel dimensions
     
     - parameter view: the current `MTKView` whose size just changed
     - parameter size: the new size of the drawable in pixels
     */
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    /**
     called automatically by the view each time a new frame needs to be drawn
     
     - parameter view: the current `MTKView` that needs to be redrawn
     */
    func draw(in view: MTKView) {
        // start a fresh queue of gpu instructions for this frame
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              // get the settings for this frame
              let passDescriptor = view.currentRenderPassDescriptor,
              // get an encoder that allows us to input render commands into the queue, following our passDescriptor settings
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor),
              // get the image buffer on screen
              let drawable = view.currentDrawable
        // if anyone one of the four fails, we skip this frame instead of crashing
        else { return }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
