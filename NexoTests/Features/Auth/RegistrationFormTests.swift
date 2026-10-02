//
//  RegistrationFormTests.swift
//  RoadmapSwift
//
//  Created by MMJ on 02/10/26.
//

import XCTest
@testable import RoadmapSwift

final class RegistrationFormTests: XCTestCase {
    func test_validate_validForm_returnsNormalizedAccount() {
        var form = RegistrationForm.valid
        form.displayName = "   Ana    "
        form.email = " Ana@Nexo.APP "
        XCTAssertEqual(form.validate(), .success(NewAccount(displayName: "Ana", email: "ana@nexo.app")))
    }
    
    func test_validate_blankName_returnsEmptyName() {
        var form = RegistrationForm.valid
        form.displayName = "    "
        XCTAssertEqual(form.validate(), .failure(.emptyName))
    }
    
    func test_validate_invalidEmail_wrapsEmailError() {
        var form = RegistrationForm.valid
        form.email = "ana@"
        XCTAssertEqual(form.validate(), .failure(.invalidEmail(.invalidFormat)))
    }
    
    func test_validate_weakPassword_returnsFailedRules() {
        var form = RegistrationForm.valid
        form.password = "nexonexo"
        form.passwordConfirmation = "nexonexo"
        XCTAssertEqual(form.validate(), .failure(.weakPassword([.uppercase, .number])))
    }
    
    func test_validate_differentConfirmation_returnsPasswordsDoNotMatch(){
        var form = RegistrationForm.valid
        form.passwordConfirmation = "Nexo2027"
        XCTAssertEqual(form.validate(), .failure(.passwordsDoNotMatch))
    }
    
    func test_validate_severalErrors_returnsFirstOne(){
        let form = RegistrationForm() // todo vacio
        XCTAssertEqual(form.validate(), .failure(.emptyName))
    }
    
}

// MARK: - Fixture
extension RegistrationForm {
    // Un formulario valido, Cada test lo COPIA (es struct) y cambia y solo un campo
    static let valid = RegistrationForm(
        displayName: "Ana",
        email: "ana@nexo.app",
        password: "Nexo2026",
        passwordConfirmation: "Nexo2026"
    )
}
