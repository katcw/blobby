//
//  metalView.swift
//  blobby
//
//  Created by kalen •ᴗ•  on 20/8/26.
//

import SwiftUI
import MetalKit


struct MetalView: UIViewRepresentable {
    
    /**
     creates a coordinator, a helper object that acts as a "middleman" between swiftui and the metal view
     - returns: a `Coordinator` object
    */
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    /**
     creates a coordinator, a helper object that acts as a "middleman" between swiftui and the metal view
     - returns: a `Coordinator` object
    */
    func makeUIView(context: Context) -> MTKView {
        
        let mtkView = MTKView()
        
        /**
         gives us a reference to the device's gpu
         if it unable to do so, then we terminate immediately with `fatalerror`
         */
        guard let device = MTLCreateSystemDefaultDevice()
        else { fatalError("this device does not support metal :(") }
        mtkView.device = device
        
        // instructs the view to make a depth buffer for our 3d depth test
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        
        /**
         creates a `Renderer` object, stores it in the coordinator
         so it stays alive after `makeUIView` ends, and sets it as the metal view's
         delegate so the view can invoke it when required
         */
        let renderer = Renderer(mtkView: mtkView)
        context.coordinator.renderer = renderer
        mtkView.delegate = renderer
        
        /**
         `clearColor` is the background/base colour the metal view fills the
         screen with each frame before the renderer renders anything on screen
         */
        mtkView.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0)

        return mtkView
    }
    /**
     called by swiftui whenever the view state changes and the underlying metal view might need to be updated to match
     - parameter uiView:  the existing metal view instance created by `makeUIView`
     - parameter context: swiftui-provided context; gives access to the `Coordinator` object
     */
    func updateUIView(_ uiView: MTKView, context: Context) {}

    final class Coordinator {
        var renderer: Renderer?
    }
}
