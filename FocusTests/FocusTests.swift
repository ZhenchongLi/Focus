//
//  FocusTests.swift
//  FocusTests
//
//  Created by lizc on 2025/5/2.
//

import Testing
@testable import Focus

struct FocusTests {

    @Test func test_version_reads_short_version_string_from_bundle() async throws {
        let info: [String: Any] = ["CFBundleShortVersionString": "9.9.9"]
        #expect(AppVersion.shortVersion(infoDictionary: info) == "9.9.9")
    }

}
