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
    
    // MARK: - Estado
    // private (set): desde fuera se puede LEER (util en test), pero solo el Feed la cambia
    private(set) var posts: [Post] = []
    
    // MARK: - Init
    // 🟢 iOS 13+ el storyboard nos crea con ESTE init gracias a instantiateInitialViewController(creator:)
    init?(coder: NSCoder, loader: FeedLoader){
        self.loader = loader
        super.init(coder: coder)
    }
    
    // Obligatorio para heredar de UIViewController. si alguien crea el Feed sin loader, crash claro
    required init?(coder: NSCoder) {
        fatalError("Usam init(coder:loader:)")
        
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
        // Mid: abrir el detall del post
    }

}
