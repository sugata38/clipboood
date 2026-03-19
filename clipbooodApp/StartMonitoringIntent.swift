import AppIntents
import WidgetKit

/// クリップボード監視のタイムアウト設定を表す列挙型
/// コントロールセンターでボタン長押し時に表示される設定メニューで使用
enum MonitoringTimeout: String, AppEnum {
    case noTimeout = "noTimeout"
    case fiveMinutes = "fiveMinutes"
    case thirtyMinutes = "thirtyMinutes"
    
    /// コントロールセンターの設定メニューに表示される選択肢の名前
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "タイムアウト"
    
    static var caseDisplayRepresentations: [MonitoringTimeout: DisplayRepresentation] = [
        .noTimeout: "制限なし",
        .fiveMinutes: "5分",
        .thirtyMinutes: "30分"
    ]
    
    /// タイムアウト時間を分単位で返す（0 = 制限なし）
    var minutes: Int {
        switch self {
        case .noTimeout: return 0
        case .fiveMinutes: return 5
        case .thirtyMinutes: return 30
        }
    }
}

/// コントロールセンターのボタンタップ時に実行されるIntent
/// アプリを開いてPiPによるクリップボード監視を開始する
struct StartMonitoringIntent: AppIntent {
    static var title: LocalizedStringResource = "クリップボード自動保存を開始"
    static var description = IntentDescription("clipbooodでクリップボードの自動保存を開始します。")
    
    /// アプリを開く（PiPの起動にはメインアプリのフォアグラウンド化が必須）
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        
        // メインアプリに「PiP起動要求」を通知
        // ※アプリがフォアグラウンドになった時にPiPを起動するフラグを立てる
        UserDefaults.standard.set(true, forKey: "ShouldStartPiP")
        
        return .result()
    }
}
