//
//  FeedLoaderSpy.swift
//  NexoTests
//
//  Created by MMJ on 14/10/26.
//

import XCTest
@testable import RoadmapSwift

// Spy del FeedLoader: no carga nada. Guarda cada peticion y el TEST decide
// cuando y con que  contesta (igual que ImageLoaderSpy Día 6)
final class FeedLoaderSpy: FeedLoader {
    private var completions: [@Sendable (Result<[Post], Error>) -> Void] = []
    
    // cuantas veces nos pidieron el feed
    var requestCount: Int { completions.count }
    
    func load(completion: @escaping @Sendable (Result<[Post], Error>) -> Void) {
        completions.append(completion)
    }
    
    // Simula que llegó la respuesta de la petición numero Index
    func complete(with result: Result<[Post], Error>, at index: Int = 0){
        guard completions.indices.contains(index) else {
            return XCTFail("No hay peticion #\(index): solo se pidio el feed \(requestCount) veces")
        }
        completions[index](result)
        
    }
}
