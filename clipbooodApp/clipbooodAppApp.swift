import SwiftUI

@main
struct ClipbooodApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // AVAudioSession の設定は PiPManager.setupPlayer() 内で一元管理
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        clipboardManager.checkClipboard()
                    }
                }
        }
    }
}
