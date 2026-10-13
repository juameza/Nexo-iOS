//
//  RemoteImageLoaderTests.swift
//  NexoTests
//
//  Created by MMJ on 13/10/26.
//

import XCTest
@testable import RoadmapSwift

// Prueba el loader REAL con un URLSession REAL.... pero la red la inventa URLProtocolStub
final class RemoteImageLoaderTests: XCTestCase {
    
    override func tearDown() {
        URLProtocolStub.stub = nil // Que un test no contamine al siguiente
        super.tearDown()
    }
    
    func test_load_validImage_returnsImage() async throws {
        URLProtocolStub.stub = .init(data: makeImageData(), statusCode: 200, error: nil)
        let image = try await load().get()
        XCTAssertEqual(image.size, CGSize(width: 1, height: 1))
    }
    
    func test_load_non2xxStatus_failsWithInvalidResponse() async {
        URLProtocolStub.stub = .init(data: makeImageData(), statusCode: 404, error: nil)
        let result = await load()
        XCTAssertEqual(result.failure as? ImageLoaderError, .invalidResponse(statusCode: 404))
    }
    
    func test_load_invalidData_failsWithInvalidImageData() async {
        URLProtocolStub.stub = .init(data: Data("no soy una imagen".utf8), statusCode: 200, error: nil)
        let result = await load()
        XCTAssertEqual((result.failure as? ImageLoaderError), .invalidImageData)
    }
    
    func test_load_networkError_failsWithThatError() async {
        URLProtocolStub.stub = .init(data: nil, statusCode: 200, error: URLError(.notConnectedToInternet))
        let result = await load()
        XCTAssertEqual((result.failure as? URLError)?.code, .notConnectedToInternet)
    }
    
    // MARK: - Helpers
    private func load(url: URL = URL(string: "https://nexo.app/avatar.png")!) async -> Result<UIImage, Error> {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self] // Aqui secuestramos la red
        let sut = RemoteImageLoader(session: URLSession(configuration: configuration))
        
        // 🟢 Adelanto el nivel Mid: convertir un completion handler en await
        // ⚠️ resume se debe llamar EXACTAMENTE una vez (si nunca se llama, el test espera para siempre)
        return await withCheckedContinuation { continuation in
            sut.loadImage(from: url) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    // Un PNG rela de 1x1 px scale = 1 si no usa la escala de la pantalla (3x) y saldria de 3x3
    private func makeImageData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).pngData { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}

private extension Result {
    // El error, si lo hay para poder escribir XCTAssertEqual(result.failure as? ...)
    var failure: Failure? {
        if case .failure(let error) = self {
            return error
        }
        
        return nil
    }
}


// 🟤 URLProtocol: URLSession le pregunta tu atiendes esta peticion? (canInit)
// Decimos que si a TODAS y contestamos con lo que el test puso en stub
final class URLProtocolStub: URLProtocol {
    struct Stub {
        let data: Data?
        let statusCode: Int
        let error: Error?
    }
    
    // nonisolated(unsafe): una variable global mutable, le prometemos a Swift que los tests
    // no la tocan desde dos hilos a la vez, (En el nivel Senior lo haremos sin unsafe)
    nonisolated(unsafe) static var stub: Stub?
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let stub = Self.stub, let url = request.url else { return }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
    
}
