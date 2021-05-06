//
//  ViewController.swift
//  WorldTracking
//
//  Created by Roman on 4/1/21.
//

import UIKit
import ARKit
import MetalKit
import Metal
import CoreMotion
import CoreHaptics

class ViewController: UIViewController{

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var session: ARSession!
    
    var motionManager: CMMotionManager!
    
    var timer = Timer()
    
    var textureMaker: Renderer!
    
    var speedOn = true
    
    var hapticOn = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let string = "Welcome to Disto-Measure, to begin, point your device in the direction you want to move and it will start guiding you, the settings are in the top left if you need to change your experience." //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
        
        session = ARSession()
        
        configuration.frameSemantics = .smoothedSceneDepth //configure the way the camera will sensors will obtain the data
        
        self.sceneView.session.run(configuration)//Begin sensors and data collecting
        
        textureMaker = Renderer(session: session, metalDevice: MTLCreateSystemDefaultDevice()!)
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        // Handle acceleration update
        
        self.runEveryFrame()//start function that repeats at specific intervals for when to annouce warnings
    }
    
    func runEveryFrame(){
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    
    @objc func updateCounting(){
        let frame = sceneView.session.currentFrame
        guard let sceneDepth = frame?.smoothedSceneDepth ?? frame?.sceneDepth else {
            print("Failed to acquire scene depth.")
            return
        }
        
        var pixelBuffer: CVPixelBuffer!
        
        pixelBuffer = sceneDepth.depthMap
        
        var depthTexture: CVMetalTexture!
        var confidenceTexture: CVMetalTexture!
        
        var texturePixelFormat: MTLPixelFormat!
        textureMaker.setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
        depthTexture = textureMaker.createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)
        
        pixelBuffer = sceneDepth.confidenceMap
        textureMaker.setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
        confidenceTexture = textureMaker.createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)
    }
    
    @IBAction func SpeedSimulator(_ sender: Any) {
        /*let distanceToWall = 5.0
        let accelerometerData = motionManager.accelerometerData
        if(sqrt(accelerometerData?.acceleration.x ^ 2 + accelerometerData?.acceleration.y ^ 2) * 1.5 > distanceToWall){
            let string = "STOP, you are about to hit an object" //Message that will be said by text-to-speech
            
            //setting up settings for text-to-speech
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            //calling the text-to-speech
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
        }*/
        let string = "STOP, you are about to hit an object" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    @IBAction func VibrationSimulator(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    @IBAction func speedSwitch(_ uiSwitch: UISwitch) {
        if uiSwitch.isOn {
            speedOn = true;
            let string = "Accelerometer turned on" //Message that will be said by text-to-speech
            
            //setting up settings for text-to-speech
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            //calling the text-to-speech
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
        } else {
            let string = "Accelerometer turned off" //Message that will be said by text-to-speech
            
            //setting up settings for text-to-speech
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            //calling the text-to-speech
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
            hapticOn = false;
        }
    }
    @IBAction func hapticSwitch(_ uiSwitch: UISwitch) {
        if uiSwitch.isOn {
            let string = "Haptic feedback turned on" //Message that will be said by text-to-speech
            
            //setting up settings for text-to-speech
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            //calling the text-to-speech
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
            hapticOn = true;
        } else {
            let string = "Haptic feedback turned off" //Message that will be said by text-to-speech
            
            //setting up settings for text-to-speech
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            //calling the text-to-speech
            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
            hapticOn = false;
        }
    }
    
    @IBAction func topLeft(_ sender: Any) {
        let string = "Object to the left ahead" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func topMiddle(_ sender: Any) {
        let string = "Object Straight ahead" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func topRight(_ sender: Any) {
        let string = "Object to the right ahead" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func middleLeft(_ sender: Any) {
        let string = "Object directly to the left" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func middleMiddle(_ sender: Any) {
        let string = "Object directly ahead" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func middleRight(_ sender: Any) {
        let string = "Object directly to the right" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func bottomLeft(_ sender: Any) {
        let string = "Object in front and to the left" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func bottomBottom(_ sender: Any) {
        let string = "Object in front" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    @IBAction func bottomRight(_ sender: Any) {
        let string = "Object in front and to the right" //Message that will be said by text-to-speech
        
        //setting up settings for text-to-speech
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        //calling the text-to-speech
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
}

