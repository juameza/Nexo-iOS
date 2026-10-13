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
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    
    // Se muestra mientras carga, si falla, o si el autor no tiene foto
    private static let avatarPlaceholder = UIImage(systemName: "person.crop.circle.fill")
    
    // A que post representa la celda AHORA. Defensa #2 contra la imagen equivocada (Concepto 4)
    // private(set): El Feed lo LEE, pero solo la celda lo cambia (en configure y prepareForReuse)
    private(set) var representedPostID: Post.ID?
    
    // La descarga en curso de esta celda, para cancelarla al reciclarla. Defensa #1
    var avatarTask: ImageLoadTask?
    
    // Solo lectura, para los tests, el outlet es private
    var displayedAvatar: UIImage? { avatarImageView.image }
    
    
    // Una sola vez, cuando el storyboard termina de crear la celda (no en cada configure)
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = 20 // La mitad de 40 -> circulo
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = .systemGray3 // Color del placeholder (es un SF symbol)
    }
    
   
    
    // La celda NO sabe dar like: Solo Avisa "me tocaron" (igual que el delegate del Dia 3, pero con los closures)
    var onLikeTapped: (() -> Void)?
    
    // MARK: - Configuracion
    // Se llama en CADA cellForRowAt: hay que poner TODO por que la celda puede venir reciclada
    func configure(with post: Post){
        representedPostID = post.id
        avatarImageView.image = Self.avatarPlaceholder // ⚠️ si no, se veria el avatar del post
        
        nameLabel.text = post.author.isVerified ? "\(post.author.displayName) ✓" : post.author.displayName
        metaLabel.text = "\(post.author.handle) · \(post.relativeCreatedAt)"
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
        avatarTask?.cancel() // defensa #1: ya no necesitamos esa imagen
        avatarTask = nil
        representedPostID = nil
        avatarImageView.image = Self.avatarPlaceholder
    }
    
    // nil (fallo la descarga) -> placeholder
    func setAvatar(_ image: UIImage?){
        avatarImageView.image = image ?? Self.avatarPlaceholder
    }
    
    // MARK: - Acciones
    @IBAction private func likeButtonTapped(_ sender: UIButton) {
        onLikeTapped?()
    
    }
    
}
