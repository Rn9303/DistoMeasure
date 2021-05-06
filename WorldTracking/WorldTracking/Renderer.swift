//
//  MTLcreater.swift
//  WorldTracking
//
//  Created by Roman on 4/29/21.
//

import Foundation
import Metal
import MetalKit
import ARKit
import MetalPerformanceShaders

// The max number of command buffers in flight.
let kMaxBuffersInFlight: Int = 3

// Vertex data for an image plane.
let kImagePlaneVertexData: [Float] = [
    -1.0, -1.0, 0.0, 1.0,
    1.0, -1.0, 1.0, 1.0,
    -1.0, 1.0, 0.0, 0.0,
    1.0, 1.0, 1.0, 0.0
]

class Renderer{
    
    let session: ARSession
    let device: MTLDevice
    let inFlightSemaphore = DispatchSemaphore(value: kMaxBuffersInFlight)
    
    var commandQueue: MTLCommandQueue!
    
    // A texture used to store depth information from the current frame.
    var depthTexture: CVMetalTexture?
    
    // A texture used to pass confidence information to the GPU for fog rendering.
    var confidenceTexture: CVMetalTexture?
    
    // A texture of the blurred depth data to pass to the GPU for fog rendering.
    var filteredDepthTexture: MTLTexture!
    
    // Captured image texture cache.
    var cameraImageTextureCache: CVMetalTextureCache!
    
    // An object that holds vertex information for source and destination rendering.
    var imagePlaneVertexBuffer: MTLBuffer!
    
    //Object for pipeline or something
    var samplerPipelineState: MTLRenderPipelineState!
    
    
    init(session: ARSession, metalDevice device: MTLDevice){
        self.session = session
        self.device = device
        
        //loadMetal()
    }
    
    func loadMetal(){
        
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let samplerFunc = defaultLibrary.makeFunction(name: "sampleFunc")!
        
        let samplePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        samplePipelineStateDescriptor.label = "MySamplingPipeline"
        
        do{
            try samplerPipelineState = device.makeRenderPipelineState(descriptor: samplePipelineStateDescriptor)
        } catch let error {
            print("Failed to create the pipeline state, error: \(error)")
        }

        commandQueue = device.makeCommandQueue()
    }
    
    func Update() {
        
        /*if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommand"
            
            updateAppState()
            
            guard let arDepthTexture = depthTexture, let depthTexture = CVMetalTextureGetTexture(arDepthTexture) else {
                print("Error: Unable to apply the MPS filter.")
                return
            }
    
            setupFilter(width: depthTexture.width, height: depthTexture.height)
            
            // Pass the depth and confidence pixel buffers to the GPU to shade-in the fog.
            if let renderPassDescriptor = renderDestination.currentRenderPassDescriptor, let currentDrawable = renderDestination.currentDrawable {

                if let fogRenderEncoding = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    
                    // Set a label to identify this render pass in a captured Metal frame.
                    fogRenderEncoding.label = "MyFogRenderEncoder"


                    // Finish encoding commands.
                    fogRenderEncoding.endEncoding()
                }
                
                // Schedule a present once the framebuffer is complete using the current drawable.
                commandBuffer.present(currentDrawable)
            }
            
            // Finalize rendering here & push the command buffer to the GPU.
            commandBuffer.commit()
        }*/
    }
    
    // Updates any app state.
    func updateAppState() {

        // Get the AR session's current frame.
        guard let currentFrame = session.currentFrame else {
            return
        }
        
        // Prepare the current frame's depth and confidence images for transfer to the GPU.
        updateARDepthTexures(frame: currentFrame)
        
    }
    
    // Prepares the scene depth information for transfer to the GPU for rendering.
    func updateARDepthTexures(frame: ARFrame) {
        // Get the scene depth or smoothed scene depth from the current frame.
        guard let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth else {
            print("Failed to acquire scene depth.")
            return
        }
        var pixelBuffer: CVPixelBuffer!
        pixelBuffer = sceneDepth.depthMap
        
        // Set up the destination pixel format for the depth information, and
        // create a Metal texture from the depth image provided by ARKit.
        var texturePixelFormat: MTLPixelFormat!
        setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
        depthTexture = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)

        // Get the current depth confidence values from the current frame.
        // Set up the destination pixel format for the confidence information, and
        // create a Metal texture from the confidence image provided by ARKit.
        pixelBuffer = sceneDepth.confidenceMap
        setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
        confidenceTexture = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)
    }
    
    
    // Assigns an appropriate MTL pixel format given the argument pixel-buffer's format.
    func setMTLPixelFormat(_ texturePixelFormat: inout MTLPixelFormat?, basedOn pixelBuffer: CVPixelBuffer!) {
        if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_DepthFloat32 {
            texturePixelFormat = .r32Float
        } else if CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_OneComponent8 {
            texturePixelFormat = .r8Uint
        } else {
            fatalError("Unsupported ARDepthData pixel-buffer format.")
        }
    }
    
    // Sets up a filter to process the depth texture.
    func setupFilter(width: Int, height: Int) {
        // Create a destination backing-store to hold the blurred result.
        let filteredDepthDescriptor = MTLTextureDescriptor()
        filteredDepthDescriptor.pixelFormat = .r32Float
        filteredDepthDescriptor.width = width
        filteredDepthDescriptor.height = height
        filteredDepthDescriptor.usage = [.shaderRead, .shaderWrite]
        filteredDepthTexture = device.makeTexture(descriptor: filteredDepthDescriptor)
        
    }
    
    
    // Creates a Metal texture with the argument pixel format from a CVPixelBuffer at the argument plane index.
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        // Create camera image texture cache.
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        cameraImageTextureCache = textureCache
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, cameraImageTextureCache, pixelBuffer, nil, pixelFormat,
                                                               width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }
    
    
}

