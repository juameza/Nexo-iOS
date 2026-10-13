//
//  FeedViewControllerTests.swift
//  NexoTests
//
//  Created by MMJ on 05/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

@MainActor
final class FeedViewControllerTests: XCTestCase {
    
    
    func test_viewDidLoad_renderOneRowPerPost() throws {
        let sut = try makeSUT(result: .success([.fixture(), .fixture(), .fixture()]))
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 3)
        XCTAssertNil(sut.tableView.backgroundView)
    }
    
    func test_viewDidLoad_loaderFails_showErrorAndNoRows() throws {
        let sut = try makeSUT(result: .failure(FeedLoaderError.fileNotFound("x")))
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
        XCTAssertNotNil(sut.tableView.backgroundView)
    }
    
    // También es un test de humo: si la celda prototipo no tiene class/Identifier
    // correctos, o un outlet esta roto, esto truena
    func test_cellForRow_returnsPostCell() throws {
        let sut = try makeSUT(result: .success([.fixture(content: .text("Hola Nexo"))]))
        let cell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is PostCell)
    }
    
    func test_feed_isReleasedFromMemory() throws {
        let sut = try makeSUT(result: .success([.fixture()]))
        
        // Le damos tamaño y forzamos el layout para que la TABLA cree y GUARDE sus celdas.
        // Sin esto no existiria kla cadena tabla -> celda -> closure, y el test no detectaria el ciclo
        sut.tableView.frame = CGRect(x: 0, y: 0,  width: 3990, height: 800)
        sut.tableView.layoutIfNeeded()
        XCTAssertEqual(sut.tableView.visibleCells.count, 1)
        assertNoMemoryLeak(sut)
        
    }
    
    // MARK: - Avatares
    func test_cellForRow_requestsAuthorAvatar() throws{
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [.fixture(author: .fixture(avatarURL: url))])
        
        _ = renderedCell(at: 0, in: sut)
        
        XCTAssertEqual(imageLoader.requestedURLs, [url])
    }
    
    func test_cellForRow_withoutAvatarURL_doesNotRequestAndShowsPlaceholder() throws {
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [.fixture(author: .fixture(avatarURL: nil))])
        
        let cell = renderedCell(at: 0, in: sut)
        
        XCTAssertTrue(imageLoader.requestedURLs.isEmpty)
        XCTAssertNotNil(cell?.displayedAvatar)
    }
    
    func test_avatarLoaded_showsImageOnlyAfterMainQueueRuns() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [.fixture(author: .fixture(avatarURL: url))])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        let image = UIImage()
        
        imageLoader.complete(with: image)
        
        // Todavia NO: el Feed la mando con DispathQueue.main.async ("mas tarde")
        XCTAssertFalse(cell.displayedAvatar === image)
        
        flushMainQueue()
        XCTAssertTrue(cell.displayedAvatar === image) // === : la MISMA instancia (Dia 1, P2)
    }
    
    // El bug del concepto 4, reproducido sin red lenta y sin hacer scroll
    func test_avatarLoaded_afterCellWasReused_isIgnored() throws {
        let urlA = try XCTUnwrap(URL(string: "https://nexo.app/a.png"))
        let postA = Post.fixture(author: .fixture(avatarURL: urlA))
        let postB = Post.fixture(author: .fixture(avatarURL: nil))
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [postA])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut)) // pide el avatar de A
        let imageOfA = UIImage()
        
        // La tabla recicla la celda para el post B (lo mismo que hace al hacer scroll)
        cell.prepareForReuse()
        cell.configure(with: postB)
        // ...y llega TARDE la imagen de A
        imageLoader.complete(with: imageOfA, at: 0)
        flushMainQueue()
        
        XCTAssertEqual(imageLoader.cancelledURLs, [urlA])  // defensa #1
        XCTAssertFalse(cell.displayedAvatar === imageOfA) // defensa # 2
    }
    
    // MARK: - Helpers
    // make System Under Test: un solo lugar para construir el Feed en todos los tests
    private func makeSUT(result: Result<[Post], Error>, imageLoader: ImageLoader = ImageLoaderSpy()) throws -> FeedViewController {
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController{ coder in
            FeedViewController(coder: coder, loader: FeedLoaderStub(result: result), imageLoader: imageLoader)
                            
        })
        sut.loadViewIfNeeded()
        return sut
    }
    
    private func makeSUTWithSpy(posts: [Post]) throws -> (FeedViewController, ImageLoaderSpy){
        let imageLoader = ImageLoaderSpy()
        let sut = try makeSUT(result: .success(posts), imageLoader: imageLoader)
        return (sut, imageLoader)
    }
    
    private func renderedCell(at row: Int, in sut: FeedViewController) -> PostCell? {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? PostCell
    }
    
    // Espera a que se ejecute lo que ya estaba encolado en el hilo principal
    // La cola es FIFO: cuando corre NUESTRO bloque, el DispatchQueue.main.async del Feed ya corrio
    private func flushMainQueue() {
        let exp = expectation(description: "main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }
    
}

// STUB: un loader falso que devuelve exactamente lo que el test le pide
// Gracias al protocolo FeedLoader, el Feed no nota la diferencia
private struct FeedLoaderStub: FeedLoader {
    let result: Result<[Post], Error>
    func load() throws -> [Post] {
        try result.get()  // .success-> post, .failure -> throw
    }
}
