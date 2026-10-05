//
//  FeedLoader.swift
//  RoadmapSwift
//
//  Created by MMJ on 05/10/26.
//

import Foundation


// Contrato "algo que sabe cargar posts"
// El feed depende de ESTO, no de una clase concreta. Hoy lo cumple 'MockFeedLoader'
// En el nivel Mid lo cumplira un loader que llama a NexoServer, y en los sets, un stub
nonisolated protocol FeedLoader {
    func load() throws -> [Post]
}
