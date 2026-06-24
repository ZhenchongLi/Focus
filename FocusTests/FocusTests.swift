//
//  FocusTests.swift
//  FocusTests
//
//  Created by lizc on 2025/5/2.
//

import Foundation
import Testing
@testable import Focus

struct FocusTests {

    @Test func test_version_reads_short_version_string_from_bundle() async throws {
        let info: [String: Any] = ["CFBundleShortVersionString": "9.9.9"]
        #expect(AppVersion.shortVersion(infoDictionary: info) == "9.9.9")
    }

    @Test func test_version_helper_is_only_version_source() async throws {
        // AppVersion is the single source of the marketing version. No source
        // file may keep a hardcoded "1.0.x" literal that can drift from
        // MARKETING_VERSION.
        let testFileURL = URL(fileURLWithPath: #filePath)
        let sourcesRoot = testFileURL
            .deletingLastPathComponent() // FocusTests/
            .deletingLastPathComponent() // worktree root
            .appendingPathComponent("Focus")

        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(
            at: sourcesRoot,
            includingPropertiesForKeys: nil
        )

        let pattern = #"1\.0\.\d+"#
        let regex = try NSRegularExpression(pattern: pattern)

        var offenders: [String] = []
        while let element = enumerator?.nextObject() as? URL {
            guard element.pathExtension == "swift" else { continue }
            let contents = try String(contentsOf: element, encoding: .utf8)
            let range = NSRange(contents.startIndex..., in: contents)
            if regex.firstMatch(in: contents, range: range) != nil {
                offenders.append(element.lastPathComponent)
            }
        }

        #expect(offenders.isEmpty, "Hardcoded marketing-version literal found in: \(offenders)")
    }

    @Test func test_work_phase_completes_into_break() async throws {
        // Recording fakes for the injected side effects.
        final class SoundRecorder {
            var played: [AlertSoundType] = []
        }
        final class NotificationRecorder {
            var sent: [(title: String, body: String)] = []
        }

        let sound = SoundRecorder()
        let notifications = NotificationRecorder()

        let model = TimerModel(
            playSound: { sound.played.append($0) },
            sendNotification: { title, body in notifications.sent.append((title, body)) }
        )
        // Shrink the work duration so the test can reach the boundary quickly.
        model.workTime = 3
        model.isWorking = true
        model.isRunning = true

        // Advance until elapsedTime reaches workTime (3 ticks).
        model.tick()
        model.tick()
        model.tick()

        #expect(model.isWorking == false)
        #expect(model.elapsedTime == 0)
        #expect(sound.played == [.workToBreak])
        #expect(notifications.sent.count == 1)
        #expect(notifications.sent.first?.title == "休息时间")
        #expect(notifications.sent.first?.body == "请休息20分钟")
    }

    @Test func test_break_phase_completes_into_work() async throws {
        // Recording fakes for the injected side effects.
        final class SoundRecorder {
            var played: [AlertSoundType] = []
        }
        final class NotificationRecorder {
            var sent: [(title: String, body: String)] = []
        }

        let sound = SoundRecorder()
        let notifications = NotificationRecorder()

        let model = TimerModel(
            playSound: { sound.played.append($0) },
            sendNotification: { title, body in notifications.sent.append((title, body)) }
        )
        // Shrink the break duration so the test can reach the boundary quickly.
        model.breakTime = 3
        model.isWorking = false
        model.isRunning = true

        // Advance until elapsedTime reaches breakTime (3 ticks).
        model.tick()
        model.tick()
        model.tick()

        #expect(model.isWorking == true)
        #expect(model.elapsedTime == 0)
        #expect(sound.played == [.breakToWork])
        #expect(notifications.sent.count == 1)
        #expect(notifications.sent.first?.title == "工作时间")
        #expect(notifications.sent.first?.body == "开始专注90分钟")
    }

    @Test func test_format_time_renders_hh_mm_ss() async throws {
        let model = TimerModel()
        #expect(model.formatTime(0) == "00:00:00")
        #expect(model.formatTime(5) == "00:00:05")
        #expect(model.formatTime(3661) == "01:01:01")
    }

    @Test func test_menu_title_idle() async throws {
        // A freshly constructed model is idle: not running, elapsedTime == 0.
        let model = TimerModel()
        #expect(model.menuBarTitle == "专注计时器")
    }

    @Test func test_content_view_has_no_test_only_comments() async throws {
        // ContentView must not keep the misleading "测试用" comments that
        // contradict the real durations (90*60, 20*60) and reminder interval
        // (180...300).
        let testFileURL = URL(fileURLWithPath: #filePath)
        let contentViewURL = testFileURL
            .deletingLastPathComponent() // FocusTests/
            .deletingLastPathComponent() // worktree root
            .appendingPathComponent("Focus")
            .appendingPathComponent("ContentView.swift")

        let contents = try String(contentsOf: contentViewURL, encoding: .utf8)
        #expect(!contents.contains("测试用"), "ContentView.swift still contains a misleading 测试用 comment")
    }

}
