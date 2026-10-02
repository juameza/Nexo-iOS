//
//  PasswordValidatorTests.swift
//  NexoTests
//
//  Created by MMJ on 02/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

final class PasswordValidatorTests: XCTestCase {
    private let sut = PasswordValidator()
    
    func test_failedRules_validPassword_returnsEmpty() {
        XCTAssertEqual(sut.failedRules(for: "Nexo2026"), [])
        
    }
    
    func test_failedRules_emptyPassword_returnsAllRules() {
        XCTAssertEqual(sut.failedRules(for: ""), PasswordRule.allCases)
    }
    
    func test_failedRules_shortPassword_returnsMinLength() {
        XCTAssertEqual(sut.failedRules(for: "Ab1"), [.minLength])
    }
    
    func test_failedRules_withoutUppercase_returnsUppercase(){
        XCTAssertEqual(sut.failedRules(for: "nexo2026"), [.uppercase])
    }
    
    func test_failedRules_withoutNumber_returnsNumber(){
        XCTAssertEqual(sut.failedRules(for: "NexoNexo"), [.number])
    }
    
    // 7 caracteres visibles, pero 11 unidades UTF-16 (cada 👍 ocupa 2)
    // Si contaramos con NSString(🟤 length) esta contraseña pasaria
    func test_failedRules_emojis_countAsOneCharacterEach(){
        let password = "Ab1👍👍👍👍"
        XCTAssertEqual(password.count, 7)
        XCTAssertEqual(password.utf16.count, 11)
        XCTAssertEqual(sut.failedRules(for: password), [.minLength])
    }
}
