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
    // La vista dueña del ViewModel (let) sin private: los tests leen su estado
    let viewModel: FeedViewModel
    private let imageLoader: ImageLoader
    
    
    // MARK: - Init
    // 🟢 iOS 13+ el storyboard nos crea con ESTE init gracias a instantiateInitialViewController(creator:)
    init?(coder: NSCoder, viewModel: FeedViewModel, imageLoader: ImageLoader){
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(coder: coder)
    }
    
    // Obligatorio para heredar de UIViewController. si alguien crea el Feed sin loader, crash claro
    required init?(coder: NSCoder) {
        fatalError("Usa init(coder:viewModel:imageLoader:)")
        
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
        bind() // ⚠️ Antes de load(): si no, el primer .loading no llega a nadie
        viewModel.load()
    }
    
    // MARK: - Binding (Concepto 3)
    // [weak self] en los TRES (concepto 5): el viewModel guarda estas closures y nosotros lo guardamos a el
    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onLoadingChange = { [weak self] isLoading in
            if !isLoading { self?.refreshControl?.endRefreshing() }
        }
        viewModel.onPostUpdated = { [weak self] index in
            self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        
    }
    
    // MARK: - Datos
    private func configureRefreshControl() {
        let refresh = UIRefreshControl()
        // Target-Action con codigo (Concepto 3) #selector revisa EN COMPILACION que el metodo exista
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        refreshControl = refresh
    }
    
    @objc private func refreshPulled() {
        viewModel.load()
    }
    

    // El UNICO lugar que traduce un estado a pantalla
    private func render(_ newState: FeedViewModel.State){
        
        switch newState{ // sin default: si mañana agregas un caso, el compilador te avisa aqui
        case .loading:
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            tableView.backgroundView = spinner
        case .loaded:
            tableView.backgroundView = nil
        case .empty:
            tableView.backgroundView = makeMessageLabel("Aún no hay posts.\nSé el primero en publicar ✨")
        case .failed(let message):
            tableView.backgroundView = makeMessageLabel(message)
            
        }
        tableView.reloadData()  // 🟤 Vuelve a preguntar TODO. En Mid: diffable (solo lo que cambio)
    }
    

    private func loadAvatar(for post: Post, in cell: PostCell){
        
        guard let url = post.author.avatarURL else { return } // Sin foto: se queda el placeholder
        // Copiamos el id: la closure no debe depender de post ni de self
        let postID = post.id
        
        // [weak cell] (Concepto 3) si la celda desaparece antes de que llegue la imagen, no la retenemos
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
        viewModel.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue: "dame una celda reciclada, o crea una nueva si no hay
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier, for: indexPath) as? PostCell else {
            fatalError("La celda prototipo no es PostCell: revisa Class e Identifier en Feed.storyboard")
        }
        let post = viewModel.posts[indexPath.row]
        cell.configure(with: post)
        
        loadAvatar(for: post, in: cell)
        
        // ⚠️ [weak self]: la celda (que vive dentro de NUESTRA table) guarda esta closure.
        // Sin weak la closure retendria al Feed -> retain cycle (Concepto 2)
        cell.onLikeTapped = { [weak self] in
            self?.viewModel.toggleLike(postID: post.id)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Mid: abrir el detalle del post
    }

}
