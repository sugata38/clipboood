import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var pipManager = PiPManager()
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationView {
            ZStack {
                PiPHostView(pipManager: pipManager)
                    .frame(width: 1, height: 1)
                    .opacity(0.01) // 0にするとOSがレンダリングを完全にスキップしてPiPが起動できなくなるため、0.01に設定
                
                List {
                    ForEach(clipboardManager.history, id: \.self) { text in
                        Button(action: {
                            clipboardManager.copyToClipboard(text: text)
                            generator.impactOccurred()
                        }) {
                            Text(text)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("クリップ履歴")

            .onAppear {
                generator.prepare()
                pipManager.onPiPStarted = {
                    clipboardManager.startMonitoring()
                }
                pipManager.onPiPStopped = {
                    clipboardManager.stopMonitoring()
                }
            }
        }
    }
}

