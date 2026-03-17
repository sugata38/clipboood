import Foundation
import AVKit
import AVFoundation
import Combine
import SwiftUI

/// PiPの小窓の中に表示されるカスタムUI
class CustomPiPViewController: AVPictureInPictureVideoCallViewController {
    let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景色を暗いグレーにしてウィジェット風に
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.95)
        
        // ラベルの設定
        statusLabel.text = "clipboood"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold) // 少し小さめに調整
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // ★ ここが重要：PiPの縦横比を「極端な横長」に指定する
        // さらに縦幅を細くするため、高さを120から60に変更
        self.preferredContentSize = CGSize(width: 800, height: 60)
    }
}

class PiPManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var isPiPActive = false
    private var pipController: AVPictureInPictureController?
    
    var onPiPStarted: (() -> Void)?
    var onPiPStopped: (() -> Void)?
    
    /// ビデオ通話APIを用いてセットアップする
    func setupPlayer(in sourceView: UIView) {
        // AVAudioSession: PiPの起動システム要件として必要
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup error: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                
                let pipViewController = CustomPiPViewController()
                
                // ★ 初回の正方形化バグを防ぐため、システムにサイズを強制認識させる
                pipViewController.loadViewIfNeeded()
                pipViewController.view.layoutIfNeeded()
                
                // ★ ビデオ通話用APIを利用（コントロールバーが一切表示されなくなる）
                let contentSource = AVPictureInPictureController.ContentSource(
                    activeVideoCallSourceView: sourceView,
                    contentViewController: pipViewController
                )
                
                let controller = AVPictureInPictureController(contentSource: contentSource)
                controller.delegate = self
                controller.canStartPictureInPictureAutomaticallyFromInline = true
                self.pipController = controller
                
                print("VideoCall PiP Controller initialized successfully")
            } else {
                print("PiP is not supported on this device/simulator.")
            }
        }
    }
    
    func togglePiP() {
        guard let controller = pipController else {
            print("togglePiP failed: Controller is nil")
            return
        }
        
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pipController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = true; self.onPiPStarted?() }
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pipController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = false; self.onPiPStopped?() }
    }
    
    /// バックグラウンドでの音声再生を禁止する
    /// システムに音声コンテンツを提供していないことを明示する（審査用）
    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pipController: AVPictureInPictureController) -> Bool {
        return true
    }
}

struct PiPHostView: UIViewRepresentable {
    let pipManager: PiPManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        // 単なる透明なViewを基点（出発点）としてPiPに渡す
        pipManager.setupPlayer(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
