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
    
    // MARK: - La vista dibuja cada estado
    func test_viewDidLoad_asksViewModelToLoad() throws {
        let (_, loader) = try makeSUT()
        XCTAssertEqual(loader.requestCount, 1)
    }
    
    func test_viewDidLoad_showsSpinner() throws {
        let (sut, _) = try makeSUT()
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
    
    func test_loadCompletesWithNoPosts_showsMessage() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([]))
        flushMainQueue()
        XCTAssertTrue(sut.tableView.backgroundView is UILabel)
    }
    
    func test_loadFails_showsMessageAndNoRows() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .failure(FeedLoaderError.fileNotFound("x")))
        flushMainQueue()
        XCTAssertTrue(sut.tableView.backgroundView is UILabel)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
    }
    
    // MARK: - La vista reenvia eventos
    func test_pullToRefresh_asksViewModelToLoadAgain() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]))
        flushMainQueue()
        sut.simulatedPullToRefresh()
        
        XCTAssertEqual(loader.requestCount, 2)
    }
    
    func test_likeTapped_togglesLikeInViewModel() throws {
        let post = Post.fixture(isLikedByMe: false)
        let (sut, _) = try makeLoadedSUT(posts: [post])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        
        cell.onLikeTapped?() // como si tocaran el ♥️
        
        XCTAssertEqual(sut.viewModel.posts.first?.isLikedByMe, true)
    }
    
    // MARK: -  Celdas y memoria
    func test_cellForRow_returnsPostCell() throws{
        let (sut, _) = try makeLoadedSUT(posts: [.fixture(content: .text("Hola Nexo"))])
        XCTAssertNotNil(renderedCell(at: 0, in: sut))
    }
    
    func test_feed_isReleasedFromMemory() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture()])
        sut.tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 800)
        sut.tableView.layoutIfNeeded()
        XCTAssertEqual(sut.tableView.visibleCells.count, 1)
        assertNoMemoryLeak(sut)
        assertNoMemoryLeak(sut.viewModel) // ⚠️ los dos deben morir (Concepto 5)
    }
    
    // MARK: - Avatares (sin cambios respecto al Día 7)
    func test_cellForRow_requestAuthorAvatar() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
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
        
        XCTAssertEqual(imageLoader.cancelledURLs, [urlA])
        XCTAssertFalse(cell.displayedAvatar === imageOfA)
    }
    
    // MARK: - Helpers
    private func makeSUT(imageLoader: ImageLoader = ImageLoaderSpy()) throws -> (FeedViewController, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let viewModel = FeedViewModel(loader: loader)
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController { coder in
            FeedViewController(coder: coder, viewModel: viewModel, imageLoader: imageLoader)
        })
        sut.loadViewIfNeeded()
        return (sut, loader)
    }
    
    private func makeLoadedSUT(posts: [Post]) throws -> (FeedViewController, ImageLoaderSpy) {
        let imageLoader = ImageLoaderSpy()
        let (sut, loader) = try makeSUT(imageLoader: imageLoader)
        loader.complete(with: .success(posts))
        flushMainQueue()
        return (sut, imageLoader)
    }
    
    private func renderedCell(at row: Int, in sut: FeedViewController) -> PostCell? {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? PostCell
    }
    

    
}


// Simula el gesto: el refreshControl: dispara su evento como si el usuario deslizara
private extension FeedViewController {
    func simulatedPullToRefresh() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}
