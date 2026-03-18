import SwiftUI

@main
struct ClipbooodApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @Environment(\.scenePhase) var scenePhase
    
    /// オンボーディング完了フラグ（UserDefaultsに保存）
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        // AVAudioSession の設定は PiPManager.setupPlayer() 内で一元管理
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                // メイン画面
                ContentView()
                    .environmentObject(clipboardManager)
                    .onAppear {
                        // コントロールセンターからの起動要求をチェック
                        handlePiPStartRequest()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            // フォアグラウンド復帰時にCC起動要求を確認
                            handlePiPStartRequest()
                        }
                    }
            } else {
                // 初回起動時のオンボーディング画面
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
    
    /// コントロールセンターからのPiP起動要求を処理する
    /// StartMonitoringIntentがUserDefaultsにフラグを立てるので、それを読み取る
    private func handlePiPStartRequest() {
        if UserDefaults.standard.bool(forKey: "ShouldStartPiP") {
            // フラグをリセット（二重起動防止）
            UserDefaults.standard.set(false, forKey: "ShouldStartPiP")
            
            // 少し遅延させてPiPを起動（画面の描画完了を待つ）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // ContentView内のPiPManagerに起動通知を送る
                NotificationCenter.default.post(
                    name: Notification.Name("StartPiPFromControlCenter"),
                    object: nil
                )
            }
        }
    }
}
