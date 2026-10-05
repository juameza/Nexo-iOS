//
//  PostContent+Preview.swift
//  RoadmapSwift
//
//  Created by MMJ on 05/10/26.
//

import Foundation

// Cómo se ve cada tipo de contenido en el Feed (por ahora solo texto; las imágenes llegan en Mid)
// va en una extensión dentro de Feed/UI porque es un detalle de PRESENTACIÓN, no del modelo.
nonisolated extension PostContent {
    var previewText: String {
        // 🟢 Swift 5.9+: switch como expresión, sin return en cada case
        switch self {
        case .text(let text):
            text
        case .image(_, let caption):
            "🖼️ " + (caption ?? "Foto")
        case .video(_, let duration):
            // 🟢 iOS 16+: Duration + FormatStyle -> 0:42. 🟤 Antes: DateComponentsFormatter.
            "🎬 Video · " + Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
        case .unsupported:
            // Forward compatibility (Dia 2): la app vieja no craseha, avisa.
            "Actualiza Nexo para ver esta publicación"
        }
    }
}
