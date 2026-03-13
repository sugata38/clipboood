import Foundation
import AVKit
import AVFoundation
import Combine
import SwiftUI

class PiPManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var isPiPActive = false
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var pipController: AVPictureInPictureController?
    private var looper: AVPlayerLooper?
    var onPiPStarted: (() -> Void)?
    var onPiPStopped: (() -> Void)?
    
    func setupPlayer(in playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        let videoURL = getOrCreateBlackVideo()
        let templateItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)
        self.player = queuePlayer
        playerLayer.player = queuePlayer
        
        // AVAudioSession: PiP映像の再生に必要な最低限の設定
        // .mixWithOthers で他アプリの音声を妨げない
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup error: \(error)")
        }
        
        queuePlayer.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                let controller = AVPictureInPictureController(playerLayer: playerLayer)
                controller?.delegate = self
                self.pipController = controller
            }
        }
    }
    
    func togglePiP() {
        guard let controller = pipController else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }
    
    private func getOrCreateBlackVideo() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pip_black.mp4")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: NSNumber(value: 2),
            AVVideoHeightKey: NSNumber(value: 2)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 2, 2, kCVPixelFormatType_32BGRA, nil, &pb)
        guard let pixelBuffer = pb else { fatalError() }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        memset(CVPixelBufferGetBaseAddress(pixelBuffer)!, 0, CVPixelBufferGetDataSize(pixelBuffer))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        for i in 0..<10 {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.01) }
            adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: 10))
        }
        input.markAsFinished()
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { semaphore.signal() }
        semaphore.wait()
        return url
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pipController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = true; self.onPiPStarted?() }
        // 注意: player.pause() は呼ばない。映像再生を維持してPiPウィンドウを保持する。
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pipController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = false; self.onPiPStopped?() }
    }
    
    /// バックグラウンドでの音声再生を禁止する（iOS 15+）
    /// これにより「音声コンテンツを提供していない」ことをシステムに明示する
    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pipController: AVPictureInPictureController) -> Bool {
        return true
    }
}

struct PiPHostView: UIViewRepresentable {
    let pipManager: PiPManager
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let playerLayer = AVPlayerLayer()
        playerLayer.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        pipManager.setupPlayer(in: playerLayer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
