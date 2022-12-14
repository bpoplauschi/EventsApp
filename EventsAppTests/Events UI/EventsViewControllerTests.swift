//
//  EventsViewControllerTests.swift
//  EventsAppTests
//
//  Created by Bogdan on 23.07.2022.
//

import EventsApp
import UIKit
import XCTest

class EventsViewControllerTests: XCTestCase {
    func test_loadEventsActions_requestEventsFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0, "Expected no load requests before view is loaded")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a load request once view is loaded")
        let capturedLoadDates = loader.dates(at: 0)
        XCTAssertEqual(capturedLoadDates.startDate, startDate)
        XCTAssertEqual(capturedLoadDates.endDate, endDate)
        
        sut.simulateUserInitiatedRefresh()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another load request once user initiates a load")
        
        sut.simulateUserInitiatedRefresh()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected a third load request once user initiates another load")
    }
    
    func test_loadingIndicator_isVisibleWhenLoadingEvents() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")

        loader.complete(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading completes successfully")
        
        sut.simulateUserInitiatedRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a refresh")
        
        loader.completeWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated refresh completes with error")
    }
    
    func test_loadEventsCompletion_rendersSuccessfullyLoadedEvents() throws {
        let event0 = makeEvent(imageURL: anyURL())
        let event1 = makeEvent(suffix: "another", count: 0)
        let event2 = Event(name: "a name", location: "", dateInterval: "", count: 1, imageURL: URL(string: "http://another-specific-url.com")!)
        let event3 = Event(name: "", location: "", dateInterval: "", count: 0, imageURL: nil)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        loader.complete(with: [event0], at: 0)
        assertThat(sut, isRendering: [event0])
        
        sut.simulateUserInitiatedRefresh()
        loader.complete(with: [event0, event1, event2, event3], at: 1)
        assertThat(sut, isRendering: [event0, event1, event2, event3])
    }
    
    func test_loadEventsCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let event0 = makeEvent(imageURL: anyURL())
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0], at: 0)
        assertThat(sut, isRendering: [event0])
        
        sut.simulateUserInitiatedRefresh()
        loader.completeWithError(at: 1)
        assertThat(sut, isRendering: [event0])
    }
    
    func test_eventImageView_loadsImageURLWhenVisible() {
        let event0 = makeEvent()
        let event1 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let event2 = makeEvent(suffix: "2", count: 1, imageURL: URL(string: "http://image-url2.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0, event1, event2], at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until views become visible")
        
        sut.simulateEventImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests once first view with nil image url becomes visible")
        
        sut.simulateEventImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [event1.imageURL], "Expected second image URL requests once second view also becomes visible")
        
        sut.simulateEventImageViewVisible(at: 2)
        XCTAssertEqual(loader.loadedImageURLs, [event1.imageURL, event2.imageURL], "Expected third image URL requests once third view also becomes visible")
    }
    
    func test_eventImageView_cancelsImageLoadingWhenNotVisibleAnymore() {
        let event0 = makeEvent()
        let event1 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let event2 = makeEvent(suffix: "2", count: 1, imageURL: URL(string: "http://image-url2.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0, event1, event2], at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [], "Expected no cancelled image URL requests until view is not visible")
        
        sut.simulateEventImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [], "Expected no cancelled image URL requests once first view with nil image is not visible anymore")
        
        sut.simulateEventImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [event1.imageURL], "Expected cancelled second image URL requests once second view is not visible anymore")
        
        sut.simulateEventImageViewNotVisible(at: 2)
        XCTAssertEqual(loader.cancelledImageURLs, [event1.imageURL, event2.imageURL], "Expected cancelled third image URL requests once third view is not visible anymore")
    }
    
    func test_eventImageViewLoadingIndicator_isVisibleWhenLoadingImage() {
        let event0 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let event1 = makeEvent(suffix: "2", count: 1, imageURL: URL(string: "http://image-url2.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0, event1], at: 0)
        
        let view0 = sut.simulateEventImageViewVisible(at: 0)
        let view1 = sut.simulateEventImageViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true, "Expected loading indicator for first view while loading first image")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected loading indicator for second view while loading second image")
        
        loader.completeImageLoading(at: 0)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected loading indicator for second view while loading second image")
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for second view once second image loading completes with error")
    }
    
    func test_eventImageView_rendersImageLoadedFromURL() {
        let event0 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let event1 = makeEvent(suffix: "2", count: 1, imageURL: URL(string: "http://image-url2.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0, event1], at: 0)
        
        let view0 = sut.simulateEventImageViewVisible(at: 0)
        let view1 = sut.simulateEventImageViewVisible(at: 1)
        XCTAssertEqual(view0?.renderedImage, .none, "Expected no image for first view while loading first image")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image for second view while loading second image")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with: imageData0, at: 0)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected image for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected no image for second view while loading second image")
        
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected image for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.renderedImage, imageData1, "Expected image for second view once second image loading completes successfully")
    }
    
    func test_eventImageView_preloadsImageURLWhenNearVisible() {
        let event0 = makeEvent()
        let event1 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let event2 = makeEvent(suffix: "2", count: 1, imageURL: URL(string: "http://image-url2.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0, event1, event2], at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests until image is near visible")
        
        sut.simulateEventImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [], "Expected no image URL requests once first image with nil image url is near visible")
        
        sut.simulateEventImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [event1.imageURL], "Expected second image URL request once second image is near visible")
        
        sut.simulateEventImageViewNearVisible(at: 2)
        XCTAssertEqual(loader.loadedImageURLs, [event1.imageURL, event2.imageURL], "Expected third image URL request once third image is near visible")
    }
    
    func test_eventImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
        let event0 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let event1 = makeEvent(suffix: "2", count: 1, imageURL: URL(string: "http://image-url2.com")!)
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [event0, event1], at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [], "Expected no cancelled image URL requests until image is not near visible anymore")
        
        sut.simulateEventImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [event0.imageURL], "Expected first cancelled image URL request once first image is not near visible anymore")
        
        sut.simulateEventImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [event0.imageURL, event1.imageURL], "Expected second cancelled image URL request once second image is not near visible anymore")
    }
    
    func test_eventImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore() {
        let event0 = makeEvent(suffix: "1", count: 1, imageURL: URL(string: "http://image-url1.com")!)
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.complete(with: [event0], at: 0)
        
        let view = sut.simulateEventImageViewNotVisible(at: 0)
        loader.completeImageLoading(with: anyImageData(), at: 0)
        
        XCTAssertNil(view?.renderedImage, "Expected no rendered image when an image load finishes after the view is not visible anymore")
    }
    
    func test_loadEventsCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.complete(at: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadImageDataCompletion_dispatchesFromBackgroundToMainThread() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.complete(with: [makeEvent(imageURL: anyURL())], at: 0)
        sut.simulateEventImageViewVisible(at: 0)
        
        let exp = expectation(description: "Wait for background queue")
        DispatchQueue.global().async {
            loader.completeImageLoading(with: self.anyImageData(), at: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: EventsViewController, loader: EventsLoaderSpy) {
        let loader = EventsLoaderSpy()
        let sut = EventsUIComposer.eventsComposedWith(
            eventsLoader: loader,
            imageLoader: loader,
            currentDate: { self.startDate },
            futureDate: { self.endDate }
        )
        trackForMemoryLeaks(loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }
    
    private func anyImageData() -> Data {
        UIImage.make(withColor: .red).pngData()!
    }
    
    private var startDate: Date {
        Date(timeIntervalSince1970: 1658275200) // Wednesday, 20 July 2022 00:00:00
    }
    
    private var endDate: Date {
        Date(timeIntervalSince1970: 1658361600) // Thursday, 21 July 2022 00:00:00
    }
    
    private func makeEvent(suffix: String = "", count: Int = 1, imageURL: URL? = nil) -> Event {
        Event(
            name: "name\(suffix)",
            location: "location\(suffix)",
            dateInterval: "date interval\(suffix)",
            count: 1,
            imageURL: imageURL)
    }
    
    private func assertThat(
        _ sut: EventsViewController,
        isRendering events: [Event],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard sut.numberOfRenderedEventViews() == events.count else {
            return XCTFail("Expected \(events.count) event cells, got \(sut.numberOfRenderedEventViews()) instead", file: file, line: line)
        }
        
        events.enumerated().forEach { index, event in
            assertThat(sut, hasViewConfiguredFor: event, at: index)
        }
    }
    
    private func assertThat(
        _ sut: EventsViewController,
        hasViewConfiguredFor event: Event,
        at index: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let view = sut.eventView(at: index)
        
        guard let cell = view as? EventCell else {
            return XCTFail("Expected \(EventCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        XCTAssertEqual(cell.nameText, event.name, "Expected name text to be \(String(describing: event.name)) for cell at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.locationText, event.location, "Expected location text to be \(String(describing: event.location)) for cell at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.dateIntervalText, event.dateInterval, "Expected dateInterval text to be \(String(describing: event.dateInterval)) for cell at index (\(index))", file: file, line: line)
        XCTAssertEqual(cell.countText, "\(event.count) events", "Expected events count text to be \(String(describing: "\(event.count) events")) for cell at index (\(index))", file: file, line: line)
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { rendererContext in
            color.setFill()
            rendererContext.fill(rect)
        }
    }
}
