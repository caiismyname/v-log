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
            self.view.bringSubviewToFront(clipsButton)

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
            // TODO Don't think this timestamp thing will be robust to timezone issues
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            captureVideoOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            recordButton.setTitle("Stop", for: [])
            recordButton.setTitleColor(UIColor.white, for: [])
            recordButton.backgroundColor = UIColor.red
            
            print("starting to record")
        }
    }
    
    
//    Callback that displays the "success" popup
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
                print("directory didn't exist, making it")
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
}

extension ViewController : AVCaptureFileOutputRecordingDelegate {
    // DidStartRecording
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    }
    
    // DidFinishRecording
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
//            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        // Save video to documents directory
        do {
            try FileManager.default.moveItem(at: outputFileURL, to: getDirectoryPath())
            print("done saving")
        } catch {
            print("Error saving video")
        }
        
    }
}
