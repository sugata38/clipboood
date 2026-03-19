import SwiftUI

/// 使い方ガイド画面
/// コントロールセンターからの監視開始方法やPiPの挙動を説明する
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    /// タイムアウト設定用
    @AppStorage("MonitoringTimeoutMinutes") private var timeoutMinutes: Int = 5
    @AppStorage("TimeoutExplicitlySetToZero") private var timeoutExplicitlySetToZero: Bool = false
    
    private var timeoutBinding: Binding<Int> {
        Binding(
            get: {
                if timeoutMinutes == 0 && !timeoutExplicitlySetToZero {
                    return 5 // デフォルト値
                }
                return timeoutMinutes
            },
            set: { newValue in
                timeoutMinutes = newValue
                timeoutExplicitlySetToZero = (newValue == 0)
            }
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // セクション1: コントロールセンターへの追加方法
                    helpSection(
                        icon: "plus.rectangle.on.rectangle",
                        iconColor: .blue,
                        title: "1. コントロールセンターに追加"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            stepRow(number: 1, text: "コントロールセンターを開く")
                            stepRow(number: 2, text: "何もない場所を長押しして編集モードへ")
                            stepRow(number: 3, text: "「コントロールを追加」をタップ")
                            stepRow(number: 4, text: "clipbooodの「クリップボード自動保存」を追加")
                        }
                    }
                    
                    Divider()
                    
                    // セクション2: クリップボード監視の始め方
                    helpSection(
                        icon: "play.circle.fill",
                        iconColor: .green,
                        title: "2. 自動保存を開始する"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            stepRow(number: 1, text: "画面右上から下にスワイプして\nコントロールセンターを開く")
                            stepRow(number: 2, text: "「クリップボード自動保存」ボタンをタップ")
                            stepRow(number: 3, text: "小さなPiP（ピクチャー・イン・ピクチャー）\nウィンドウが表示されれば成功です")
                        }
                    }
                    
                    Divider()
                    
                    // セクション3: PiPウィンドウについて
                    helpSection(
                        icon: "pip",
                        iconColor: .purple,
                        title: "PiPウィンドウについて"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            bulletRow("記録中は画面上に小さなウィンドウが表示されます")
                            bulletRow("このウィンドウは画面の端にスワイプして隠せます")
                            bulletRow("PiPを閉じると自動保存も停止します")
                        }
                    }
                    
                    Divider()
                    
                    // セクション3-2: タイムアウト設定（新規）
                    helpSection(
                        icon: "timer",
                        iconColor: .pink,
                        title: "自動保存の停止時間（タイムアウト）"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("バッテリー消費を防ぐため、指定した時間が経過すると自動保存は自動的に停止します。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("停止までの時間")
                                    .font(.callout.weight(.medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("タイムアウト", selection: timeoutBinding) {
                                    Text("1分").tag(1)
                                    Text("5分").tag(5)
                                    Text("15分").tag(15)
                                    Text("30分").tag(30)
                                    Text("制限なし").tag(0)
                                }
                                .pickerStyle(MenuPickerStyle())
                                .tint(.accentColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                    
                    Divider()
                    
                    // セクション4: ペースト許可の設定
                    helpSection(
                        icon: "hand.raised.circle.fill",
                        iconColor: .orange,
                        title: "確認ダイアログを非表示にする"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("自動保存中に「ペーストを許可しますか？」と表示される場合は、以下の設定を行ってください。")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            stepRow(number: 1, text: "下の「設定を開く」をタップ")
                            stepRow(number: 2, text: "「他のAppからペースト」をタップ")
                            stepRow(number: 3, text: "「許可」を選択")
                            
                            // 設定アプリを開くボタン
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("設定を開く")
                                }
                                .font(.callout.weight(.semibold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                )
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("使い方")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.callout)
                }
            }
        }
    }
    
    // MARK: - コンポーネント
    
    /// セクションのヘッダー付きコンテナ
    private func helpSection<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
            }
            content()
        }
    }
    
    /// 番号付きステップ行
    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /// 箇条書き行
    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.callout)
                .foregroundColor(.secondary)
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
