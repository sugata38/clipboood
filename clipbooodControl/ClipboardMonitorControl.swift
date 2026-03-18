import WidgetKit
import SwiftUI

/// コントロールセンターに表示されるクリップボード監視ボタン
/// タップ: 監視を開始（アプリを開いてPiPを起動）
/// 長押し: タイムアウト設定のメニューを表示
struct ClipboardMonitorControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        // AppIntentControlConfiguration: 設定可能なパラメーター付きのコントロール
        AppIntentControlConfiguration(
            kind: "com.miyake.clipbooodApp.monitor",
            intent: StartMonitoringIntent.self
        ) { configuration in
            ControlWidgetButton(action: configuration) {
                // コントロールセンターに表示されるラベル
                Label("クリップボード自動保存", systemImage: "clipboard")
            }
        }
        .displayName("クリップボード自動保存")
        .description("clipbooodでクリップボードの自動保存を開始します。")
    }
}
