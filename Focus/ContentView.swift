import SwiftUI
import AppKit
import UserNotifications

// 不同类型的提示音
enum AlertSoundType {
    case workToBreak    // 工作结束，开始休息
    case breakToWork    // 休息结束，开始工作
    case focusReminder  // 工作期间的10秒提醒
}

struct ContentView: View {
    // 计时器模型，驱动全部计时状态与每秒决策
    @StateObject private var model = TimerModel()

    // 工作期间的随机提醒定时器
    @State private var randomTimer: Timer? = nil

    // 正弦波合成的专用播放器，声音逻辑不再住在视图里
    private let soundPlayer = SoundPlayer()

    // AppDelegate引用，用于更新菜单栏
    @EnvironmentObject var appDelegate: AppDelegate

    var body: some View {
        VStack(spacing: 25) {
            Text("专注计时器")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 计时器显示
            Text(model.formatTime(model.elapsedTime))
                .font(.system(size: 64, weight: .light, design: .monospaced))
                .padding()
                .frame(minWidth: 250)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(model.isWorking ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                )

            // 状态信息
            Text(model.statusMessage)
                .foregroundColor(model.isWorking ? .blue : .green)
                .font(.headline)

            // 控制按钮
            HStack(spacing: 30) {
                Button(action: toggleTimer) {
                    Text(model.isRunning ? "暂停" : "开始")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(model.isRunning ? Color.orange : Color.blue)
                        )
                }

                Button(action: resetTimer) {
                    Text("重置")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red)
                        )
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            // 注入副作用：播放声音与发送通知。模型在每次相位切换时回调。
            model.onPlaySound = { type in
                playAlertSound(type: type)
            }
            model.onSendNotification = { title, body in
                sendNotification(title: title, body: body)
            }
            // 相位切换时，重置工作期间的随机提醒
            model.onPhaseChange = { isWorking in
                if isWorking {
                    scheduleRandomNotification()
                } else {
                    randomTimer?.invalidate()
                }
            }
            // 每个 tick 后同步菜单栏
            model.onTick = {
                updateMenuBarStatus()
            }
            // 首次加载时确保菜单栏状态一致
            updateMenuBarStatus()
        }
    }

    // 根据当前状态更新菜单栏，确保同步
    func updateMenuBarStatus() {
        appDelegate.updateMenuBarTitle(model.menuBarTitle)
    }

    // 播放不同类型的提示音（合成逻辑住在 SoundPlayer 里）
    func playAlertSound(type: AlertSoundType = .focusReminder) {
        soundPlayer.play(type)
    }

    // 通过现代UNUserNotificationCenter发送通知
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }

    // 播放10秒提醒序列
    func play10SecondAlert() {
        // 用焦点提醒声音播放初始哔声
        playAlertSound(type: .focusReminder)

        // 10秒后安排结束哔声
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.model.isRunning && self.model.isWorking {
                self.playAlertSound(type: .focusReminder)
            }
        }
    }

    // 安排工作期间的随机提醒
    func scheduleRandomNotification() {
        randomTimer?.invalidate()

        if model.isRunning && model.isWorking {
            let randomInterval = TimeInterval.random(in: 180...300)

            randomTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
                guard self.model.isRunning && self.model.isWorking else { return }

                // 只播放提醒声音，不发送通知
                self.play10SecondAlert()

                // 安排下一个随机提醒
                self.scheduleRandomNotification()
            }
        }
    }

    // 开始/暂停定时器
    func toggleTimer() {
        model.toggle()

        if model.isRunning {
            // 立即更新菜单栏初始状态
            updateMenuBarStatus()

            // 如果在工作期间，开始随机通知
            if model.isWorking {
                scheduleRandomNotification()
            }
        } else {
            // 暂停定时器
            randomTimer?.invalidate()
            randomTimer = nil

            // 更新菜单栏以显示暂停状态
            updateMenuBarStatus()
        }
    }

    // 重置定时器
    func resetTimer() {
        model.reset()
        randomTimer?.invalidate()
        randomTimer = nil

        // 重置菜单栏
        updateMenuBarStatus()
    }
}
