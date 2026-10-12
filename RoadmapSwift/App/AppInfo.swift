//
//  AppInfo.swift
//  RoadmapSwift
//
//  Created by MMJ on 09/10/26.
//

import Foundation


// Versión y build de la app, para la sección "Acerca de"
struct AppInfo: Equatable {
    let version: String
    let build: String
    
    var versionText: String {
        "\(version) (\(build))"
    }
}


extension AppInfo {
    // Recibe el diccionario en lugar de leer Bundle.main adentro -> se puede probar con datos falsos
    init(infoDictionary: [String: Any]?){
        self.init(
            version: infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            build: infoDictionary?["CFBundleVersion"] as? String ?? "?"
        )
    }
    
    // La de la app real: Version y Build  de la pestaña general del target
    static var current: AppInfo{
        AppInfo(infoDictionary: Bundle.main.infoDictionary)
    }

}
