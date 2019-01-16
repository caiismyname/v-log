//
//  ViewController.swift
//  v-log
//
//  Created by David Cai on 1/15/19.
//  Copyright © 2019 David Cai. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var viewfinder: UIView!
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?

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
            viewfinder.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            // Prepare capture button
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            captureSession?.addOutput(capturePhotoOutput!)
        } catch {
            print(error)
        }
    }
    
    @IBAction func button(_ sender: Any) {
        
        guard let capturePhotoOutput = self.capturePhotoOutput else { return}
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .off
        
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension ViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Get captured image
        guard error == nil else {
            print("error capturing photo")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else { return }
        
        let capturedImage = UIImage.init(data: imageData, scale: 1.0)
        if let image = capturedImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil
                , nil)
        }

    }
}

