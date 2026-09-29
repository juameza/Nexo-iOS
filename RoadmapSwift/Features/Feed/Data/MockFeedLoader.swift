//
//  MockFeedLoader.swift
//  RoadmapSwift
//
//  Created by MMJ on 28/09/26.
//

import Foundation


// Errores propios del loader: más claros que los errores genéricos del sistema
nonisolated enum FeedLoaderError: Error, Equatable {
    case fileNotFound(String)
    case decondingFailed(String)
}


// Lee el feed desde un JSON dentro de la app.
// Recibe bundle y fileName en el init (inyeccion de dependencias por init):
// Asi en los tests podemos pedirle un archivo que NO existe y probar el error.
nonisolated struct MockFeedLoader {
    private let bundle: Bundle
    private let fileName: String
    
    init(bundle: Bundle = .main, fileName: String = "feed") {
        self.bundle = bundle
        self.fileName = fileName
    }
    
    // throws: esta función puede fallar y quien le llame DEBE usar try
    func load() throws -> [Post] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw FeedLoaderError.fileNotFound(fileName)
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder.nexo.decode(FeedResponse.self, from: data).posts
        } catch {
            // String(describing:) conserva el detalle: QUÉ llave faltó y en QUÉ posición
            throw FeedLoaderError.decondingFailed(String(describing: error))
        }
    }
}
