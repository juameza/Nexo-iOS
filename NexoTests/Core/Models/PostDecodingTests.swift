//
//  PostDecodingTests.swift
//  NexoTests
//
//  Created by MMJ on 28/09/26.
//

import XCTest
@testable import RoadmapSwift

final class PostDecodingTests: XCTestCase {
    private let decoder = JSONDecoder.nexo
    
    // throws en el test: si algo lanza un error, el test falla mostrando un error
    func test_decode_textContent_returnsTextCase() throws{
        // #"..."# raw string: no hace falta escapar las comillas.
        let json = #"{ "type": "text", "text": "Hola" }"#
        let content = try decoder.decode(PostContent.self, from: Data(json.utf8))
        XCTAssertEqual(content, .text("Hola"))
    }
    
    func test_decode_imageWithoutCaption_returnsImageWithNilCaption() throws {
        let json = #"{ "type": "image", "url": "https://nexo.app/a.jpg" }"#
        let content = try decoder.decode(PostContent.self, from: Data(json.utf8))
        XCTAssertEqual(content, .image(url: URL(string: "https://nexo.app/a.jpg")!, caption: nil))
    }
    
    func test_decode_unknownType_returnsUnsupported() throws {
        let json = #"{ "type": "poll", "question": "¿?" }"#
        let content = try decoder.decode(PostContent.self, from: Data(json.utf8))
        XCTAssertEqual(content, .unsupported(type: "poll"))
    }
    
    func test_decode_videoWithoutDuration_throwsError() {
        let json = #"{ "type": "video", "url": "https://nexo.app/v.mp4"}"#
        XCTAssertThrowsError(try decoder.decode(PostContent.self, from: Data(json.utf8)))
    }
    
    func test_decode_userWithSnakeCaseAndMissingBio_mapsFields() throws {
        // Raw string multilines: #"""...""""#
        let json = #"""
        {
            "id": "A0000000-0000-0000-0000-000000000009",
            "username": "ana",
            "display_name": "Ana",
            "avatar_url": null,
            "is_verified": true
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertEqual(user.displayName, "Ana")
        XCTAssertEqual(user.handle, "@ana")
        XCTAssertNil(user.avatarURL)
        XCTAssertNil(user.bio)
        XCTAssertTrue(user.isVerified)
    }
    
    // Round trip: codificar y volver a decodificar debe dar exactamente lo mismo
    func test_encodeThenDecode_post_returnsEqualPost() throws {
        let original = Post.fixture(content: .video(url: URL(string: "https://nexo.app/v.mp4")!, duration: 10))
        let data = try JSONEncoder.nexo.encode(original)
        let decoded = try decoder.decode(Post.self, from: data)
        XCTAssertEqual(decoded, original)
    }
    
    func test_mockFeedLoader_loadsBundleFeed() throws {
        let posts = try MockFeedLoader().load()
        XCTAssertEqual(posts.count, 4)
        XCTAssertEqual(posts.last?.content, .unsupported(type: "poll"))
    }
    
    func test_mockFeedLoader_missingFile_throwsFileNotFound()  {
        let sut = MockFeedLoader(fileName: "no_existe")
        XCTAssertThrowsError(try sut.load()) { error in
            XCTAssertEqual(error as? FeedLoaderError, .fileNotFound("no_existe"))
        }
    }
    
    func test_decode_userWithAvatar_mapsAvatarURL() throws {
        let json = #"""
        { 
            "id": "A0000000-0000-0000-0000-000000000009", 
            "username": "ana",
            "display_name": "Ana", 
            "avatar_url": "https://nexo.app/ana.jpg", 
            "is_verified": false 
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertEqual(user.avatarURL, URL(string: "https://nexo.app/ana.jpg"))
    }
}

final class PostTests: XCTestCase {

    func test_toggleLike_whenNotLiked_incrementsCount() {
        var post = Post.fixture(likeCount: 10, isLikedByMe: false)
        post.toggleLike()
        XCTAssertTrue(post.isLikedByMe)
        XCTAssertEqual(post.likeCount, 11)
    }

    func test_toggleLike_whenLiked_decrementsCount() {
        var post = Post.fixture(likeCount: 10, isLikedByMe: true)
        post.toggleLike()
        XCTAssertFalse(post.isLikedByMe)
        XCTAssertEqual(post.likeCount, 9)
    }

    /// Demuestra la semántica de VALOR: la copia no afecta al original.
    func test_struct_copyIsIndependent() {
        let original = Post.fixture(likeCount: 0, isLikedByMe: false)
        var copy = original
        copy.toggleLike()
        XCTAssertEqual(original.likeCount, 0)
        XCTAssertEqual(copy.likeCount, 1)
    }
    
    
}

// MARK: - Fixtures
// Un "fixture" es un objeto de prueba con valores por defecto.
// Cada test cambia SOLO lo que le importa y el resto queda con valores válidos.
extension User {
    static func fixture(username: String = "mario", avatarURL: URL? = nil) -> User {
        User(id: UUID(), username: username, displayName: "Mario", avatarURL: avatarURL, isVerified: false, bio: nil)
    }
}

extension Post {
    static func fixture(
        author: User = .fixture(),
        content: PostContent = .text("Hola"),
        likeCount: Int = 0,
        isLikedByMe: Bool = false
    ) -> Post {
        Post(
            id: UUID(),
            author: author,
            content: content,
            // Fecha FIJA: los tests no deben depender del reloj. Y un número entero de
            // segundos, porque ISO 8601 no guarda milisegundos y el round trip fallaría.
            createdAt: Date(timeIntervalSince1970: 1_790_000_000),
            likeCount: likeCount,
            commentCount: 0,
            isLikedByMe: isLikedByMe
        )
    }
}

