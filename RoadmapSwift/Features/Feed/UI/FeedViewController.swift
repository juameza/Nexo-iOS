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
    // private (set): desde fuera se puede LEER (util en test), pero solo el Feed la cambia
    private(set) var posts: [Post] = []
    
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
        loadFeed()
    }
    
    // MARK: - Datos
    private func loadFeed() {
        do {
            posts = try loader.load()
            tableView.backgroundView = nil
        } catch {
            posts = []
            tableView.backgroundView = makeMessageLabel("No pudimos cargar el feed 🙁")
            print("❌ Feed:", error)
        }
        
        tableView.reloadData() // 🟤 Vuelve a preguntarme TODO. En Mid: diffable (solo lo que cambió)
    }
    
    // Buscamos por id y NO usamos el indexPath que tenia la celda: si la lista cambio
    // (o la celda se reciclo) ese indexPath podria apuntar a OTRO post
    private func toggleLike(postID: Post.ID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].toggleLike() // mutating del Dia : funciona porque posts es var
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
