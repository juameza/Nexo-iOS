//
//  RemoteImageLoader.swift
//  RoadmapSwift
//
//  Created by MMJ on 12/10/26.
//

import Foundation
import UIKit

// Descarga imagenes con URLSession 🟤 (completion handlers) y las guarda en NSCache
nonisolated final class RemoteImageLoader: ImageLoader {
    // Inyectada la app usa .shared y los tests una sesión con URLProtocolStub (Paso 8.4)
    private let session: URLSession
    // 🟤 NSCache: se vacai sola si falta memoria y se puede usar desde varios hilos
    private let cache = NSCache<NSURL, UIImage>()
    
    init(session: URLSession = .shared){
        self.session = session
    }
    
    @discardableResult
    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) -> ImageLoadTask {
        
        // 1 ¿Ya la teniamos? Respuesta inmediata, sin red.
        // ⚠️ Aqui 'completion' se llama YA (sincrono) y en la descarga se llama DESPUÉS (asincrono)
        // Por eso quien llama siempre debe usar DispatchQueue.main.async: asi funciona en ambos casos
        if let cached = cache.object(forKey: url as NSURL){
            completion(.success(cached))
            return CompletedTask()
        }
        
        // Copiamos la cache a una constante local para  no capturar 'self' en la closure
        let cache = self.cache
        let task = session.dataTask(with: url){ data, response, error in
            // ⚠️ Esto corre en un hilo de FONDO
            // 2. Error de transporte: sin interner, timeout o CANCELADA (prepareForReuse).
            if let error {
                completion(.failure(error))
                return
            }
            
            // 3. Un 404/500 NO llega como 'error': hay que revisar el statusCode a mano
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ImageLoaderError.invalidResponse(statusCode: -1)))
                return
            }
            
            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(ImageLoaderError.invalidResponse(statusCode: http.statusCode)))
                return
            }
            
            // 4. Los bytes tienen que ser una imagen de verdad
            guard let data, let image = UIImage(data: data) else {
                completion(.failure(ImageLoaderError.invalidImageData))
                return
            }
            cache.setObject(image, forKey: url as NSURL)
            completion(.success(image))
        }
        task.resume() // ⚠️ Sin esto las descarga nunca empieza (experimento 7.4)
        return task
    }
}

// Para el caso de la cache no hay nada que cancelar
private nonisolated struct CompletedTask: ImageLoadTask{
    func cancel() { }
}
