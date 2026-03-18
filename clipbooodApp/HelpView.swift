import SwiftUI

/// 使い方ガイド画面
/// コントロールセンターからの監視開始方法やPiPの挙動を説明する
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // セクション1: クリップボード監視の始め方
                    helpSection(
                        icon: "play.circle.fill",
                        iconColor: .green,
                        title: "監視を開始する"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            stepRow(number: 1, text: "画面右上から下にスワイプして\nコントロールセンターを開く")
                            stepRow(number: 2, text: "「クリップボード監視」ボタンをタップ")
                            stepRow(number: 3, text: "小さなPiP（ピクチャー・イン・ピクチャー）\nウィンドウが表示されれば成功です")
                        }
                    }
                    
                    Divider()
                    
                    // セクション2: コントロールセンターへの追加方法
                    helpSection(
                        icon: "plus.rectangle.on.rectangle",
                        iconColor: .blue,
                        title: "コントロールセンターに追加"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            stepRow(number: 1, text: "コントロールセンターを開く")
                            stepRow(number: 2, text: "何もない場所を長押しして編集モードへ")
                            stepRow(number: 3, text: "「コントロールを追加」をタップ")
                            stepRow(number: 4, text: "clipbooodの「クリップボード監視」を追加")
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
                            bulletRow("監視中は画面上に小さなウィンドウが表示されます")
                            bulletRow("このウィンドウは画面の端にスワイプして隠せます")
                            bulletRow("PiPを閉じると監視も停止します")
                            bulletRow("タイムアウトを設定すると、指定時間後に自動で停止します")
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
                            Text("監視中に「ペーストを許可しますか？」と表示される場合は、以下の設定を行ってください。")
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
