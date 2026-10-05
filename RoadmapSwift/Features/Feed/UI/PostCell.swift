//
//  PostCell.swift
//  RoadmapSwift
//
//  Created by MMJ on 05/10/26.
//

import Foundation
import UIKit

final class PostCell: UITableViewCell {
    // Debe ser IGUAL al identifier de la celda prototipo en el storyboard
    static let reuseIdentifier = "PostCell"
    
    // MARK: - Outlets
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var metaLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var likeButton: UIButton!
    
   
    
    // La celda NO sabe dar like: Solo Avisa "me tocaron" (igual que el delegate del Dia 3, pero con los closures)
    var onLikeTapped: (() -> Void)?
    
    // MARK: - Configuracion
    // Se llama en CADA cellForRowAt: hay que poner TODO por que la celda puede venir reciclada
    func configure(with post: Post){
        nameLabel.text = post.author.isVerified ? "\(post.author.displayName) *" : post.author.displayName
        metaLabel.text = "\(post.author.handle) . \(post.relativeCreatedAt)"
        bodyLabel.text = post.content.previewText
        
        // 🟢 iOS 15+: UIButton.Configuration (como en el dia 1), El if/else cubre ambos estados:
        // si solo pintaras el corazón rojo cuando hay like, una celda reciclada se quedaria roja.
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: post.isLikedByMe ? "heart.fill" : "heart")
        config.title = "\(post.likeCount)"
        config.imagePadding = 6
        config.baseForegroundColor = post.isLikedByMe ? .systemPink : .secondaryLabel
        likeButton.configuration = config
        
    }
    
    // Justo antes de reutilizar la celda: soltamos la closure del post anterior
    override func prepareForReuse(){
        super.prepareForReuse()
        onLikeTapped = nil
    }
    
    // MARK: - Acciones
    @IBAction private func likeButtonTapped(_ sender: UIButton) {
        onLikeTapped?()
    
    }
    
}
