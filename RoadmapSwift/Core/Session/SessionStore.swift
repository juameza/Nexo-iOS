//
//  SessionStore.swift
//  RoadmapSwift
//
//  Created by MMJ on 09/10/26.
//

import Foundation


// Guarda QUIÉN inició sesión, para que al reabrir la app no se pida login otra vez.
// 🟤 UserDefaults: solo datos pequeños y NO sensibles. El token JWT ira al Keychain (nivel Mid)
struct SessionStore{
    // Las claves en UN solo lugar: un typo en un String no lo detecta el compilador
    private enum Key {
        static let currentEmail = "session.currentEmail"
        
        
    }
    
    // Inyectado por init: la app usa .standard y los tests un UserDefaults aislado
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
    }
    
    var currentEmail: String? {
        defaults.string(forKey: Key.currentEmail)
    }
    
    var isLoggedIn: Bool{
        currentEmail != nil
    }
    
    // NO es mutating aunque cambia algo: lo que cambia es el UserDefaults (una CLASE, osea una referencia)
    // no las propiedades de este struct
    func logIn(email: String){
        defaults.set(email, forKey: Key.currentEmail)
    }
    
    func logOut(){
        defaults.removeObject(forKey: Key.currentEmail)
    }
}
