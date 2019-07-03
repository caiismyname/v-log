//
//  ViewController.swift
//  v-log
//
//  Created by David Cai on 1/15/19.
//  Copyright © 2019 David Cai. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices


class ViewController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var viewFinder: UIView!
    @IBOutlet weak var clipsButton: UIButton!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureVideoOutput: AVCaptureMovieFileOutput?
    var usingBackCamera = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.didOrientationChange(_:)),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
            
            let videoDevice = AVCaptureDevice.default(for: AVMediaType.video) // Default to back camera
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            captureSession = AVCaptureSession()
            
            // Add video
            let videoInput = try AVCaptureDeviceInput(device: videoDevice!)
            captureSession?.addInput(videoInput)
            
            // Add audio
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            captureSession?.addInput(audioInput)

            // Create live preview
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.frame = view.layer.bounds
            videoPreviewLayer?.session = captureSession
            
            // Create square mask
            let squareMask = CALayer.init()
            squareMask.backgroundColor = UIColor.init(white: 1.0, alpha: 1.0).cgColor
            let previewDimension = 2 * min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) // Why 2x? IDK. screen.width/height seems to only give the screen.
            squareMask.bounds = CGRect.init(x: 0, y: 0, width: previewDimension, height: previewDimension)
            videoPreviewLayer?.mask = squareMask
            
            viewFinder.layer.addSublayer(videoPreviewLayer!)
            // Make sure to bring the button to front *after* adding the video preview
            self.view.bringSubviewToFront(recordButton)
            self.view.bringSubviewToFront(clipsButton)

            captureSession?.startRunning()

            // Prepare capture button
            captureVideoOutput =  AVCaptureMovieFileOutput()
            captureSession?.addOutput(captureVideoOutput!)
            
            // Prepare the switch camera gesture
            let switchCameraGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.switchCameras(_:))) // RE: selectors https://stackoverflow.com/questions/24007650/selector-in-swift
            switchCameraGestureRecognizer.numberOfTapsRequired = 2
            switchCameraGestureRecognizer.numberOfTouchesRequired = 1
            viewFinder.addGestureRecognizer(switchCameraGestureRecognizer)
            
        } catch {
            print(error)
        }
    }
    
    // This changes the orientation that the video is recorded in
    @objc func didOrientationChange(_ notification: Notification) {
        switch UIDevice.current.orientation {
            case .landscapeLeft:
                print("landscapeLeft")
                self.captureVideoOutput?.connection(with: .video)?.videoOrientation = .landscapeRight
            case .landscapeRight:
                print("landscapeRight")
                self.captureVideoOutput?.connection(with: .video)?.videoOrientation = .landscapeLeft
            case .portrait:
                print("portrait Normal")
                self.captureVideoOutput?.connection(with: .video)?.videoOrientation = .portrait
            case .portraitUpsideDown:
                print("portrait Upsidedown")
                self.captureVideoOutput?.connection(with: .video)?.videoOrientation = .portraitUpsideDown
            default:
                print("other")
        }
    }

    func startRecordingState() {
        // Set record button
        recordButton.setTitle("Stop", for: [])
        recordButton.setTitleColor(UIColor.white, for: [])
        recordButton.backgroundColor = UIColor.red
        
        // Disable switching to other states
        clipsButton.isEnabled = false
        clipsButton.isHidden = true
        print("Start recording")
    }
    
    func stopRecordingState() {
        // Set record button
        recordButton.setTitle("Record", for: [])
        recordButton.setTitleColor(UIColor.red, for: [])
        recordButton.backgroundColor = UIColor.black
        
        // Reenable switching to other states
        clipsButton.isEnabled = true
        clipsButton.isHidden = false
        print("Stop recording")
    }

    // @objc b/c this function is associated with the tap gesture using a #selector, which requires objc functions
    // internal b/c the thing selected by the selector needs to be visable
    // see: https://stackoverflow.com/questions/24007650/selector-in-swift
    @objc internal func switchCameras(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            var device: AVCaptureDevice.DeviceType
            var position: AVCaptureDevice.Position
            
            if usingBackCamera {
                device = AVCaptureDevice.DeviceType.builtInWideAngleCamera
                position = AVCaptureDevice.Position.front
            } else {
                device = AVCaptureDevice.DeviceType.builtInWideAngleCamera
                position = AVCaptureDevice.Position.back
            }
            
            usingBackCamera = !usingBackCamera // toggle the camera state
            
            do {
                // To remove the previous camera, find the video input on the capturesession (video and audio are two separate inputs)
                let oldInput = captureSession?.inputs.first(where: {$0.ports.first?.mediaType == AVMediaType.video})
                let newVideoDevice = AVCaptureDevice.default(device, for: AVMediaType.video, position: position)
                let newInput = try AVCaptureDeviceInput(device: newVideoDevice!)
                captureSession?.beginConfiguration()
                captureSession?.removeInput(oldInput!)
                captureSession?.addInput(newInput)
                captureSession?.commitConfiguration()
                
            } catch {
                print (error)
            }
        }
    }
    
    @IBAction func recordButtonPress(_ sender: Any) {
        guard let captureVideoOutput = self.captureVideoOutput else { return}
        
        if captureVideoOutput.isRecording {
            captureVideoOutput.stopRecording()
            stopRecordingState()
        } else {
            // TODO Don't think this timestamp thing will be robust to timezone issues
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            captureVideoOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            startRecordingState()
        }
    }
    
    func getDirectoryPath() -> URL {
        do {
            let fmanager = FileManager.default
            let documents = fmanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let vlog_folder = documents.appendingPathComponent("vlog_clips", isDirectory: true)
            
            // First, create the directory
            var isDirectory: ObjCBool = false
            let directoryExists = fmanager.fileExists(atPath: vlog_folder.path, isDirectory: &isDirectory)
            if (!directoryExists || !isDirectory.boolValue) {
                try fmanager.createDirectory(at: vlog_folder, withIntermediateDirectories: false, attributes: [:])
            }
            
            let clip_url = vlog_folder.appendingPathComponent(generateCurrentTimeStamp(), isDirectory: false).appendingPathExtension("mov")
            return clip_url
        } catch {
            print("error while creating clip url")
            return URL(string: "error")!
        }
    }
    
    func generateCurrentTimeStamp () -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
        return (formatter.string(from: Date()) as NSString) as String
    }
    
    @IBAction func unwindToMainAction(unwindSegue: UIStoryboardSegue) {
        
    }
    
    func squareCropVideo(inputURL: NSURL, completion: @escaping (_ outputURL : NSURL?) -> ())
    {
        let videoAsset: AVAsset = AVAsset( url: inputURL as URL )
        let clipVideoTrack = videoAsset.tracks( withMediaType: AVMediaType.video ).first! as AVAssetTrack
        
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize( width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.height )
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30))
    
        let transform1: CGAffineTransform = CGAffineTransform(translationX: clipVideoTrack.naturalSize.height, y: 0)
        let transform2 = transform1.rotated(by: .pi/2)
        let finalTransform = transform2
        
        transformer.setTransform(finalTransform, at: CMTime.zero)
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        // Export
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
        // Save video to documents directory
        let croppedOutputFileUrl = getDirectoryPath()
        exportSession.outputURL = croppedOutputFileUrl
        exportSession.outputFileType = AVFileType.mov
        exportSession.videoComposition = videoComposition
        
        exportSession.exportAsynchronously() { () -> Void in
            if exportSession.status == .completed {
                print("Square crop export complete")
                DispatchQueue.main.async(execute: {
                    completion(croppedOutputFileUrl as NSURL)
                })
                return
            } else if exportSession.status == .failed {
                print("Square crop export failed - \(String(describing: exportSession.error))")
            }
            
            completion(nil)
            return
        }
    }
}



extension ViewController : AVCaptureFileOutputRecordingDelegate {
    // DidStartRecording
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    }
    
    // DidFinishRecording
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            return
        }
        
        squareCropVideo(inputURL: outputFileURL as NSURL, completion: { (outputURL) -> () in
                print("called square crop video")
                ThumbnailManager().generateAndSaveThumbnail(clip_url: outputURL!) // Use the cropped video's url as the input to the thumbnail generator
            }
        )
        
        

    }
}
