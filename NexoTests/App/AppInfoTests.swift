//
//  AppInfoTests.swift
//  NexoTests
//
//  Created by MMJ on 09/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

@MainActor
final class AppInfoTests: XCTestCase {
    
    func test_init_readsVersionAndBuild() {
        let sut = AppInfo(infoDictionary: ["CFBundleShortVersionString": "1.2", "CFBundleVersion": "34"])
        XCTAssertEqual(sut.versionText, "1.2 (34)")
    }
    
    func test_init_missingKeys_usesQuestionMarks() {
        XCTAssertEqual(AppInfo(infoDictionary: ["":""]).versionText, "? (?)")
    }
}

