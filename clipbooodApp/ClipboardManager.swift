import Foundation
import UIKit
import SwiftUI
import Combine

class ClipboardManager: ObservableObject {
    @Published var history: [String] = []
    @Published var isMonitoring = false
    
    private let maxHistoryCount = 30
    private let userDefaultsKey = "ClipboardHistory"
    private var monitorTimer: DispatchSourceTimer?
    
    init() {
        loadHistory()
        checkClipboard()
    }
    
    func checkClipboard() {
        guard let pasteboardString = UIPasteboard.general.string else { return }
        let trimmedString = pasteboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        if history.first == trimmedString { return }
        if let index = history.firstIndex(of: trimmedString) {
            history.remove(at: index)
        }
        history.insert(trimmedString, at: 0)
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        saveHistory()
    }
    
    func startMonitoring() {
        guard monitorTimer == nil else { return }
        isMonitoring = true
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 3.0)
        timer.setEventHandler { [weak self] in
            self?.checkClipboard()
        }
        timer.resume()
        monitorTimer = timer
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.cancel()
        monitorTimer = nil
    }
    
    func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
    }
    
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: userDefaultsKey)
    }
    
    private func loadHistory() {
        if let savedHistory = UserDefaults.standard.stringArray(forKey: userDefaultsKey) {
            history = savedHistory
        }
    }
}
