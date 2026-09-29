//
//  User.swift
//  RoadmapSwift
//
//  Created by MMJ on 28/09/26.
//

import Foundation


// Usuario de Nexo
/// - Codable: Se puede leer y escribir como JSON.
/// - Identifiable:  tiene un id unico (lo usaran SwiftUI y las listas diffable)
/// - Hashable: Se puede usar en Set como llave del Dictionary y en Dffable Data Sources
/// - Sendable: Es seguro pasarlo entre hilos/actores (cocurrencia, nivel Senior)
///
nonisolated struct User: Codable, Identifiable, Hashable, Sendable{
    let id: UUID
    let username: String
    var displayName: String // var: el usuario puede cambiar sunombre visible
    let avatarURL: URL? // Optional: no todos tienen foto
    let isVerified: Bool
    var bio: String?
    
    /// Computed property: no se guarda, se calcula cada vez.
    var handle: String {
        "@\(username)"
    }
    
    /// Solo hace falta porque 'avatarURL' no coincide con lo que genera .convertFromSnakeCase
    /// ("avatar_url" -> "avatarUrl") Si declaras CodingKeys, debes listar TODAS las propiedades guardadas
    enum CodinKeys: String, CodingKey {
        case id
        case username
        case displayName
        case avatarURL = "avatarUrl"
        case isVerified
        case bio
    }
}
