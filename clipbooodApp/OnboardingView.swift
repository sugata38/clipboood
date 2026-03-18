import SwiftUI

/// 初回起動時に表示される設定誘導画面
/// ペーストプロンプトを回避するための「常に許可」設定と、
/// コントロールセンターへのボタン追加手順をユーザーに案内する
struct OnboardingView: View {
    /// オンボーディング完了フラグ
    @Binding var hasCompletedOnboarding: Bool
    /// 現在表示中のステップ
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // ステップインジケーター
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            TabView(selection: $currentStep) {
                // ステップ1: ようこそ
                welcomeStep
                    .tag(0)
                
                // ステップ2: ペースト許可の設定
                pastePermissionStep
                    .tag(1)
                
                // ステップ3: コントロールセンターの設定
                controlCenterStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // 下部ボタン
            VStack(spacing: 12) {
                if currentStep < 2 {
                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        Text("次へ")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(14)
                    }
                } else {
                    Button(action: {
                        hasCompletedOnboarding = true
                    }) {
                        Text("はじめる")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(14)
                    }
                }
                
                if currentStep < 2 {
                    Button("あとで設定する") {
                        hasCompletedOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - 各ステップのビュー
    
    /// ステップ1: ようこそ画面
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 12) {
                Text("clipboood へようこそ")
                    .font(.largeTitle.weight(.bold))
                
                Text("コピーしたテキストを自動で履歴に保存。\nいつでもワンタップで再利用できます。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    /// ステップ2: ペースト許可の設定案内
    private var pastePermissionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange.gradient)
            
            VStack(spacing: 12) {
                Text("ペースト許可の設定")
                    .font(.title2.weight(.bold))
                
                Text("クリップボード監視中に確認ダイアログが\n表示されないようにするための設定です。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 手順の説明
            VStack(alignment: .leading, spacing: 16) {
                settingStep(number: 1, text: "「設定を開く」をタップ")
                settingStep(number: 2, text: "「他のAppからペースト」をタップ")
                settingStep(number: 3, text: "「許可」を選択")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 8)
            
            // 設定アプリを開くボタン
            Button(action: {
                // 設定アプリのclipboood設定画面を直接開く
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
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                )
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    /// ステップ3: コントロールセンターの設定案内
    private var controlCenterStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "switch.2")
                .font(.system(size: 64))
                .foregroundStyle(.green.gradient)
            
            VStack(spacing: 12) {
                Text("コントロールセンターに追加")
                    .font(.title2.weight(.bold))
                
                Text("クリップボード監視はコントロールセンターの\nボタンから開始します。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                settingStep(number: 1, text: "画面右上から下にスワイプ")
                settingStep(number: 2, text: "長押しして編集モードにする")
                settingStep(number: 3, text: "「コントロールを追加」をタップ")
                settingStep(number: 4, text: "clipbooodの「監視開始」を追加")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 8)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    /// 設定手順の行コンポーネント
    private func settingStep(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.callout)
        }
    }
}
