//
//  CameraViewController.swift
//  SloMoVideo
//
//  Created by amir sankar on 10/7/16.
//  Copyright © 2016 amir sankar. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import UIKit

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var videoPreview: UIView!
    @IBOutlet var recordButtonOutlet: UIButton!
    var activeInput: AVCaptureDeviceInput!
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    let movieOutput = AVCaptureMovieFileOutput()
    var dataManager = DAO.dataManager
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if setupSession() {
            setupPreview()
            startSession()
        }
    }
    
    
    @IBAction func recordButton(_ sender: AnyObject) {
        captureMovie()
    }
    
    
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = videoPreview.bounds
        previewLayer.contentsGravity = kCAGravityResizeAspectFill
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreview.layer.addSublayer(previewLayer)
    }
    
    
    func setupSession() -> Bool {
        captureSession.sessionPreset = AVCaptureSessionPresetInputPriority
        
        // Setup Camera
        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        
        // Setup Microphone
        let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        // Movie output
        movieOutput.movieFragmentInterval = kCMTimeInvalid
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        return true
    }
    
    
    
    func receiveSwitchNotification(_ notification:Notification){
        if notification.name == "switch"{
            self.tabBarController?.selectedIndex = 0
        }
    }
    
    
    
    func startSession() {
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
    }

    
    
    @IBAction func switchCamDirection(_ sender: AnyObject) {
        
        if movieOutput.isRecording == false {
            // Make sure the device has more than 1 camera.
            if AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count > 1 {
                // Check which position the active camera is.
                var newPosition: AVCaptureDevicePosition!
                if activeInput.device.position == AVCaptureDevicePosition.back {
                    newPosition = AVCaptureDevicePosition.front
                } else {
                    newPosition = AVCaptureDevicePosition.back
                }
                
                // Get camera at new position.
                var newCamera: AVCaptureDevice!
                let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
                for device in devices! {
                    if (device as AnyObject).position == newPosition {
                        newCamera = device as! AVCaptureDevice
                    }
                }
                
                // Create new input and update capture session.
                do {
                    let input = try AVCaptureDeviceInput(device: newCamera)
                    captureSession.beginConfiguration()
                    // Remove input for active camera.
                    captureSession.removeInput(activeInput)
                    // Add input for new camera.
                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                        activeInput = input
                    } else {
                        captureSession.addInput(activeInput)
                    }
                    captureSession.commitConfiguration()

                } catch {
                    print("Error switching cameras: \(error)")
                }
            }
        }
    }
    
    //PROBLEM IS THAT THE BACK CAM SUPPORTS THIS BUT NOT FRONT FACING CAM. MIGHT HAVE TO SET TO DEFAULT FORMAT BEFORE SWITCHING CAMERA
    
    func captureMovie() {
        
        if movieOutput.isRecording == false {
            let connection = movieOutput.connection(withMediaType: AVMediaTypeVideo)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }

            let device = activeInput.device
            

            
            if (device?.isSmoothAutoFocusSupported)! {
                do {
                    try device?.lockForConfiguration()
                    device?.isSmoothAutoFocusEnabled = false
                    device?.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
            }
            if device?.position == AVCaptureDevicePosition.back { //FRONT CAM WORKS IF I SKIP THE FORMATTING HERE
                
            if (captureSession.isRunning == true) {
                captureSession.stopRunning()
            }
                var currentFormat = AVCaptureDeviceFormat()
//                var maxWidth : Int32 = 0
                var frameRateRange = AVFrameRateRange()
        
            for format in device?.formats as! [AVCaptureDeviceFormat] {
                
                for range in format.videoSupportedFrameRateRanges as! [AVFrameRateRange] {
                    
                    let description : CMFormatDescription = format.formatDescription
                    let dimensions : CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(description)
//                    var width : Int32 = dimensions.width
                    
                    if(range.maxFrameRate > 59){
                        currentFormat = format
                        frameRateRange = range
//                        maxWidth = width
                        
                        print("format: \(currentFormat) \nframeRateRage: \(frameRateRange)")
                    }
                }
            }
            
            
                do {
                    try device?.lockForConfiguration()
                    
                    device?.activeFormat = currentFormat
                    device?.activeVideoMinFrameDuration = CMTimeMake(1, 60)
                    device?.activeVideoMaxFrameDuration = CMTimeMake(1, 60)
                    
                    device?.unlockForConfiguration()
                } catch {
                    print("ERROR With lock/unlock and configuring frame rate")
                }
           
            


            captureSession.startRunning()
        
            } //line for skipping formate change for FRONT cam
        
            let outputURL = tempURL()
            movieOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
        } else {
            stopRecording()
        }
    }
    

    
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }

    

    func saveMovieToLibrary(_ movieURL: URL) {
        
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieURL)
        }) { (success: Bool, error: NSError?) -> Void in
            if success {
                // Set thumbnail
                self.setVideoThumbnailFromURL(movieURL)
            } else {
                print("Error writing to movie library: \(error!.localizedDescription)")
            }
        }
    }
    
    
    
    func setVideoThumbnailFromURL(_ movieURL: URL) {
        videoQueue().async { () -> Void in
        
            print(movieURL)
            let newVideo = Video(fromURL:movieURL)
            self.dataManager.videos.append(newVideo)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refresh"), object: self)
        }
    }



    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent("SloMoVideo.mov")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
   

}


//Extension for AVCaptureFileOutputRecordingDelegate callback methods


extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        self.recordButtonOutlet.setImage(UIImage(named: "recording"), for: UIControlState())
    }
    
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            
            UIApplication.shared.beginIgnoringInteractionEvents()
            // Write video to library

            
            saveMovieToLibrary(outputFileURL)
            self.recordButtonOutlet.setImage(UIImage(named: "recordButton"), for: UIControlState())
        }
    }
}



