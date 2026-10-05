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
    
    // MARK: - Helpers
    // make System Under Test: un solo lugar para construir el Feed en todos los tests
    private func makeSUT(result: Result<[Post], Error>) throws -> FeedViewController {
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController{ coder in
            FeedViewController(coder: coder, loader: FeedLoaderStub(result: result))
                            
        })
        sut.loadViewIfNeeded()
        return sut
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
