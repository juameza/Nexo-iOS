//
//  XCTestCase+MemoryLeak.swift
//  NexoTests
//
//  Created by MMJ on 05/10/26.
//

import Foundation
import XCTest

extension XCTestCase {
    // Falla si instance sigue viva cunado el test ya termino -> hay un retain cycle
    // addTeardownBlock se ejecuta DESPUES del test, CUANDO todas sus variables locales ya se soltaron
    // [weak instance] si el bloque la capturara strong el propio test causaria leak
    // file: / line: el error se marca en la linea del test que llamó al helper, no aqui
    func assertNoMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line){
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "⚠️ Memory leak: la instancia sigue viva. Falta un [weak self]?", file: file, line: line)
        }
    }
}
