//
//  ImageLoaderSpy.swift
//  NexoTests
//
//  Created by MMJ on 12/10/26.
//

import UIKit
@testable import RoadmapSwift

// SPY: no descarga nada. Anota que le pidieron y que le cancelaron
// y el TEST decide cuando llega la imagen con complete(...)
final class ImageLoaderSpy: ImageLoader {
    private(set) var requests: [(url: URL, completion: @Sendable (Result<UIImage, Error>) -> Void)] = []
    private(set) var cancelledURLs: [URL] = []
    
    var requestedURLs: [URL] { requests.map(\.url) }
    
    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) -> ImageLoadTask{
        requests.append((url, completion))
        return TaskSpy {[weak self] in self?.cancelledURLs.append(url)}
    }
    
    // Simula que llegó la respuesta de la petición numero index
    func complete(with image: UIImage, at index: Int = 0) {
        requests[index].completion(.success(image))
    }
    
    func complete(with error: Error, at index: Int = 0){
        requests[index].completion(.failure(error))
    }
    
    private struct TaskSpy: ImageLoadTask {
        let onCancel: () -> Void
        func cancel() {
            onCancel()
        }
    }
}
