import Foundation
import AVFoundation

// 拥有正弦波合成与音频引擎的专用类型。把原本内联在视图里的合成逻辑搬到这里，
// 数值（频率、谐波、包络、时长）逐字不变。
final class SoundPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    // 启动结果不再被吞掉：要么引擎起来了，要么记录错误，外部可检查。
    private(set) var isEngineRunning = false
    private(set) var lastStartError: Error?

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!)
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            lastStartError = error
            isEngineRunning = false
        }
    }

    // 播放不同类型的提示音
    func play(_ type: AlertSoundType) {
        // 引擎没起来就安静返回，避免在失败后调用时崩溃。
        guard isEngineRunning, engine.isRunning else { return }

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
        player.stop()

        // 播放声音
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }
}
