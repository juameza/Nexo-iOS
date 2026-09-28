//
//  EmailValidatorTests.swift
//  NexoTests
//
//  Created by MMJ on 27/09/26.
//


import XCTest
@testable import RoadmapSwift // @testable permite acceder a lo internal de la app

final class EmailValidatorTests: XCTestCase{
    
    // SUT = "System Under Test", (convencion de nombre para lo que se prueba)
    private let sut = EmailValidator()
    
    // Convencion de nombre: test_<metodo>_<escenario>_<resultadoEsperado>
    func test_validate_emptyString_returnsEmptyError() {
        XCTAssertEqual(sut.validate(""), .failure(.empty))
    }
    
    func test_validate_onlyWhitespaces_returnsEmptyError() {
        XCTAssertEqual(sut.validate("   \n "), .failure(.empty))
    }
    
    func test_validate_withoutAt_returnsInvalidFormat(){
        XCTAssertEqual(sut.validate("mario.nexo.com"), .failure(.invalidFormat))
    }
    
    func test_validate_withoutDomain_returnsInvalidFormat() {
        XCTAssertEqual(sut.validate("mario@"), .failure(.invalidFormat))
    }
    
    func test_validate_withoutTLD_returnsInvalidFormat() {
        XCTAssertEqual(sut.validate("mario@nexo"), .failure(.invalidFormat))
    }
    
    func test_validate_validEmail_returnSuccess() {
        XCTAssertEqual(sut.validate("mario@nexo.com"), .success("mario@nexo.com"))
    }
    
    func test_validate_emailWithSpacesAndUppercase_returnsNormalizedEmail() {
        XCTAssertEqual(sut.validate(" Mario@Nexo.com "), .success("mario@nexo.com"))
    }
}


