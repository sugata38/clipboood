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
                    .opacity(0)
                
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        pipManager.togglePiP()
                    }) {
                        Image(systemName: pipManager.isPiPActive ? "pip.fill" : "pip")
                            .foregroundColor(pipManager.isPiPActive ? .green : .primary)
                    }
                }
            }
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

