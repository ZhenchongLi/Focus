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
