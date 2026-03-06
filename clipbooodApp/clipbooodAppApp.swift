import SwiftUI
import AVFoundation

@main
struct ClipbooodApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
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
