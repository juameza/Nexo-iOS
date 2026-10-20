//
//  XCTestCase+MainQueue.swift
//  NexoTests
//
//  Created by MMJ on 15/10/26.
//

import XCTest

extension XCTestCase {
    // Espera a que corra lo que ya estaba encolado en el hilo principal (Dia 6)
    func flushMainQueue() {
        let exp = expectation(description: "main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }
}
