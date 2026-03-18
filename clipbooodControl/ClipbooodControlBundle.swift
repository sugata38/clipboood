import WidgetKit
import SwiftUI

/// Widget Extensionのエントリポイント
/// コントロールセンターに表示されるクリップボード監視ボタンを提供する
@main
struct ClipbooodControlBundle: WidgetBundle {
    var body: some Widget {
        ClipboardMonitorControl()
    }
}
