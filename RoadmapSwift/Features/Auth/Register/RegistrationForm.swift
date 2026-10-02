//
//  RegistrationForm.swift
//  RoadmapSwift
//
//  Created by MMJ on 01/10/26.
//

import Foundation


// Datos ya validados y normalizados, listos para mandarse al servidor (Dia - 60)
nonisolated struct NewAccount: Equatable, Sendable {
    let displayName: String
    let email: String
}

// Errores del formulario de registro.
nonisolated enum RegistrationError: Error, Equatable {
    case emptyName
    // Envuelve el error de OTRO validador: reutilizamos EmailValidator sin duplicar sus reglas
    case invalidEmail(EmailValidationError)
    // Lleva la lista de reglas que fallaron
    case weakPassword([PasswordRule])
    case passwordsDoNotMatch
    
    var message: String {
        switch self {
        case .emptyName: "El nombre es obligatorio"
        case .invalidEmail(let error): error.message
        case .weakPassword(let rules): "La contraseña necesita: " + rules.map(\.message).joined(separator: " - ")
        case .passwordsDoNotMatch: "Las contraseñas no coinciden"
            
        }
    }
}

// Lo que el usuario escribio en el formulario, todavia SIN validar
// La lógica vive aqui y no en el view controller: asi se prueba sin abrir ninguna pantalla
nonisolated struct RegistrationForm {
    var displayName = ""
    var email = ""
    var password = ""
    var passwordConfirmation = ""
    
    // Valida en orden y devuelve el PRIMER error, que es el que mostrará la pantalla
    // Los validadores llegan como parametros con valor por defecto (inyeccion de dependencias)
    func validate(emailValidator: EmailValidator = EmailValidator(), passwordValidator: PasswordValidator = PasswordValidator()) -> Result<NewAccount, RegistrationError>{
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return .failure(.emptyName)
        }
        
        let validEmail: String
        switch emailValidator.validate(email) {
        case .success(let normalized):
            validEmail = normalized
        case .failure(let error):
            return .failure(.invalidEmail(error))
        }
        
        let failedRules = passwordValidator.failedRules(for: password)
        guard failedRules.isEmpty else {
            return .failure(.weakPassword(failedRules))
        }
        
        guard password == passwordConfirmation else {
            return .failure(.passwordsDoNotMatch)
        }
        
        return .success(NewAccount(displayName: name, email: validEmail))
    }
    
    
    
    
}
