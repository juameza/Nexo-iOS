//
//  FeedViewModelTests.swift
//  NexoTests
//
//  Created by MMJ on 15/10/26.
//

import XCTest
@testable import RoadmapSwift

@MainActor
final class FeedViewModelTests: XCTestCase {
    // MARK: - Carga
    func test_init_doesNotRequestFeed() {
        let (_, loader) = makeSUT()
        XCTAssertEqual(loader.requestCount, 0) // El viewModel no carga solo: espera a que la vista se lo pida
    }
    
    func test_load_requestsFeedOnce(){
        let (sut, loader) = makeSUT()
        sut.load()
        XCTAssertEqual(loader.requestCount, 1)
        
        
    }
    
    func test_load_setsLoadingStateAndIsLoading() {
        let (sut, _) = makeSUT()
        sut.load()
        XCTAssertEqual(sut.state, .loading)
        XCTAssertTrue(sut.isLoading)
    }
    
    func test_loadCompletesWithPosts_setsLoaded() {
        let (sut, loader) = makeSUT()
        let posts = [Post.fixture(), Post.fixture()]
        sut.load()
        loader.complete(with: .success(posts))
        flushMainQueue()
        XCTAssertEqual(sut.state, .loaded(posts)) // ✅ Ahora comparamos el estado EXACTO, no una tabla
        XCTAssertFalse(sut.isLoading)
    }
    
    func test_loadCompletesWithNoPosts_setsEmpty() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .success([]))
        flushMainQueue()
        XCTAssertEqual(sut.state, .empty)
    }
    
    func test_loadFails_setsFailedAndStopsLoading() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .failure(FeedLoaderError.fileNotFound("x")))
        flushMainQueue()
        guard case .failed = sut.state else { return XCTFail("Se esperaba, .failed, llego \(sut.state)") }
        XCTAssertFalse(sut.isLoading)
    }
    
    func test_loadCompletes_appliesOnlyAfterMainQueueRuns() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .success([.fixture()]))
        XCTAssertEqual(sut.state, .loading) // todavia  no: DispathQueue.main.async es "mas tarde"
        flushMainQueue()
        XCTAssertEqual(sut.posts.count, 1)
    }
    
    // MARK: - Refresh
    func test_load_whileLoading_doesNotRequestAgain() {
        let (sut, loader) = makeSUT()
        sut.load()
        sut.load()
        XCTAssertEqual(loader.requestCount, 1)
    }
    
    
    func test_refresh_keepsPostsVisibleWhileLoading() {
        let (sut, loader) = makeSUT()
        let posts = [Post.fixture()]
        sut.load()
        loader.complete(with: .success(posts), at: 0)
        flushMainQueue()
        sut.load()  // el refresh
        
        XCTAssertEqual(sut.state, .loaded(posts)) // Concepto 4: los posts NO desaparecen
        XCTAssertTrue(sut.isLoading)
    }
    
    func test_refreshCompletes_replacesPosts() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .success([.fixture()]), at: 0)
        flushMainQueue()
        
        sut.load()
        
        loader.complete(with: .success([.fixture(), .fixture()]), at: 1)
        flushMainQueue()
        XCTAssertEqual(sut.posts.count, 2)
    }
    
    // MARK: - Binding
    func test_onStateChange_reportsLoadingThenLoaded() {
        let (sut, loader) = makeSUT()
        let post = Post.fixture()
        var received: [FeedViewModel.State] = []
        sut.onStateChange = { received.append($0) } // EL TEST hace de vista
        
        sut.load()
        loader.complete(with: .success([post]))
        flushMainQueue()
        XCTAssertEqual(received, [.loading, .loaded([post])])
    }
    
    // MARK: - Likes
    func test_toggleLike_updatesPostAndNotifiesOnlyThatRow() throws {
        let (sut, loader) = makeSUT()
        let other = Post.fixture()
        let target = Post.fixture(likeCount: 3, isLikedByMe: false)
        var updatedRows: [Int] = []
        var stateChanges = 0
        sut.load()
        loader.complete(with: .success([other, target]))
        flushMainQueue()
        sut.onPostUpdated = { updatedRows.append($0) }
        sut.onStateChange = { _ in stateChanges += 1}
        
        sut.toggleLike(postID: target.id)
        
        let updated = try XCTUnwrap(sut.posts.last)
        XCTAssertTrue(updated.isLikedByMe)
        XCTAssertEqual(updated.likeCount, 4)
        XCTAssertEqual(updatedRows, [1]) // solo la fila 1
        XCTAssertEqual(stateChanges, 0) // Y NO un redibujando completo
    }
    
    // MARK: - Memoria
    func test_load_doesNotRetainViewModel() {
        let (sut, _) = makeSUT()
        sut.load()  // el spy GUARDA la closure (Concepto 5, segundo ciclo)
        assertNoMemoryLeak(sut)
        
    }
    
    // MARK: - Helpers
    private func makeSUT() -> (FeedViewModel, FeedLoaderSpy){
        let loader = FeedLoaderSpy()
        let sut = FeedViewModel(loader: loader)
        return (sut, loader)
    }
    
    
}
