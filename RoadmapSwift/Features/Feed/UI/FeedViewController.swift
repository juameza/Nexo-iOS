//
//  FeedViewController.swift
//  RoadmapSwift
//
//  Created by MMJ on 05/10/26.
//

import Foundation
import UIKit

// 🟤 UITableViewController: ya trae su tableView y ya es un dataSource y delegate
final class FeedViewController: UITableViewController {
    
    // MARK: -  Dependencias
    // let + protocolo: El feed no sabe (ni le importa) de donde vienen los posts
    private let loader: FeedLoader
    
    private let imageLoader: ImageLoader
    
    // MARK: - Estado
    // Make impossible states impossible (Concepto 2)
    enum State: Equatable{
        case loading
        case loaded([Post])
        case empty
        case failed(message: String)
    }
    
    // private(set): los tests lo LEEN pero solo el Feed lo cambia (en render y toggleLike)
    private(set) var state: State = .loading
    // Independiente del estado: durante un refresh se ven los posts y hay una peticion en curso
    private var isLoading = false
    
    // Atajo para el DataSource: los posts solo existen en .loaded
    private var posts: [Post] {
        if case .loaded(let posts) = state {
            return posts
        }
        return []
    }
    
    
    
    // MARK: - Init
    // 🟢 iOS 13+ el storyboard nos crea con ESTE init gracias a instantiateInitialViewController(creator:)
    init?(coder: NSCoder, loader: FeedLoader, imageLoader: ImageLoader){
        self.loader = loader
        self.imageLoader = imageLoader
        super.init(coder: coder)
    }
    
    // Obligatorio para heredar de UIViewController. si alguien crea el Feed sin loader, crash claro
    required init?(coder: NSCoder) {
        fatalError("Usa init(coder:loader:)")
        
    }
    
    // se llama cuando la cuenta de ARC llega a 0. SI NUNCA lo ves al salir del Feed: hay leak
    deinit {
        print("♻️ FeedViewController liberado")
    }
    
    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inicio"
        configureRefreshControl()
        loadFeed()
    }
    
    // MARK: - Datos
    private func configureRefreshControl() {
        let refresh = UIRefreshControl()
        // Target-Action con codigo (Concepto 3) #selector revisa EN COMPILACION que el metodo exista
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        refreshControl = refresh
    }
    
    @objc private func refreshPulled() {
        loadFeed()
    }
    
    private func loadFeed() {
        guard !isLoading else { return } // ya hay una peticion en curso: no pedir dos veces
       
        isLoading = true
        // Es la primera carga: spinner grande. Es un refresh: ya se ve el spinner del refreshControl
        if refreshControl?.isRefreshing != true {
            render(.loading)
        }
        
        // [weak self] (Concepto 4): no sabemos si el loader guarda la closure
        loader.load { [weak self] result in
            // 🟤 llega en un hilo de fondo -> al principal para tocar la UI (Dia 6)
            DispatchQueue.main.async {
                self?.handle(result)
            }
        }
        
    
    }
    
    private func handle(_ result: Result<[Post], Error>) {
        isLoading = false
        refreshControl?.endRefreshing() // ⚠️ si lo olvidas, el spinner del refresh gira para siempre
        
        switch result {
        case .success(let posts):
            render(posts.isEmpty ? .empty : .loaded(posts))
        case .failure(let error):
            print("❌ Feed:", error)
            render(.failed(message: "No pudimos cargar el feed 🙁\nDesliza hacia abajo para reintentar"))
        }
    }
    
    // El UNICO lugar que traduce un estado a pantalla
    private func render(_ newState: State){
        state = newState
        switch newState{ // sin default: si mañana agregas un caso, el compilador te avisa aqui
        case .loading:
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            tableView.backgroundView = spinner
        case .loaded:
            tableView.backgroundView = nil
        case .empty:
            tableView.backgroundView = makeMessageLabel("Aun no hay posts. \nSe el primero en publica ✨")
        case .failed(let message):
            tableView.backgroundView = makeMessageLabel(message)
            
        }
        tableView.reloadData()  // 🟤 Vuelve a preguntar TODO. En Mid: diffable (solo lo que cambio)
    }
    
    // Buscamos por id y NO usamos el indexPath que tenia la celda: si la lista cambio
    // (o la celda se reciclo) ese indexPath podria apuntar a OTRO post
    private func toggleLike(postID: Post.ID) {
        // guard case: solo hay likes si hay contenido. var posts: una COPIA que si podemos mutar
        guard case .loaded(var posts) = state, let index = posts.firstIndex(where: { $0.id == postID}) else {
            return
        }
        posts[index].toggleLike()
        state = .loaded(posts) // structs: modificamos la copia y la guardamos de vuelta
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)

        
    }
    
    private func loadAvatar(for post: Post, in cell: PostCell){
        
        guard let url = post.author.avatarURL else { return } // Sin foto: se queda el placeholder
        // Copiamos el id: la closure no debe depender de post ni de self
        let postID = post.id
        
        // [weak self] (Concepto 3) si la celda desaparece antes de que llegue la imagen, no la retenemos
        cell.avatarTask = imageLoader.loadImage(from: url) { [weak cell] result in
            // 🟤 Aqui podemos estar en un hilo de FONDO-> regresamos al principal para tocar la UI
            DispatchQueue.main.async{
                
                // Defensa #2 (Concepto 4): La celda sigues mostrando ESTE post?
                guard let cell, cell.representedPostID == postID else { return }
                cell.setAvatar(try? result.get()) // error -> nil -> placeholder
            }
        }
    }
    
    private func makeMessageLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue: "dame una celda reciclada, o crea una nueva si no hay
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier, for: indexPath) as? PostCell else {
            fatalError("La celda prototipo no es PostCell: revisa Class e Identifier en Feed.storyboard")
        }
        let post = posts[indexPath.row]
        cell.configure(with: post)
        
        loadAvatar(for: post, in: cell)
        
        // ⚠️ [weak self]: la celda (que vive dentro de NUESTRA table) guarda esta closure.
        // Sin weak la closure retendria al Feed -> retain cycle (Concepto 2)
        cell.onLikeTapped = { [weak self] in
            self?.toggleLike(postID: post.id)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Mid: abrir el detalle del post
    }

}
