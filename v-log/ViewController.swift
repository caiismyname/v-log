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

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureVideoOutput: AVCaptureMovieFileOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            videoPreviewLayer?.session = captureSession
            viewFinder.layer.addSublayer(videoPreviewLayer!)
            // Make sure to bring the button to front *after* adding the video preview
            self.view.bringSubviewToFront(recordButton)

            captureSession?.startRunning()

            // Prepare capture button
            captureVideoOutput =  AVCaptureMovieFileOutput()
            captureSession?.addOutput(captureVideoOutput!)
        } catch {
            print(error)
        }
    }
    
    @IBAction func recordButtonPress(_ sender: Any) {
        guard let captureVideoOutput = self.captureVideoOutput else { return}
        
        if captureVideoOutput.isRecording {
            // Stop
            captureVideoOutput.stopRecording()
            recordButton.setTitle("Record", for: [])
            recordButton.setTitleColor(UIColor.red, for: [])
            recordButton.backgroundColor = UIColor.white
            
            print("stoppping the recording")
        } else {
            // Start
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            captureVideoOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            
            recordButton.setTitle("Stop", for: [])
            recordButton.setTitleColor(UIColor.white, for: [])
            recordButton.backgroundColor = UIColor.red
            
            print("starting to record")
        }
    }
    
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
//
//extension ViewController : AVCapturePhotoCaptureDelegate {
//    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        // Get captured image
//        guard error == nil else {
//            print("error capturing photo")
//            return
//        }
//
//        guard let imageData = photo.fileDataRepresentation() else { return }
//
//        let capturedImage = UIImage.init(data: imageData, scale: 1.0)
//        if let image = capturedImage {
//            UIImageWriteToSavedPhotosAlbum(image, nil, nil
//                , nil)
//        }
//
//    }
//}

extension ViewController : AVCaptureFileOutputRecordingDelegate {
    // DidStartRecording
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
    }
    
    // DidFinishRecording
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // Note: Since we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
        }
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            // TODO Check authorization status.
            print("saving")
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
            
        }
    }
}
