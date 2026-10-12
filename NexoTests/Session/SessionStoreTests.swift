//
//  SessionStoreTests.swift
//  NexoTests
//
//  Created by MMJ on 09/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

@MainActor
final class SessionStoreTests: XCTestCase {
    func test_newStore_isLoggedOut(){
        let sut = SessionStore(defaults: makeIsolatedDefaults())
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.currentEmail)
    }
    
    func test_logIn_savesEmail() {
        let sut = SessionStore(defaults: makeIsolatedDefaults())
        sut.logIn(email: "ana@nexo.app")
        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertEqual(sut.currentEmail, "ana@nexo.app")
    }
    
    func test_logOut_removesEmail() {
        let sut = SessionStore(defaults: makeIsolatedDefaults())
        sut.logIn(email: "ana@nexo.app")
        sut.logOut()
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.currentEmail)
    }
    
    // Simula cerrar y volver a abrir la app: otra instancia, mismo almacenamiento
    func test_session_persistsAcrossInstances() {
        let defaults = makeIsolatedDefaults()
        SessionStore(defaults: defaults).logIn(email: "ana@nexo.app")
        let reopened = SessionStore(defaults: defaults)
        XCTAssertEqual(reopened.currentEmail, "ana@nexo.app")
    }
}
