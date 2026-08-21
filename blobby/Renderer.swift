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
    
    private let pipelineState: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int
    
    private var uniforms = Uniforms()
    private var aspect: Float = 1
    private let startTime = CACurrentMediaTime()
    
    // MARK: init
    /**
     similar to a constructor in c++,
     this executes when a `Renderer` object is created
     
     - parameter device: a reference to the device's gpu
     */
    init(mtkView: MTKView) {
        // get device gpu handler
        guard let device = mtkView.device,
              // instruct gpu to create a command queue
              let queue  = device.makeCommandQueue()
        else {
            fatalError("metal setup failed :(")
        }
        
        // store gpu handler and created queue
        self.device = device
        self.commandQueue = queue
        
        // MARK: [1] create and store geometry to gpu buffers
        /**
         create and store geometry to gpu buffers
         if buffers cannot be created, then terminate with `FatalError`
         */
        let mesh = Icosphere.generate(subdivisions: 5)
        guard let vBuf = device.makeBuffer(bytes: mesh.vertices, length: MemoryLayout<Vertex>.stride * mesh.vertices.count),
              let iBuf = device.makeBuffer(bytes:mesh.indices, length: MemoryLayout<UInt32>.stride * mesh.indices.count)
        else {
            fatalError("could not create geometry buffers!")
        }
        
        // store vertex, index buffers and index count
        self.vertexBuffer = vBuf
        self.indexBuffer  = iBuf
        self.indexCount   = mesh.indices.count
        
        // MARK: [2] vertex descriptor
        /**
         vertex descriptor
         how to read a vertex out of the buffer
         */
        let vertexDescriptor = MTLVertexDescriptor()
        
        // position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        
        // normal
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<Vertex>.offset(of: \.normal)!
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        // MARK: [3] compile vertex and fragment shaders
        /**
         compile vertex and fragment shaders into the pipeline
         */
        guard let library = device.makeDefaultLibrary()
        else { fatalError("could not load the default metal library") }
        
        let pipeDesc = MTLRenderPipelineDescriptor()
 
        pipeDesc.vertexFunction = library.makeFunction(name: "vertex_main")
        pipeDesc.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipeDesc.vertexDescriptor = vertexDescriptor
        pipeDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipeDesc.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipeDesc)
        
        // MARK: [4] depth test
        /**
         keeps the closest surface at each pixel
         */
        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor: depthDesc)!
        
        
        super.init()
    }
    
    // MARK: metal view
    /**
     called automatically whenever the size of the drawable area changes (e.g., when the window is resized or rotated); used to update anything that depends on the view's pixel dimensions
     
     - parameter view: the current `MTKView` whose size just changed
     - parameter size: the new size of the drawable in pixels
     */
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        aspect = Float(size.width / max(size.height, 1))
    }
    
    // MARK: draw
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
    
        // update per-frame uniforms
        let time = Float(CACurrentMediaTime() - startTime)
        // spin factor
        let spinFactor: Float = 0.4
        
        uniforms.time = time
        
        // idle spin
        uniforms.modelMatrix = matrix_float4x4(rotationY: time * spinFactor)
        
        // translate camera 3 units back
        uniforms.viewMatrix = matrix_float4x4(translation: [0, 0, -3])
        
        // project
        uniforms.projectionMatrix = matrix_float4x4(perspectiveFOV: .pi / 3,
                                                     aspect: aspect,
                                                     near: 0.1, far: 100)

        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthState)
        let ds = view.drawableSize
        encoder.setViewport(MTLViewport(originX: 0, originY: 0,
                                        width: Double(ds.width), height: Double(ds.height),
                                        znear: 0, zfar: 1))
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)

        encoder.drawIndexedPrimitives(type: .triangle,
                                       indexCount: indexCount,
                                       indexType: .uint32,
                                       indexBuffer: indexBuffer,
                                       indexBufferOffset: 0)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
