//
//  JSONDecoder+Nexo.swift
//  RoadmapSwift
//
//  Created by MMJ on 28/09/26.
//

import Foundation


// Una sola configuracion para toda la app: si el servidor cambia el formato de fechas,
// Se corrige en UN lugar
nonisolated extension JSONDecoder {
    static var nexo: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // display_name -> displayName
        decoder.dateDecodingStrategy = .iso8601 // "2026-09-27T10:00:00Z" -> Date
        return decoder
    }
}

nonisolated extension JSONEncoder {
    static var nexo: JSONEncoder{
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
