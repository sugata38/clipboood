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
    /// タップされた履歴項目のテキスト（ハイライトエフェクト用）
    @State private var tappedText: String?
    
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
                // 右: ヘルプボタン + 全削除ボタン
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    if !clipboardManager.history.isEmpty {
                        Button(action: { showClearConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.body)
                                .foregroundColor(.red.opacity(0.8))
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
                // スクショ制作用の一時コード: 起動と同時にPiPを開始
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    pipManager.startPiP()
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
                Text("「自動保存」を")
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
            // 自動保存ステータスをリストのヘッダーとして表示（見切れ防止）
            if clipboardManager.isMonitoring {
                Section {
                    EmptyView()
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .symbolEffect(.pulse)
                        Text("自動保存中")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .textCase(nil)
                    .padding(.bottom, 4)
                }
            }
            
            Section {
                // idを\.selfにすることで、配列の並び替え時に要素が上下にスライド移動するアニメーションが自然になります
                ForEach(clipboardManager.history, id: \.self) { text in
                Button(action: {
                    // タップを即座にフィードバック
                    generator.impactOccurred()
                    copiedText = String(text.prefix(30))
                    
                    // タップされた元の位置で色を変える
                    withAnimation(.easeInOut(duration: 0.1)) {
                        tappedText = text
                    }
                    
                    withAnimation { showCopiedToast = true }
                    
                    // エフェクトが終わってワンテンポ経ってから移動＆コピー実行（0.35秒後）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        // ここで初めて一番上への移動とクリップボード書き込みが走る
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            clipboardManager.copyToClipboard(text: text)
                        }
                        
                        // ハイライトを解除
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tappedText = nil
                        }
                    }
                    
                    // 1.5秒後にトーストを非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopiedToast = false }
                    }
                }) {
                    Text(text)
                        .lineLimit(3)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle()) // タップ領域を行全体に拡張
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(tappedText == text ? Color.gray.opacity(0.3) : Color(UIColor.secondarySystemGroupedBackground))
            }
            .onDelete { offsets in
                // スワイプ削除
                clipboardManager.deleteItem(at: offsets)
            }
            } // End of Section
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
