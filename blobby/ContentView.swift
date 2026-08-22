//
//  ContentView.swift
//  blobby
//
//  Created by kalen •ᴗ•  on 20/8/26.
//

import SwiftUI

struct ContentView: View {
    
    // shared morph state, reference to MorphController
    @State private var morph = MorphController()
    
    // tracks whether the current drag has already been started
    @State private var isDragging = false
    
    // drag sensitivity
    private let dragSensitivity: Float = 0.004
    
    var body: some View {
        MetalView(morph: morph)
            .ignoresSafeArea()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            morph.beginDrag()
                        }
                        morph.updateDrag(translation: Float(value.translation.width))
                    }
                    .onEnded { value in
                        isDragging = false
                        morph.endDrag(velocity: Float(value.velocity.width))
                    }
            )
    }
}

#Preview {
    ContentView()
}
