//
//  AppRouter.swift
//  RoadmapSwift
//
//  Created by MMJ on 09/10/26.
//

import Foundation
import UIKit
import SwiftUI

// Decide cual es la pantalla RAIZ de la ventana: el login o la app principal (tabs)
// Es el UNICO que cambia window.rootViewContoller Antecesor del patron Coordinator (nivel Mid)
final class AppRouter {
    private let window: UIWindow
    private let session: SessionStore
    
    init(window: UIWindow, session: SessionStore = SessionStore()){
        self.window = window
        self.session = session
    }
    
    // Al abrir la app: si hay sesion guardada. directo a los tabs: si no al Login
    func start(){
        if session.isLoggedIn {
            showMain(animated: false)
        } else {
            showLogin(animated: false)
        }
    }
    
    func logOut(animated: Bool = true){
        session.logOut()
        showLogin(animated: animated)
    }
    
    // MARK: - Pantallas raiz
    private func showLogin(animated: Bool){
        // El login sigue en Main.storyboard 🟤, pero ahora lo carga NUESTRO codigo, no el Info.plist
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateInitialViewController() as? UINavigationController, let login = navigation.viewControllers.first as? LoginViewController else {
            assertionFailure("Main.storyboard: el Initial View Controller debe ser un Navigation Controller con el Login")
            return
        }
        // [weak self]: La ventana -> Login -> esta closure. Si la closure retuviera al router (que retiene la ventana), se cerraria el circulo. Concepto 2
        login.onLogin = { [weak self] email in
            self?.session.logIn(email: email)
            self?.showMain(animated: true)
        }
        setRoot(navigation, animated: animated)
    }
    
    private func showMain(animated: Bool) {
        let tabBar = UITabBarController()
        tabBar.viewControllers = [makeFeedTab(), makeAccountTab()]
        setRoot(tabBar, animated: animated)
    }
    
    // MARK: - Tabs
    private func makeFeedTab() -> UIViewController {
        // Lo mismo que hace showFeed() del Login ayer, pero ahora aqui
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        guard let feed = storyboard.instantiateInitialViewController(creator: { coder in
            FeedViewController(coder: coder, loader: MockFeedLoader())
        }) else {
            assertionFailure("Feed.storyboard no tiene Initial View Controller")
            return UIViewController()
        }
        
        // Cada tab tiene SU PROPIA pila de navegacion
        let navigation = UINavigationController(rootViewController: feed)
        navigation.tabBarItem = UITabBarItem(
            title: "Inicio",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        return navigation
    }
    
    private func makeAccountTab() -> UIViewController {
        let accountView = AccountView(
            email: session.currentEmail ?? "",
            appInfo: .current,
            onLogout: { [weak self] in self?.logOut()}
        )
        
        // 🟢 SwiftUI dentro de UIKit: para el tab bar es un UIViewController mas
        let hosting = UIHostingController(rootView: accountView)
        hosting.tabBarItem = UITabBarItem(
            title: "Cuenta",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        
        return hosting
    }
    
    // MARK: - Helpers
    private func setRoot(_ viewController: UIViewController, animated: Bool){
        // Al reemplazar la raiz, la ventana suelta la pantalla anterior -> ARC la libera (♻️)
        window.rootViewController = viewController
        guard animated else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
