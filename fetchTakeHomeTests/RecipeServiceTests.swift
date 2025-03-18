import XCTest
@testable import fetchTakeHome

class RecipeServiceTests: XCTestCase {
    
    var sut: RecipeService!
    var mockURLSession: URLSessionMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockURLSession = URLSessionMock()
        sut = RecipeService(session: mockURLSession)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockURLSession = nil
        try super.tearDownWithError()
    }
    
    // Network tests
    
    func testFetchRecipesSuccess() async throws {
        // Setup with sample JSON
        let jsonData = """
        {
            "recipes": [
                {
                    "uuid": "1234",
                    "name": "Test Recipe",
                    "cuisine": "Test Cuisine",
                    "photo_url_large": "https://example.com/large.jpg",
                    "photo_url_small": "https://example.com/small.jpg",
                    "source_url": "https://example.com/recipe",
                    "youtube_url": "https://youtube.com/watch?v=test"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        mockURLSession.mockDataAndResponse(for: url, data: jsonData, response: response, error: nil)
        
        // Try fetching
        let result = try await sut.fetchRecipes()
        
        // Check everything matches
        XCTAssertEqual(result.recipes.count, 1, "Should receive 1 recipe")
        XCTAssertEqual(result.recipes[0].id, "1234")
        XCTAssertEqual(result.recipes[0].name, "Test Recipe")
        XCTAssertEqual(result.recipes[0].cuisine, "Test Cuisine")
        XCTAssertEqual(result.recipes[0].photoURLLarge, "https://example.com/large.jpg")
        XCTAssertEqual(result.recipes[0].photoURLSmall, "https://example.com/small.jpg")
        XCTAssertEqual(result.recipes[0].sourceURL, "https://example.com/recipe")
        XCTAssertEqual(result.recipes[0].youtubeURL, "https://youtube.com/watch?v=test")
    }
    
    func testFetchRecipesEmptyResponse() async throws {
        // Empty response test
        let jsonData = """
        {
            "recipes": []
        }
        """.data(using: .utf8)!
        
        let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        mockURLSession.mockDataAndResponse(for: url, data: jsonData, response: response, error: nil)
        
        // Call the API
        let result = try await sut.fetchRecipes()
        
        // Should be empty but valid
        XCTAssertEqual(result.recipes.count, 0, "Should receive 0 recipes")
    }
    
    func testFetchRecipesNetworkError() async {
        // Mock a network failure
        let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!
        let error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        mockURLSession.mockDataAndResponse(for: url, data: nil, response: nil, error: error)
        
        // Try and expect failure
        do {
            _ = try await sut.fetchRecipes()
            XCTFail("Expected network error")
        } catch {
            // This should happen
            XCTAssertEqual((error as NSError).domain, "test")
        }
    }
    
    func testFetchRecipesBadStatusCode() async {
        // Set up a 404 response
        let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!
        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
        
        mockURLSession.mockDataAndResponse(for: url, data: Data(), response: response, error: nil)
        
        // Make sure it throws correctly
        do {
            _ = try await sut.fetchRecipes()
            XCTFail("Expected bad status code error")
        } catch {
            // Got the error we wanted
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }
    
    func testFetchRecipesMalformedJSON() async {
        // Bad JSON data
        let invalidJSON = "{ this is not valid JSON }".data(using: .utf8)!
        let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        mockURLSession.mockDataAndResponse(for: url, data: invalidJSON, response: response, error: nil)
        
        // Should fail to parse
        do {
            _ = try await sut.fetchRecipes()
            XCTFail("Expected JSON parsing error")
        } catch {
            // Parser should complain
            XCTAssertTrue(error is DecodingError)
        }
    }
}

// Mock networking for tests

// This mocks our async URLSession
class URLSessionMock: URLSessionProtocolAsync {
    private var mockData: [URL: (data: Data?, response: URLResponse?, error: Error?)] = [:]
    
    func mockDataAndResponse(for url: URL, data: Data?, response: URLResponse?, error: Error?) {
        mockData[url] = (data, response, error)
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        guard let mock = mockData[url] else {
            throw URLError(.badURL)
        }
        
        if let error = mock.error {
            throw error
        }
        
        guard let data = mock.data, let response = mock.response else {
            throw URLError(.cannotParseResponse)
        }
        
        return (data, response)
    }
}
