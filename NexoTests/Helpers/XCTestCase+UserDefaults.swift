//
//  XCTestCase+UserDefaults.swift
//  NexoTests
//
//  Created by MMJ on 09/10/26.
//

import Foundation
import XCTest

extension XCTestCase {
    // Un UserDefaults NUEVO y vacio para cada test, que se borra al terminar.
    // Si los tests usaran .standard, se mezclarian con los datos de la app (y entre ellos)
    func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "NexoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!  // solo devuelve nil con nombres reservados
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
    
}
