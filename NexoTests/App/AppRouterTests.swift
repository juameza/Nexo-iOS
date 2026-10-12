//
//  AppRouterTests.swift
//  NexoTests
//
//  Created by MMJ on 09/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

@MainActor
final class AppRouterTests: XCTestCase {
    
    func test_start_withoutSession_showsLogin() throws {
        let (sut, window, _) = makeSUT()
        sut.start()
        let navigation = try XCTUnwrap(window.rootViewController as? UINavigationController)
        XCTAssertTrue(navigation.viewControllers.first is LoginViewController)
    }
    
    func test_start_withSession_showsInicioAndCuentaTabs() throws {
        let (sut, window, _) = makeSUT(loggedInAs: "ana@nexo.app")
        sut.start()
        let tabBar = try XCTUnwrap(window.rootViewController as? UITabBarController)
        // \.tabBarItem.title: un key path usado como closure (lo viste en el Dia 3)
        XCTAssertEqual(tabBar.viewControllers?.map(\.tabBarItem.title), ["Inicio", "Cuenta"])
    }
    
    func test_login_savesSessionAndShowsTabs() throws {
        let (sut, window, session) = makeSUT()
        sut.start()
        let navigation = try XCTUnwrap(window.rootViewController as? UINavigationController)
        let login = try XCTUnwrap(navigation.viewControllers.first as? LoginViewController)
        
        login.onLogin?("ana@nexo.app") // Simulamos que el login avisó
        
        XCTAssertEqual(session.currentEmail, "ana@nexo.app")
        XCTAssertTrue(window.rootViewController is UITabBarController)
        
        
    }
    
    func test_logOut_clearsSessionAndShowsLogin() throws {
        let (sut, window, session) = makeSUT(loggedInAs: "ana@nexo.app")
        sut.start()
        sut.logOut(animated: false)
        
        XCTAssertFalse(session.isLoggedIn)
        let navigation = try XCTUnwrap(window.rootViewController as? UINavigationController)
        XCTAssertTrue(navigation.viewControllers.first is LoginViewController)
    }
    
    // MARK: - Helpers
    private func makeSUT(loggedInAs email: String? = nil) -> (AppRouter, UIWindow, SessionStore) {
        let session = SessionStore(defaults: makeIsolatedDefaults())
        if let email { session.logIn(email: email) }
        // Una ventana suelta (sin escena): suficiente para revisar quien es la raiz.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let sut = AppRouter(window: window, session: session)
        // ⚠️ Si una closure (onLogin / onLogout) retiene al router con strong, esto falla.
        assertNoMemoryLeak(sut)
        return (sut, window, session)
    }
}
