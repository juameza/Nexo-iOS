//
//  ImageLoader.swift
//  RoadmapSwift
//
//  Created by MMJ on 12/10/26.
//

import Foundation
import UIKit

// Algo que se puede cancelar: una descarga en curso
// nonisolated: tu proyecto pone TODO en el MainActor por defecto, la red NO debe vivir ahi
nonisolated protocol ImageLoadTask {
    func cancel()
}

// Contrato "algo que sabe traer una imagen", El Feed depende de ESTO (como FeedLoader, Día 4)
// la app usa RemoteImageLoader y los tests un spy
nonisolated protocol ImageLoader {
    // 🟤 Completion Handler ⚠️ NO promete en que hilo se llama completion: quien llama
    // debe regresar al hilo principal si va a tocar la UI
    // @escaping: la closure se guarda y se llama DESPUES  de que este método ya terminó
    // @Sendable: se puede llamar desde otro hilo (Swift lo revisa por ti)
    @discardableResult
    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) -> ImageLoadTask
}

// URLSessionDataTask ya tiene cancel(), asi que cumple el contrato sin escribir nada
nonisolated extension URLSessionDataTask: ImageLoadTask {}

nonisolated enum ImageLoaderError: Error, Equatable {
    // El servidor contesto, pero con un codigo que no es 2xx (404, 500..)
    case invalidResponse(statusCode: Int)
    // Llegaron bytes pero no son una imagen
    case invalidImageData
}
