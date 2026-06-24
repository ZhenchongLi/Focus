import Foundation

// Drives the focus/break timer independently of any SwiftUI view, so the
// per-tick phase logic can be exercised in a unit test without a run loop,
// an audio device, or the notification center. The two untestable side
// effects (play a sound, send a notification) are injected.
final class TimerModel: ObservableObject {
    // 计时器状态
    @Published var isRunning = false
    @Published var isWorking = true
    @Published var elapsedTime: TimeInterval = 0
    var workTime: TimeInterval = 90*60
    var breakTime: TimeInterval = 20*60

    @Published var statusMessage = "准备开始"

    // Injected side effects. Production wires these to the real audio output
    // and UNUserNotificationCenter; tests wire recorders. They are mutable so
    // a SwiftUI view can wire them in onAppear after constructing the model
    // with the default initializer.
    var onPlaySound: (AlertSoundType) -> Void
    var onSendNotification: (String, String) -> Void
    // Fired after every tick (used by the view to sync the menu bar) and on
    // every phase boundary (used by the view to reset the random reminder).
    var onTick: () -> Void = {}
    var onPhaseChange: (Bool) -> Void = { _ in }

    init(
        playSound: @escaping (AlertSoundType) -> Void = { _ in },
        sendNotification: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.onPlaySound = playSound
        self.onSendNotification = sendNotification
    }

    // 计时器引用
    private var timer: Timer?

    // The per-tick decision, moved verbatim out of the Timer closure so a
    // test can advance the model without waiting real seconds.
    func tick() {
        elapsedTime += 1

        // 检查工作周期是否完成
        if isWorking && elapsedTime >= workTime {
            isWorking = false
            elapsedTime = 0
            statusMessage = "休息时间！"
            onPlaySound(.workToBreak)  // 播放工作到休息的声音
            onSendNotification("休息时间", "请休息20分钟")
            onPhaseChange(isWorking)
        }
        // 检查休息周期是否完成
        else if !isWorking && elapsedTime >= breakTime {
            isWorking = true
            elapsedTime = 0
            statusMessage = "工作时间！"
            onPlaySound(.breakToWork)  // 播放休息到工作的声音
            onSendNotification("工作时间", "开始专注90分钟")
            onPhaseChange(isWorking)
        }

        onTick()
    }

    // 开始/暂停定时器
    func toggle() {
        isRunning.toggle()

        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
            statusMessage = isWorking ? "工作中..." : "休息中..."
        } else {
            timer?.invalidate()
            timer = nil
            statusMessage = "已暂停"
        }
    }

    // 重置定时器
    func reset() {
        timer?.invalidate()
        timer = nil

        isRunning = false
        isWorking = true
        elapsedTime = 0
        statusMessage = "准备开始"
    }

    // 格式化秒数为 HH:MM:SS
    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    // 根据当前状态返回菜单栏标题
    var menuBarTitle: String {
        if !isRunning {
            if elapsedTime == 0 {
                return "专注计时器"
            } else {
                return "专注计时器 - 已暂停"
            }
        } else {
            let stateText = isWorking ? "工作中" : "休息中"
            return "\(stateText): \(formatTime(elapsedTime))"
        }
    }
}
