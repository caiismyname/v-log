import UIKit
import AVFoundation
import AVKit

class ClipsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource  {
    // MARK: - Properties

    @IBOutlet weak var clipsPreviewCollectionView: UICollectionView!
    @IBOutlet weak var clipsPreviewDisplay: UIView!
    @IBOutlet weak var previewDismissButton: UIBarButtonItem!
    
    private let reuseIdentifier = "ClipCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    private let itemsPerRow: CGFloat = 4
    private var all_previews: [UIImage] = []
    private var all_item_urls: [String] = []
    
    // Below is so we can dismiss the preview once it's done
    private var videoCurrentlyPreview: Bool = false
    
    override func viewDidLoad() {
        self.all_previews = getAllPreviews() ?? []
        self.clipsPreviewCollectionView.delegate = self
        self.clipsPreviewCollectionView.dataSource = self
        self.previewDismissButton.isEnabled = false
    }
    
    func getAllPreviews() -> [UIImage]? {
        do {
            let fmanager = FileManager.default
            let documents = fmanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let vlog_folder = documents.appendingPathComponent("vlog_clips", isDirectory: true)
            var vlog_folder_contents = try fmanager.contentsOfDirectory(atPath: vlog_folder.path)
            
            vlog_folder_contents.sort() // Naive way of putting videos in chron order. Relies on timestamp naming of the clips.
            for clip in vlog_folder_contents {
                    all_item_urls.append(vlog_folder.appendingPathComponent(clip).path)
            }
            
            var previews = [UIImage]()
            
            for clip_url in vlog_folder_contents {
                let full_clip_url = vlog_folder.appendingPathComponent(clip_url)
                // It is important to create URls to local files using `fileURLWithPath` otherwise some things think it's a remote URL
                let asset = AVURLAsset(url: URL(fileURLWithPath: full_clip_url.path))
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true // This rotates the images into right-side-up
                
                let timestamp = CMTime(seconds: 0, preferredTimescale: 60)
                let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                previews.append(UIImage(cgImage: imageRef))
            }

            return previews
        
        } catch let error as NSError {
            print("Image retrevial failed with error \(error)")
            return nil
        }
    }
    
    // Triggered when a collection item (clip) is selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let url = self.all_item_urls[indexPath.item]
        
        videoCurrentlyPreview = true;
        previewDismissButton.isEnabled = true
        self.playVideo(fileURL: URL(fileURLWithPath: url))
    }
    
    func playVideo(fileURL: URL) {
        let playerItem = AVPlayerItem(url: fileURL)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.clipsPreviewDisplay.frame
        self.clipsPreviewDisplay.layer.addSublayer(playerLayer)
        player.play()
    }
    
    @IBAction func previewDismissTapped(_ sender: Any) {
        self.videoCurrentlyPreview = false
        self.previewDismissButton.isEnabled = false
        self.clipsPreviewDisplay.layer.sublayers![0].removeFromSuperlayer()
    }
    
    // MARK: Collection view stuff
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getAllPreviews()?.count ?? 0
    }
    
    // This makes the actual clip preview cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ClipPreviewCell
        let clipPreview = photo(for: indexPath)
        cell.backgroundColor = .white
        cell.clipPreviewView.image = clipPreview
        
        return cell
    }
    
    // Cell Layout stuff
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

// MARK: - Private
private extension ClipsViewController {
    func photo(for indexPath: IndexPath) -> UIImage {
        return all_previews[indexPath.row]
    }
}
