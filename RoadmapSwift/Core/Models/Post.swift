//
//  Post.swift
//  RoadmapSwift
//
//  Created by MMJ on 28/09/26.
//

import Foundation

nonisolated struct Post: Codable, Identifiable, Hashable, Sendable{
    let id: UUID
    let author: User // Composicion: un Post contiene un User
    let content: PostContent
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var isLikedByMe: Bool
    
    /// mutating: es un struct, un método que cambia propiedades debe marcarse asi
    /// Solo se puede llamar sobre un var, nunca sobre un let
    mutating func toggleLike() {
        isLikedByMe.toggle()
        likeCount += isLikedByMe ? 1 : -1
    }
    
    /// 🟢 iOS 15+: FormatStyle ("hace 2 dias")
    /// 🟤 Antes: DateFormatter / RelativeDateTimeFormatter (costosos de crear, habia que cachearlos)
    var relativeCreatedAt: String {
        createdAt.formatted(.relative(presentation: .named))
    }
}

/// La forma de la respuesta del servidor: {"post": [....]}
nonisolated struct FeedResponse: Decodable, Sendable {
    let posts: [Post]
}
