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
    
    
    // MARK: - Carga y estados
    func test_viewDidLoad_requestsFeedOnce() throws {
        let (_, loader) = try makeSUT()
        XCTAssertEqual(loader.requestCount, 1)
    }
    
    func test_viewDidLoad_showsLoadingUntilLoaderCompletes() throws{
        let (sut, _) =  try makeSUT()
        XCTAssertEqual(sut.state, .loading)
        XCTAssertTrue(sut.tableView.backgroundView is UIActivityIndicatorView)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
    }
    
    func test_loadCompletes_rendersOneRowPerPost() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture(), .fixture(), .fixture()]))
        flushMainQueue()
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 3)
        XCTAssertNil(sut.tableView.backgroundView)
        
        
    }
    
    func test_loadCompletesWithNoPosts_showsEmptyState() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([]))
        flushMainQueue()
        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.tableView.backgroundView is UILabel)
    }
    
    
    func test_loadFails_showsErrorAndNoRows() throws{
        let (sut, loader) = try makeSUT()
        loader.complete(with: .failure(FeedLoaderError.fileNotFound("x")))
        flushMainQueue()
        // guard case: no nos importa el texto exacto, solo que se .failed
        guard case .failed = sut.state else { return XCTFail("Se esperaba .faied, llego \(sut.state)")}
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
        
    }
    
    func test_loadCompletes_rendersOnlyAfterMainQueueRuns() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]))
        XCTAssertEqual(sut.state, .loading) // todavia no: DispatchQueue.main.async es mas tarde
        flushMainQueue()
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 1)
        
        
    }
    
    // MARK: - Pull to refresh
    func test_pullToRefresh_requestsFeedAgain() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]))
        flushMainQueue()
        sut.simulatedPullToRefresh()
        
        XCTAssertEqual(loader.requestCount, 2)
    }
    
    func test_pullToRefresh_whileLoading_doesNotRequestAgain() throws {
        let (sut, loader) = try makeSUT() // la primer carga NO ha terminado
        sut.simulatedPullToRefresh()
        
        XCTAssertEqual(loader.requestCount, 1)
    }
    
    
    func test_refreshCompletes_replacesPosts() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]), at: 0)
        
        flushMainQueue()
        
        sut.simulatedPullToRefresh()
        loader.complete(with: .success([.fixture(), .fixture()]), at: 1)
        
        flushMainQueue()
        
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 2)
    }
    
    
    // MARK: - Celdas y Memoria
    func test_cellForRow_returnsPostCell() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture(content: .text("Hola Nexo"))])
        XCTAssertNotNil(renderedCell(at: 0, in: sut))
    }
    
    func test_feed_isReleasedFromMemory() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture()])
        // Tamaño + layout: la TABLA CREA y guarda sus celdas (cadena tabla -> celda -> closure, Día 4)
        sut.tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 800)
        sut.tableView.layoutIfNeeded()
        XCTAssertEqual(sut.tableView.visibleCells.count, 1)
        assertNoMemoryLeak(sut)
    }
    
    // MARK: - Avatares
    func test_cellForRow_requestsAuthorAvatar() throws {
        let url = try XCTUnwrap(URL(string: "https: //nexo.app/ana.png"))
        let (sut, imageLoader) = try makeLoadedSUT(posts: [.fixture(author: .fixture(avatarURL: url))])
        _ = renderedCell(at: 0, in: sut)
        
        XCTAssertEqual(imageLoader.requestedURLs, [url])
    }
    

    
    func test_cellForRow_withoutAvatarURL_doesNotRequestAndShowsPlaceholder() throws {
        let (sut, imageLoader) = try makeLoadedSUT(posts: [.fixture(author: .fixture(avatarURL: nil))])
        
        let cell = renderedCell(at: 0, in: sut)
        
        XCTAssertTrue(imageLoader.requestedURLs.isEmpty)
        XCTAssertNotNil(cell?.displayedAvatar)
    }
    
    func test_avatarLoaded_showsImageOnlyAfterMainQueueRuns() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeLoadedSUT(posts: [.fixture(author: .fixture(avatarURL: url))])
        
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        let image = UIImage()
        
        imageLoader.complete(with: image)
        XCTAssertFalse(cell.displayedAvatar === image)
        
        flushMainQueue()
        XCTAssertTrue(cell.displayedAvatar === image)
    }
    
    // EL bug de la imagen equivocada (dia 6 concepto 4)
    func test_avatarLoaded_afterCellWasReused_isIgnored() throws {
        let urlA = try XCTUnwrap(URL(string: "https://nexo.app/a.png"))
        let postA = Post.fixture(author: .fixture(avatarURL: urlA))
        let postB = Post.fixture(author: .fixture(avatarURL: nil))
        let (sut, imageLoader) = try makeLoadedSUT(posts: [postA])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        let imageOfA = UIImage()
        
        cell.prepareForReuse()
        cell.configure(with: postB)
        imageLoader.complete(with: imageOfA, at: 0)
        flushMainQueue()
        
        XCTAssertEqual(imageLoader.cancelledURLs, [urlA]) // defensas #1
        XCTAssertFalse(cell.displayedAvatar === imageOfA) // defensa #2
        
    }
    
    
    // MARK: - Helpers
    // El Feed recien cargado, la peticion esta HECHA pero no contesta
    private func makeSUT(imageLoader: ImageLoader = ImageLoaderSpy()) throws -> (FeedViewController, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController { codee in
            FeedViewController(coder: codee, loader: loader, imageLoader: imageLoader)
        })
        sut.loadViewIfNeeded()
        return(sut, loader)
    }
    
    
    // El Feed ya mostrando posts para los tests de celdas y avatares
    private func makeLoadedSUT(posts: [Post]) throws -> (FeedViewController, ImageLoaderSpy){
        let imageLoader = ImageLoaderSpy()
        let (sut, loader) = try makeSUT(imageLoader: imageLoader)
        loader.complete(with: .success(posts))
        flushMainQueue()
        return (sut, imageLoader)
    }
    
    private func renderedCell(at row: Int, in sut: FeedViewController) -> PostCell? {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? PostCell
    }
    
    // Espera a que corra lo que ya esta encolado en el hilo principal (Dia 6)
    private func flushMainQueue() {
        let exp = expectation(description: "main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }
    
}


// Simula el gesto: el refreshControl: dispara su evento como si el usuario deslizara
private extension FeedViewController {
    func simulatedPullToRefresh() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}
