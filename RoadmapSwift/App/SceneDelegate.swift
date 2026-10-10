//
//  SceneDelegate.swift
//  RoadmapSwift
//
//  Created by MMJ on 26/09/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // Strong: El sceneDelegate es el DUEÑO del router. SI fuera una variable local dentro del metodo.
    // ARC lo liberaria al terminar y el login no haria nada (experimento 7.4)
    private var router: AppRouter?
    


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // 🟢 Creamos la ventana por codigo (🟤 antes la creaba el sistema con el storyboard del Info.plist).
        let window = UIWindow(windowScene: windowScene)
        let router = AppRouter(window: window)
        router.start()  // pone la raiz: login o tabs
        window.makeKeyAndVisible()  // sin esto, pantalla negra
        
        self.window = window
        self.router = router
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("SceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("SceneDidEnterBackground")
    }


}

