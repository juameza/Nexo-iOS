//
//  PostContent.swift
//  RoadmapSwift
//
//  Created by MMJ on 28/09/26.
//

import Foundation


/// Contenido de un post. Cada caso tiene sus propios datos (valores asociados)
nonisolated enum PostContent: Hashable, Sendable {
    
    case text(String)
    case image(url: URL, caption: String?)
    case video(url: URL, duration: TimeInterval)
    
    // Tipo que esta version de la app todavia no conoce.
    // Asi una app vieja NO crashea cuando el servidor agrega un tipo nuevo (por ejemplo 'poll')
    case unsupported(type: String)
    
}

// Separate la conformance en una extensión (como hiciste con el delegate en el Dia 1)
nonisolated extension PostContent: Codable {
    /// Las llaves posibles dentro del objeto JSON 'content'
    private enum CodingKeys: String, CodingKey {
        case type, text, url, caption, duration
    }
    
    /// Enum con raw value: convierte "text"/"image"/"video" en un caso con ContentType(rawValue:)
    private enum ContentType: String {
        case text, image, video
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decode(String.self, forKey: .type)
        
        // ContentType(rawValue:) devuelve un Optional: nil si el tipo es desconocido
        switch ContentType(rawValue: rawType){
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .image:
            self = .image(
                url: try container.decode(URL.self, forKey: .url),
                caption: try container.decodeIfPresent(String.self, forKey: .caption)
            )
        case .video:
            self = .video(
                url: try container.decode(URL.self, forKey: .url),
                duration:  try container.decode(TimeInterval.self, forKey: .duration)
            )
        case nil:
            self = .unsupported(type: rawType)
        }
    }
    
    func encode(to encoder: Encoder) throws{
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode(ContentType.text.rawValue, forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let url, let caption):
            try container.encode(ContentType.image.rawValue, forKey: .type)
            try container.encode(url, forKey: .url)
            try container.encodeIfPresent(caption, forKey: .caption)
        case .video(let url, let duration):
            try container.encode(ContentType.video.rawValue, forKey: .type)
            try container.encode(url, forKey: .url)
            try container.encode(duration, forKey: .duration)
        case .unsupported(let type):
            try container.encode(type, forKey: .type)
        }
    }
    
    
}
