//
//  thumbnails.swift
//  v-log
//
//  Created by David Cai on 6/11/19.
//  Copyright © 2019 David Cai. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ThumbnailManager {
    
    let thumbnail_dimensions = 200;
    
    func generateAndSaveThumbnail(clip_url: NSURL) {
        let fmanager = FileManager.default
        let documents = fmanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnails_folder = documents.appendingPathComponent("thumbnails", isDirectory: false) // Set isDirectory to false so it doesn't include a trailing slash when queried by the if-statement below. The `.fileExists` method does take an isDirectory field, but it requires an UnsafeMutablePointer<ObjCBool> that I can't get to work.

        if !FileManager.default.fileExists(atPath: thumbnails_folder.absoluteString) {
            do {
                try fmanager.createDirectory(at: thumbnails_folder, withIntermediateDirectories: false, attributes: [:])
            } catch {
                print(error)
            }
        }
        
        let thumbnail = makeThumbnail(clip_url: clip_url)
        let url = makeThumbnailURL(clip_url: clip_url)
       
        do {
            try thumbnail.jpegData(compressionQuality: 0.5)?.write(to: url, options: .atomic)
            print ("Saved thumbnail at path \(url)")
        } catch {
            print("file cannot be saved at path \(url), with error : \(error)")
        }
    }
    
    func makeThumbnail(clip_url: NSURL) -> UIImage {
        do {
            // It is important to create URls to local files using `fileURLWithPath` otherwise some things think it's a remote URL
            let asset = AVURLAsset(url: URL(fileURLWithPath: clip_url.path!))
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true // This rotates the images into right-side-up
            
            let timestamp = CMTime(seconds: 0, preferredTimescale: 60)
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            let originalImage = UIImage(cgImage: imageRef)
            let rect = generateImagePreviewRect(size: originalImage.size)
            let croppedImage = cropImage(originalImage, toRect: rect, viewWidth: CGFloat(thumbnail_dimensions), viewHeight: CGFloat(thumbnail_dimensions))
            
            return croppedImage!
        } catch let error as NSError {
            print("Image retrevial failed with error \(error)")
            return UIColor.brown.imageWithColor(width: thumbnail_dimensions, height: thumbnail_dimensions)
        }
    }

    func generateImagePreviewRect(size: CGSize) -> CGRect {
        if size.width < size.height {
            // Portrait
            let sideLen = size.width
            return CGRect.init(x: 0, y: (size.height / 2) - (sideLen / 2), width: sideLen, height: sideLen)
        } else if size.width > size.height {
            // Landscape
            let sideLen = size.height
            return CGRect.init(x: (size.width / 2) - (sideLen / 2), y: 0, width: sideLen, height: sideLen)
        } else {
            // Square
            let sideLen = size.height
            return CGRect.init(x: 0, y: 0, width: sideLen, height: sideLen)
        }
    }
    
    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage?
    {
        let imageViewScale = CGFloat(1)
        
        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x * imageViewScale,
                              y:cropRect.origin.y * imageViewScale,
                              width:cropRect.size.width * imageViewScale,
                              height:cropRect.size.height * imageViewScale)
        
        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
        else {
            return nil
        }
        
        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
    
    func makeThumbnailURL(clip_url: NSURL) -> URL {
        let fmanager = FileManager.default
        let documents = fmanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnail_folder = documents.appendingPathComponent("thumbnails", isDirectory: true)
        let timestamp = clip_url.lastPathComponent!.replacingOccurrences(of: ".mov", with: "")
        return thumbnail_folder.appendingPathComponent(timestamp + "_thumbnail", isDirectory: false).appendingPathExtension("jpg")
    }
}

extension UIColor {
    func imageWithColor(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
