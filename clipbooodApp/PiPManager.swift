import Foundation
import AVKit
import AVFoundation
import Combine
import SwiftUI

/// PiPの小窓の中に表示されるカスタムUI
/// コントロールセンターから起動された際にステータスを表示する
class CustomPiPViewController: AVPictureInPictureVideoCallViewController {
    let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景色を暗いグレーにしてウィジェット風に
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.95)
        
        // ラベルの設定
        statusLabel.text = "clipboood 📋"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // PiPの縦横比を「極端な横長」に指定し、最小限の画面占有に
        self.preferredContentSize = CGSize(width: 800, height: 60)
    }
}

/// PiP（ピクチャー・イン・ピクチャー）の管理を担当するクラス
/// コントロールセンターからの起動シグナルを受けてPiPを開始し、
/// クリップボード監視のバックグラウンド動作を可能にする
class PiPManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var isPiPActive = false
    private var pipController: AVPictureInPictureController?
    
    /// PiP開始時に呼ばれるコールバック
    var onPiPStarted: (() -> Void)?
    /// PiP停止時に呼ばれるコールバック
    var onPiPStopped: (() -> Void)?
    
    /// ビデオ通話APIを用いてPiPコントローラーをセットアップする
    /// ※PiP自体は自動起動しない（コントロールセンターからの明示的操作が必要）
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
                
                // 初回の正方形化バグを防ぐため、システムにサイズを強制認識させる
                pipViewController.loadViewIfNeeded()
                pipViewController.view.layoutIfNeeded()
                
                // ビデオ通話用APIを利用（コントロールバーが一切表示されなくなる）
                let contentSource = AVPictureInPictureController.ContentSource(
                    activeVideoCallSourceView: sourceView,
                    contentViewController: pipViewController
                )
                
                let controller = AVPictureInPictureController(contentSource: contentSource)
                controller.delegate = self
                // ★ 重要: 自動起動を無効化（コントロールセンターからの明示的操作のみ）
                controller.canStartPictureInPictureAutomaticallyFromInline = false
                self.pipController = controller
                
                print("VideoCall PiP Controller initialized successfully")
            } else {
                print("PiP is not supported on this device/simulator.")
            }
        }
    }
    
    /// PiPの開始/停止を切り替える
    /// コントロールセンターのControlWidgetからAppIntentを通じて呼ばれる
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
    
    /// PiPを開始する（コントロールセンターからの起動時に使用）
    func startPiP() {
        guard let controller = pipController else {
            print("startPiP failed: Controller is nil")
            return
        }
        if !controller.isPictureInPictureActive {
            controller.startPictureInPicture()
        }
    }
    
    /// PiPを停止する
    func stopPiP() {
        guard let controller = pipController else { return }
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
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

/// PiPの基点となるUIViewをSwiftUIから利用するためのラッパー
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
