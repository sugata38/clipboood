import Foundation

/// 監視設定を管理するシングルトンクラス
/// Control Center Controlとメインアプリでタイムアウト設定を共有する
class MonitoringSettings {
    static let shared = MonitoringSettings()
    
    /// UserDefaultsの保存キー（タイムアウト時間）
    private let timeoutKey = "MonitoringTimeoutMinutes"
    
    private init() {}
    
    /// タイムアウト時間（分）。0 = 制限なし
    var timeoutMinutes: Int {
        get {
            // 未設定の場合はデフォルト値5分
            let value = UserDefaults.standard.integer(forKey: timeoutKey)
            return value == 0 && !UserDefaults.standard.bool(forKey: "TimeoutExplicitlySetToZero")
                ? 5
                : value
        }
        set {
            UserDefaults.standard.set(newValue, forKey: timeoutKey)
            // 「制限なし（0分）」が意図的に設定された場合を区別するためのフラグ
            UserDefaults.standard.set(newValue == 0, forKey: "TimeoutExplicitlySetToZero")
        }
    }
}
