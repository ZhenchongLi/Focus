import SwiftUI
import AppKit
import UserNotifications
import AVFoundation

// 不同类型的提示音
enum AlertSoundType {
    case workToBreak    // 工作结束，开始休息
    case breakToWork    // 休息结束，开始工作
    case focusReminder  // 工作期间的10秒提醒
}

struct ContentView: View {
    // 计时器状态
    @State private var isRunning = false
    @State private var isWorking = true
    @State private var elapsedTime: TimeInterval = 0
    @State private var workTime: TimeInterval = 90*60 // 30秒测试用，实际应为 90*60
    @State private var breakTime: TimeInterval = 20*60 // 30秒测试用，实际应为 20*60

    // 计时器引用
    @State private var timer: Timer? = nil
    @State private var randomTimer: Timer? = nil

    // UI状态
    @State private var statusMessage = "准备开始"

    // AppDelegate引用，用于更新菜单栏
    @EnvironmentObject var appDelegate: AppDelegate

    var body: some View {
        VStack(spacing: 25) {
            Text("专注计时器")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 计时器显示
            Text(formatTime(seconds: elapsedTime))
                .font(.system(size: 64, weight: .light, design: .monospaced))
                .padding()
                .frame(minWidth: 250)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isWorking ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                )

            // 状态信息
            Text(statusMessage)
                .foregroundColor(isWorking ? .blue : .green)
                .font(.headline)

            // 控制按钮
            HStack(spacing: 30) {
                Button(action: toggleTimer) {
                    Text(isRunning ? "暂停" : "开始")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isRunning ? Color.orange : Color.blue)
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
            // 首次加载时确保菜单栏状态一致
            updateMenuBarStatus()
        }
    }

    // 格式化秒数为 HH:MM:SS
    func formatTime(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // 根据当前状态更新菜单栏，确保同步
    func updateMenuBarStatus() {
        if !isRunning {
            if elapsedTime == 0 {
                // 重置状态
                appDelegate.updateMenuBarTitle("专注计时器")
            } else {
                // 暂停状态
                appDelegate.updateMenuBarTitle("专注计时器 - 已暂停")
            }
        } else {
            // 运行中状态
            let stateText = isWorking ? "工作中" : "休息中"
            appDelegate.updateMenuBarTitle("\(stateText): \(formatTime(seconds: elapsedTime))")
        }
    }

    // 播放不同类型的提示音
    func playAlertSound(type: AlertSoundType = .focusReminder) {
        // 单例音频引擎，防止创建多个实例
        struct AudioEngineManager {
            static var shared = AVAudioEngine()
            static var player = AVAudioPlayerNode()
            static var isSetup = false

            static func setup() {
                if !isSetup {
                    shared.attach(player)
                    shared.connect(player, to: shared.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!)
                    try? shared.start()
                    isSetup = true
                }
            }
        }

        // 设置引擎（如果需要）
        AudioEngineManager.setup()

        // 基于类型的不同声音参数
        let sampleRate = 44100.0
        let duration = 1.0  // 所有声音持续1秒

        // 基于类型的不同声音特性
        var frequency: Double
        var amplitude: Float

        switch type {
        case .workToBreak:
            // 开始休息的放松声音（较低音调）
            frequency = 440.0  // A4音符
            amplitude = 0.8
        case .breakToWork:
            // 开始工作的有活力声音（较高音调）
            frequency = 880.0  // A5音符
            amplitude = 0.8
        case .focusReminder:
            // 独特的提醒声音（不同音符）
            frequency = 659.25  // E5音符
            amplitude = 0.75
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleRate * duration))!

        let data = buffer.floatChannelData?[0]
        let numberOfFrames = Int(sampleRate * duration)

        // 用基于类型的不同特性填充正弦波缓冲区
        for frame in 0..<numberOfFrames {
            // 基本正弦波
            var value = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)

            // 基于类型添加谐波，使声音更有趣
            switch type {
            case .workToBreak:
                // 添加柔和谐波以获得愉悦的声音
                value += 0.3 * sin(2.0 * .pi * (frequency * 2) * Double(frame) / sampleRate)
            case .breakToWork:
                // 添加更强谐波以获得引人注目的声音
                value += 0.5 * sin(2.0 * .pi * (frequency * 1.5) * Double(frame) / sampleRate)
                value = value * (sin(2.0 * .pi * 8 * Double(frame) / sampleRate) * 0.2 + 0.8) // 添加脉冲
            case .focusReminder:
                // 添加频率扫描以获得与众不同的声音
                let sweep = 0.1 * sin(2.0 * .pi * 2 * Double(frame) / sampleRate)
                value = sin(2.0 * .pi * (frequency * (1.0 + sweep)) * Double(frame) / sampleRate)
            }

            // 归一化以避免裁剪
            value = max(min(value, 1.0), -1.0)

            // 添加淡入淡出以避免爆音
            let envelope = min(Float(frame) / 1000.0, Float(numberOfFrames - frame) / 1000.0, 1.0)
            data?[frame] = Float(value) * amplitude * envelope
        }

        buffer.frameLength = AVAudioFrameCount(numberOfFrames)

        // 停止任何当前播放
        AudioEngineManager.player.stop()

        // 播放声音
        AudioEngineManager.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        AudioEngineManager.player.play()
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
            if self.isRunning && self.isWorking {
                self.playAlertSound(type: .focusReminder)
            }
        }
    }

    // 安排工作期间的随机通知
    func scheduleRandomNotification() {
        randomTimer?.invalidate()

        if isRunning && isWorking {
            // 测试用15秒间隔，实际应该是180-300秒之间的随机时间
            let randomInterval = TimeInterval.random(in: 180...300)

            randomTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { _ in
                guard self.isRunning && self.isWorking else { return }

                // 播放提醒序列
                self.play10SecondAlert()

                // 显示通知
                self.sendNotification(title: "专注提醒", body: "保持专注！")

                // 安排下一个随机通知
                self.scheduleRandomNotification()
            }
        }
    }

    // 开始/暂停定时器
    func toggleTimer() {
        isRunning.toggle()

        if isRunning {
            // 开始主定时器
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.elapsedTime += 1

                // 更新菜单栏状态
                self.updateMenuBarStatus()

                // 检查工作周期是否完成
                if self.isWorking && self.elapsedTime >= self.workTime {
                    self.isWorking = false
                    self.elapsedTime = 0
                    self.statusMessage = "休息时间！"
                    self.playAlertSound(type: .workToBreak)  // 播放工作到休息的声音

                    self.sendNotification(title: "休息时间", body: "请休息20分钟")

                    // 在休息期间清除随机定时器
                    self.randomTimer?.invalidate()

                    // 立即更新菜单栏以同步状态
                    self.updateMenuBarStatus()
                }
                // 检查休息周期是否完成
                else if !self.isWorking && self.elapsedTime >= self.breakTime {
                    self.isWorking = true
                    self.elapsedTime = 0
                    self.statusMessage = "工作时间！"
                    self.playAlertSound(type: .breakToWork)  // 播放休息到工作的声音

                    self.sendNotification(title: "工作时间", body: "开始专注90分钟")

                    // 为工作期间重新开始随机通知
                    self.scheduleRandomNotification()

                    // 立即更新菜单栏以同步状态
                    self.updateMenuBarStatus()
                }
            }

            // 更新状态
            statusMessage = isWorking ? "工作中..." : "休息中..."

            // 立即更新菜单栏初始状态
            updateMenuBarStatus()

            // 如果在工作期间，开始随机通知
            if isWorking {
                scheduleRandomNotification()
            }
        } else {
            // 暂停定时器
            timer?.invalidate()
            timer = nil
            randomTimer?.invalidate()
            randomTimer = nil
            statusMessage = "已暂停"

            // 更新菜单栏以显示暂停状态
            updateMenuBarStatus()
        }
    }

    // 重置定时器
    func resetTimer() {
        // 停止定时器
        timer?.invalidate()
        timer = nil
        randomTimer?.invalidate()
        randomTimer = nil

        // 重置状态
        isRunning = false
        isWorking = true
        elapsedTime = 0
        statusMessage = "准备开始"

        // 重置菜单栏
        updateMenuBarStatus()
    }
}
