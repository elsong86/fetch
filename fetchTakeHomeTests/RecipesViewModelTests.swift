import XCTest
@testable import fetchTakeHome

@MainActor // Need this for UI updates
class RecipesViewModelTests: XCTestCase {
    
    var sut: RecipesViewModel!
    var mockRecipeService: MockRecipeService!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockRecipeService = MockRecipeService()
        sut = RecipesViewModel(recipeService: mockRecipeService)
    }
    
    @MainActor
    override func tearDownWithError() throws {
        sut = nil
        mockRecipeService = nil
        try super.tearDownWithError()
    }
    
    // ViewModel tests
    
    func testLoadRecipesSuccess() async {
        // Set up some fake recipes
        let testRecipes = [
            Recipe(id: "1", name: "Recipe 1", cuisine: "Italian", photoURLLarge: "https://example.com/large1.jpg", photoURLSmall: "https://example.com/small1.jpg", sourceURL: nil, youtubeURL: nil),
            Recipe(id: "2", name: "Recipe 2", cuisine: "Mexican", photoURLLarge: "https://example.com/large2.jpg", photoURLSmall: "https://example.com/small2.jpg", sourceURL: nil, youtubeURL: nil)
        ]
        mockRecipeService.mockResponse = RecipeResponse(recipes: testRecipes)
        
        // Load them
        await sut.loadRecipes()
        
        // Make sure they loaded right
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.recipes.count, 2)
        XCTAssertEqual(sut.recipes.first?.id, "1")
        XCTAssertEqual(sut.recipes.first?.name, "Recipe 1")
        XCTAssertEqual(sut.recipes.last?.id, "2")
        XCTAssertEqual(sut.recipes.last?.name, "Recipe 2")
    }
    
    func testLoadRecipesEmptyResponse() async {
        // Empty list test
        mockRecipeService.mockResponse = RecipeResponse(recipes: [])
        
        // Try loading
        await sut.loadRecipes()
        
        // Should be empty but not error
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.recipes.isEmpty)
    }
    
    func testLoadRecipesNetworkError() async {
        // Trigger a general network error
        let testError = NSError(domain: "com.test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        mockRecipeService.mockError = testError
        
        // Try to load
        await sut.loadRecipes()
        
        // Should get the error
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.recipes.isEmpty)
        XCTAssertEqual(sut.errorMessage, "Network error")
    }
    
    func testLoadRecipesURLError() async {
        // No internet scenario
        let testError = URLError(.notConnectedToInternet)
        mockRecipeService.mockError = testError
        
        // Try loading
        await sut.loadRecipes()
        
        // Should get a nice error message
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.recipes.isEmpty)
        XCTAssertEqual(sut.errorMessage, "No internet connection. Please check your network settings and try again.")
    }
    
    func testLoadRecipesDecodingError() async {
        // Bad JSON test
        mockRecipeService.mockError = DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON"))
        
        // Try loading
        await sut.loadRecipes()
        
        // Should fail gracefully
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.recipes.isEmpty)
        XCTAssertEqual(sut.errorMessage, "Error parsing recipe data. Please try again later.")
    }
}

// Test double for RecipeService

class MockRecipeService: RecipeService {
    var mockResponse: RecipeResponse?
    var mockError: Error?
    
    init() {
        // Just need something here
        super.init(session: URLSession.shared)
    }
    
    override func fetchRecipes() async throws -> RecipeResponse {
        if let error = mockError {
            throw error
        }
        
        if let response = mockResponse {
            return response
        }
        
        throw NSError(domain: "com.test", code: 999, userInfo: [NSLocalizedDescriptionKey: "No mock data provided"])
    }
}
