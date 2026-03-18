import Foundation
import UIKit
import SwiftUI
import Combine

/// クリップボード履歴の管理を担当するクラス
/// PiP起動中にchangeCountベースで変更を検知し、履歴を蓄積する
class ClipboardManager: ObservableObject {
    @Published var history: [String] = []
    @Published var isMonitoring = false
    
    /// 履歴の最大保持件数
    private let maxHistoryCount = 30
    /// UserDefaultsの保存キー
    private let userDefaultsKey = "ClipboardHistory"
    /// 監視用タイマー
    private var monitorTimer: DispatchSourceTimer?
    /// 前回チェック時のchangeCount（プロンプトなしで取得可能）
    private var lastChangeCount: Int = 0
    /// タイムアウト用タイマー（指定時間後に監視を自動停止）
    private var timeoutTimer: Timer?
    
    init() {
        // 起動時に保存済み履歴を読み込む
        loadHistory()
        // 現在のchangeCountを記録（初回のペーストプロンプトを防ぐ）
        lastChangeCount = UIPasteboard.general.changeCount
    }
    
    /// クリップボードの変更を検知し、変化があった場合のみ内容を読み取る
    /// changeCountのチェックはプロンプトなしで可能
    /// 実際の.string読み取りは変化時のみ = プロンプト発生を最小限に抑える
    func checkClipboard() {
        let currentChangeCount = UIPasteboard.general.changeCount
        
        // changeCountが変わっていなければ何もしない（プロンプトも出ない）
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // changeCountが変化した = 新しいコピーがある → 内容を読み取る
        // ※ユーザーが「常に許可」設定済みならプロンプトは出ない
        guard let pasteboardString = UIPasteboard.general.string else { return }
        let trimmedString = pasteboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        
        // 直前と同じ内容ならスキップ
        if history.first == trimmedString { return }
        
        // 重複があれば古い方を削除
        if let index = history.firstIndex(of: trimmedString) {
            history.remove(at: index)
        }
        
        // 先頭に追加
        history.insert(trimmedString, at: 0)
        
        // 上限を超えたら古いものを削除
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory()
    }
    
    /// PiPからのクリップボード監視を開始する
    /// - Parameter timeoutMinutes: タイムアウト時間（分）。0の場合は制限なし
    func startMonitoring(timeoutMinutes: Int = 0) {
        guard monitorTimer == nil else { return }
        isMonitoring = true
        
        // 監視開始時点のchangeCountを記録
        lastChangeCount = UIPasteboard.general.changeCount
        
        // 3秒ごとにchangeCountをチェック（changeCountチェック自体はプロンプト不要）
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 3.0)
        timer.setEventHandler { [weak self] in
            self?.checkClipboard()
        }
        timer.resume()
        monitorTimer = timer
        
        // タイムアウトが設定されている場合、指定時間後に自動停止
        if timeoutMinutes > 0 {
            timeoutTimer?.invalidate()
            timeoutTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(timeoutMinutes * 60),
                repeats: false
            ) { [weak self] _ in
                self?.stopMonitoring()
            }
        }
    }
    
    /// クリップボード監視を停止する
    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.cancel()
        monitorTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    /// 指定したテキストをクリップボードにコピーする
    func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        // コピー直後のchangeCountを記録（自分のコピーを再検知しないため）
        lastChangeCount = UIPasteboard.general.changeCount
    }
    
    /// 指定インデックスの履歴を削除する
    func deleteItem(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    /// 全履歴を削除する
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    // MARK: - Private Methods
    
    /// 履歴をUserDefaultsに保存する
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: userDefaultsKey)
    }
    
    /// UserDefaultsから履歴を読み込む
    private func loadHistory() {
        if let savedHistory = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            history = savedHistory
        }
    }
}
