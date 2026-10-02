//
//  PasswordValidator.swift
//  RoadmapSwift
//
//  Created by MMJ on 01/10/26.
//

import Foundation


/// Regla de contraseña de Nexo
/// CaseIterable: Swift genera PasswordRule.allCases con todos los casos
nonisolated enum PasswordRule: CaseIterable, Equatable, Sendable {
    case minLength
    case uppercase
    case number
    
    static let minimumLength = 8
    
    // Texto para mostrar al usuario
    var message: String {
        switch self {
        case .minLength: "Mínimo \(Self.minimumLength) caracteres"
        case .uppercase: "Al menos una mayúscula"
        case .number: "Al menos un número"
        }
    }
    
    
    // Cada regla sabe validarse a si misma.
    func isSatisfied(by password: String) -> Bool {
        switch self {
            // count cuenta CARACTERES, que ve el usuario (👍 = 1), no bytes
        case .minLength: password.count >= Self.minimumLength
            // \.isUppercase es un key path usado como closure: igual que  {$0.isUppercase }
        case .uppercase: password.contains(where: \.isUppercase)
        case .number: password.contains(where: \.isNumber)
        }
    }
}

// Valida contraseñas, Igual que EmailValidator: struct sin estado, nonisolated
nonisolated struct PasswordValidator {
    // Devuelve las reglas que NO se cumplen. Un arreglo vacio significa valida
    func failedRules(for password: String) -> [PasswordRule] {
        PasswordRule.allCases.filter { rule in !rule.isSatisfied(by: password)}
    }
}
