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

/// コントロールセンターのボタンタップ時に実行されるAppIntent
/// アプリを開いてPiPによるクリップボード監視を開始する
struct StartMonitoringIntent: AppIntent {
    static var title: LocalizedStringResource = "クリップボード監視を開始"
    static var description = IntentDescription("clipbooodでクリップボードの監視を開始します。")
    
    /// アプリを開く（PiPの起動にはフォアグラウンドが必要）
    static var openAppWhenRun: Bool = true
    
    /// タイムアウト設定パラメーター
    /// コントロールセンターで長押し時に表示される設定メニュー
    @Parameter(title: "タイムアウト", default: .fiveMinutes)
    var timeout: MonitoringTimeout
    
    func perform() async throws -> some IntentResult {
        // タイムアウト設定を保存（メインアプリが読み取る）
        UserDefaults.standard.set(timeout.minutes, forKey: "MonitoringTimeoutMinutes")
        UserDefaults.standard.set(timeout.minutes == 0, forKey: "TimeoutExplicitlySetToZero")
        
        // メインアプリに「PiP起動要求」を通知
        // ※アプリがフォアグラウンドになった時にPiPを起動するフラグを立てる
        UserDefaults.standard.set(true, forKey: "ShouldStartPiP")
        
        return .result()
    }
}
