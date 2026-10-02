//
//  RegisterViewControllerTests.swift
//  NexoTests
//
//  Created by MMJ on 02/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

// Test de humo del storyboard: si un outlet o una action quedan mal conectados
// La app crashea al abrir la pantalla. Este test lo detecta ANTES de correr la app
@MainActor
final class RegisterViewControllerTests: XCTestCase {
    func test_storyboard_registerScene_loadsWithoutCrashing() throws {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: RegisterViewController.self))
        let sut = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController
        )
        sut.loadViewIfNeeded() // dispara viewDidLoad: aqui explotaria un outlet roto
        XCTAssertEqual(sut.title, "Crear cuenta")
    }
}
