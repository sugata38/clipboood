import SwiftUI

/// メイン画面 - クリップボード履歴の一覧を表示
/// PiP関連のセットアップは維持するが、自動起動はしない
struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @StateObject private var pipManager = PiPManager()
    /// 触覚フィードバック生成器
    let generator = UIImpactFeedbackGenerator(style: .medium)
    /// コピー完了のトースト表示用フラグ
    @State private var showCopiedToast = false
    /// コピーされたテキスト（トースト表示用）
    @State private var copiedText = ""
    /// 全削除確認ダイアログ表示フラグ
    @State private var showClearConfirmation = false
    /// ヘルプ画面の表示フラグ
    @State private var showHelp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // PiPの基点ビュー（不可視だがPiPシステムに必要）
                PiPHostView(pipManager: pipManager)
                    .frame(width: 1, height: 1)
                    .opacity(0.01) // 0にするとOSがレンダリングをスキップしPiPが起動不可
                
                if clipboardManager.history.isEmpty {
                    // 空状態のガイド表示
                    emptyStateView
                } else {
                    // 履歴一覧
                    historyListView
                }
                
                // コピー完了トースト
                if showCopiedToast {
                    VStack {
                        Spacer()
                        toastView
                            .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: showCopiedToast)
                }
            }
            .navigationTitle("クリップ履歴")
            .toolbar {
                // 左: 監視状態インジケーター
                ToolbarItem(placement: .navigationBarLeading) {
                    if clipboardManager.isMonitoring {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("監視中")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                // 右: ヘルプボタン（小さめ・控えめ）+ 全削除ボタン
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !clipboardManager.history.isEmpty {
                        Button(action: { showClearConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .confirmationDialog(
                "すべての履歴を削除しますか？",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("すべて削除", role: .destructive) {
                    withAnimation {
                        clipboardManager.clearHistory()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .onAppear {
                generator.prepare()
                // PiP開始/停止時のコールバックを設定
                // ※PiP自体はコントロールセンターから起動される
                pipManager.onPiPStarted = {
                    clipboardManager.startMonitoring(
                        timeoutMinutes: MonitoringSettings.shared.timeoutMinutes
                    )
                }
                pipManager.onPiPStopped = {
                    clipboardManager.stopMonitoring()
                }
            }
            // コントロールセンターからのPiP起動要求を受信
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("StartPiPFromControlCenter")
                )
            ) { _ in
                pipManager.startPiP()
            }
        }
    }
    
    // MARK: - サブビュー
    
    /// 空状態のガイド表示
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("クリップ履歴がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("コントロールセンターから")
                Text("「クリップボード監視」を")
                Text("開始してください 📋")
            }
            .font(.subheadline)
            .foregroundColor(.secondary.opacity(0.7))
            .multilineTextAlignment(.center)
            
            // 初回は使い方へ誘導する控えめなリンク
            Button(action: { showHelp = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle")
                    Text("使い方を見る")
                }
                .font(.caption)
                .foregroundColor(.accentColor.opacity(0.8))
            }
            .padding(.top, 8)
        }
    }
    
    /// 履歴リスト
    private var historyListView: some View {
        List {
            ForEach(Array(clipboardManager.history.enumerated()), id: \.offset) { index, text in
                Button(action: {
                    // タップでクリップボードにコピー
                    clipboardManager.copyToClipboard(text: text)
                    generator.impactOccurred()
                    copiedText = String(text.prefix(30))
                    withAnimation { showCopiedToast = true }
                    
                    // 1.5秒後にトーストを非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopiedToast = false }
                    }
                }) {
                    HStack(spacing: 12) {
                        // テキスト番号バッジ
                        Text("\(index + 1)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor.opacity(0.8))
                            .clipShape(Circle())
                        
                        // テキスト内容
                        Text(text)
                            .lineLimit(3)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // コピーアイコン
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10) // 上下パディングで最低60ptのタップ領域を確保
                    .contentShape(Rectangle()) // タップ領域を行全体に拡張
                }
                .buttonStyle(PlainButtonStyle())
            }
            .onDelete { offsets in
                // スワイプ削除
                clipboardManager.deleteItem(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// コピー完了トースト
    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("コピーしました")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
        )
    }
}
