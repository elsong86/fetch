import XCTest
@testable import fetchTakeHome

class ImageCacheManagerTests: XCTestCase {
    
    var sut: ImageCacheManager!
    var mockURLSession: MockURLSession!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Make a temp folder for test cache files
        let tempCacheURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ImageCacheTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: tempCacheURL, withIntermediateDirectories: true)
        
        // Setup test instance
        mockURLSession = MockURLSession()
        sut = ImageCacheManager(
            cacheDirectory: tempCacheURL,
            session: mockURLSession
        )
    }
    
    override func tearDownWithError() throws {
        // Clean up our mess
        if let cacheURL = sut.cacheDirectoryURL,
           FileManager.default.fileExists(atPath: cacheURL.path) {
            try FileManager.default.removeItem(at: cacheURL)
        }
        
        sut = nil
        mockURLSession = nil
        try super.tearDownWithError()
    }
    
    // Test cases
    
    func testLoadImageFromNetworkWhenNotInCache() throws {
        
        // Setup test data
        let expectation = expectation(description: "Image loaded from network")
        let testURL = URL(string: "https://example.com/test.jpg")!
        let testImageData = createTestImageData()
        
        mockURLSession.nextData = testImageData
        mockURLSession.nextResponse = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockURLSession.nextError = nil
        
        var resultImage: CGImage?
        
        // Run the function we're testing
        sut.loadImage(from: testURL) { image in
            resultImage = image
            expectation.fulfill()
        }
        
        // Check the results
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockURLSession.dataTaskWasCalled, "Network request should be made")
        XCTAssertEqual(mockURLSession.lastURL, testURL, "URL should match test URL")
        XCTAssertNotNil(resultImage, "Should return a valid image")
    }
    
    func testReturnsCachedImageWithoutNetworkRequest() throws {
        // Prep test data
        let testURL = URL(string: "https://example.com/cached.jpg")!
        let testImageData = createTestImageData()
        
        // Add image to cache first
        try saveTestImageToCache(data: testImageData, url: testURL)
        
        let expectation = expectation(description: "Image loaded from cache")
        var resultImage: CGImage?
        
        // Do the thing
        sut.loadImage(from: testURL) { image in
            resultImage = image
            expectation.fulfill()
        }
        
        // Verify results
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(mockURLSession.dataTaskWasCalled, "Network request should NOT be made")
        XCTAssertNotNil(resultImage, "Should return a valid image from cache")
    }
    
    func testSavesImageToCacheAfterNetworkLoad() throws {
        // Setup
        let expectation = expectation(description: "Image loaded from network")
        let testURL = URL(string: "https://example.com/test-save.jpg")!
        let testImageData = createTestImageData()
        
        mockURLSession.nextData = testImageData
        mockURLSession.nextResponse = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        // Execute
        sut.loadImage(from: testURL) { _ in
            expectation.fulfill()
        }
        
        // Verify
        wait(for: [expectation], timeout: 1.0)
        
        // Make sure it saved to disk
        let cacheURL = sut.diskCacheURL(for: testURL.absoluteString)
        XCTAssertNotNil(cacheURL, "Cache URL should be valid")
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheURL!.path), "Image should be saved to cache")
    }
    
    func testHandlesNetworkErrorGracefully() throws {
        // Setup test case
        let expectation = expectation(description: "Network error handled")
        let testURL = URL(string: "https://example.com/error.jpg")!
        
        mockURLSession.nextData = nil
        mockURLSession.nextError = NSError(domain: "test", code: -1, userInfo: nil)
        
        var resultImage: CGImage?
        
        // Execute the method
        sut.loadImage(from: testURL) { image in
            resultImage = image
            expectation.fulfill()
        }
        
        // Check if it worked
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockURLSession.dataTaskWasCalled, "Network request should be made")
        XCTAssertNil(resultImage, "Should return nil for network error")
    }
    
    func testHandlesInvalidImageDataGracefully() throws {
        // Start with test data
        let expectation = expectation(description: "Invalid data handled")
        let testURL = URL(string: "https://example.com/invalid.jpg")!
        
        // Just some gibberish data
        let invalidData = "not an image".data(using: .utf8)!
        
        mockURLSession.nextData = invalidData
        mockURLSession.nextResponse = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        var resultImage: CGImage?
        
        // Call the function
        sut.loadImage(from: testURL) { image in
            resultImage = image
            expectation.fulfill()
        }
        
        // See what happened
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockURLSession.dataTaskWasCalled, "Network request should be made")
        XCTAssertNil(resultImage, "Should return nil for invalid image data")
    }
    
    // Test utilities
    
    private func createTestImageData() -> Data {
        // Make a tiny test image
        let size = 1
        let bitsPerComponent = 8
        let bytesPerRow = 4 * size
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ),
        let cgImage = context.makeImage() else {
            fatalError("Could not create test image")
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        guard let pngData = CIContext().pngRepresentation(of: ciImage, format: .RGBA8, colorSpace: colorSpace) else {
            fatalError("Could not create PNG data")
        }
        
        return pngData
    }
    
    private func saveTestImageToCache(data: Data, url: URL) throws {
        let cacheURL = sut.diskCacheURL(for: url.absoluteString)!
        try data.write(to: cacheURL)
    }
}

// Test doubles

class MockURLSession: URLSessionProtocol {
    var dataTaskWasCalled = false
    var lastURL: URL?
    
    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?
    
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        dataTaskWasCalled = true
        lastURL = url
        
        let task = MockURLSessionDataTask {
            completionHandler(self.nextData, self.nextResponse, self.nextError)
        }
        
        return task
    }
}

class MockURLSessionDataTask: URLSessionDataTaskProtocol {
    private let completionHandler: () -> Void
    
    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
    
    func resume() {
        completionHandler()
    }
}
