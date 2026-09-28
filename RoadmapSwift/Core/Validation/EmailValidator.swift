//
//  EmailValidator.swift
//  RoadmapSwift
//
//  Created by MMJ on 27/09/26.
//

import Foundation

/// Errores posibles al validar un email
/// Equatable nos permite compararlos en los test con 'XCTAssertEqual'
nonisolated enum EmailValidationError: Error, Equatable{
    case empty
    case invalidFormat
    
    /// Mensahe listo para mostrar al usuario
    /// 🟢 Swift 5.9+: switch como expresion (sin return en cada case)
    var message: String {
        switch self {
        case .empty: "El correo es obligatorio"
        case .invalidFormat: "El formato del correo no es valido"
        }
    }
}

/// Valida emails. Es un struct (tipo valor): no tiene estado compartido
/// asi que es facil de testear y seguro de usar desde cualquier hilo
nonisolated struct EmailValidator {
    /// Devuelve el email normalizado (sin espacio, en minusculas) o un error
    func validate(_ email: String) -> Result<String, EmailValidationError>{
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .failure(.empty)
        }
        
        // 🟢 Swift Regex (iOS 16+): la expresion se valida al compilar
        let pattern = #/[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/#
        
        guard trimmed.wholeMatch(of: pattern) != nil else {
            return .failure(.invalidFormat)
        }
        
        return .success(trimmed.lowercased())
    }
}
