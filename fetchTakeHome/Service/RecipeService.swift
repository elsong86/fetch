import Foundation

// Protocol for testable URLSession with async/await
protocol URLSessionProtocolAsync {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocolAsync {}

class RecipeService {
    // Add dependency injection for URLSession
    private let session: URLSessionProtocolAsync
    
    init(session: URLSessionProtocolAsync = URLSession.shared) {
        self.session = session
    }
    
    func fetchRecipes() async throws -> RecipeResponse {
        guard let url = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json") else {
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            do {
                let recipes = try JSONDecoder().decode(RecipeResponse.self, from: data)
                return recipes
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
}
