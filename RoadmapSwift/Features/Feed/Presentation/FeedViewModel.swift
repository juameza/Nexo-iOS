//
//  FeedViewModel.swift
//  RoadmapSwift
//
//  Created by MMJ on 15/10/26.
//

import Foundation


// MVVM 🟤 con binding por closures
// Toda la LOGICA del Feed: pedir Posts, decidir el estado, evitar peticiones duplicadas y los likes
// Por no depender de UIKit se prueba SIN storyboard

final class FeedViewModel {
    // MARK: - Estado(el mismo enum del Dia 7, ahora vive aqui)
    enum State: Equatable {
        case loading
        case loaded([Post])
        case empty
        case failed(message: String)
    }
    
    // MARK: - Salidas (binding): la vista se suscribe a estas closures
    // Cambio el estado completo -> la vista se vuelve a dibujar
    var onStateChange: ((State) -> Void)?
    // Empezo o termino una peticion -> la vista muestra u oculta el spinner del refresh
    var onLoadingChange: ((Bool) -> Void)?
    // Cambio UN post (like) -> La vista recarga solo una fila
    var onPostUpdated: ((Int) -> Void)?
    
    // MARK: - Estado interno
    // private(set): la vista y los tests lo LEEN, solo el ViewModel lo cambia
    private(set) var state: State = .loading
    private(set) var isLoading = false
    
    private let loader: FeedLoader
    
    init(loader: FeedLoader) {
        self.loader = loader
    }
    
    // MARK: - Lectura para el DataSource
    var posts: [Post]{
        if case .loaded(let posts) = state {
            return posts
        }
        
        return []
    }
    
    // MARK: - Entrada (lo que la vista le pide)
    func load() {
        guard !isLoading else { return } // ya hay un peticion en curso
        setLoading(true)
        
        // Concepto 4: si ya hay posts (refresh), se queda visibles, SI no, spinner grande.
        if case .loaded = state { } else {
            setState(.loading)
        }
        
        // [weak self] (Concepto 5): el loader podria GUARDAR  esta closure (como el spy)
        loader.load { [weak self] result in
            // 🟤 Llega en un hilo de fondo -> el estado SIEMPRE se cambia en el principal.
            DispatchQueue.main.async{
                self?.handle(result)
            }
        }
    }
    
    func toggleLike(postID: Post.ID){
        guard case .loaded(var posts) = state, let index = posts.firstIndex(where: { $0.id == postID }) else {
            return
        }
        posts[index].toggleLike()
        state = .loaded(posts) // ⚠️ SIN setStatus: no es un cambio de pantalla completa
        onPostUpdated?(index) // Solo avisamos qué fila cambió
    }
    
    // MARK: - Privaod
    private func handle(_ result: Result<[Post], Error>){
        setLoading(false)
        switch result {
        case .success(let posts):
            setState(posts.isEmpty ? .empty : .loaded(posts))
        case .failure(let error):
            print("❌ Feed:", error)
            setState(.failed(message: "No pudimos cargar el feed 🙁\nDesliza hacia abajo para reintentar."))
            
        }
    }
    
    // UN solo lugar que cambia el estado Y avisa. Asi nunca se te olvida avisar
    private func setState(_ newState: State){
        state = newState
        onStateChange?(newState)
    }
    
    private func setLoading(_ loading: Bool){
        isLoading = loading
        onLoadingChange?(loading)
    }
    
}
