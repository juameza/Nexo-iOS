//
//  PostContentPreviewTests.swift
//  NexoTests
//
//  Created by MMJ on 05/10/26.
//

import Foundation
import XCTest
@testable import RoadmapSwift

final class PostContentPreviewTests: XCTestCase {
    
    
    private let url = URL(string: "https://nexo.app/a")!
    
    func test_previewText_text_returnText(){
        XCTAssertEqual(PostContent.text("Hola").previewText, "Hola")
    }
    
    func test_previewText_imageWithoutCaption_returnsFoto() {
        XCTAssertEqual(PostContent.image(url: url, caption: nil).previewText, "🖼️ Foto")
    }
    
    func test_previewText_video_formatsMinutesAndSeconds() {
        XCTAssertEqual(PostContent.video(url: url, duration: 42.5).previewText, "🎬 Video · 0:42")
    }
    
    func test_previewText_unsupported_asksToUpdate() {
        XCTAssertEqual(PostContent.unsupported(type: "poll").previewText, "Actualiza Nexo para ver esta publicación")
    }
}
