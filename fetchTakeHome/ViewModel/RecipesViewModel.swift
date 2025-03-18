import Foundation

@MainActor
class RecipesViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let recipeService: RecipeService
    
    init(recipeService: RecipeService = RecipeService()) {
        self.recipeService = recipeService
    }
    
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await recipeService.fetchRecipes()
            
            recipes = response.recipes
            isLoading = false
        } catch {
            
            // Figure out what went wrong and tell the user
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    errorMessage = "No internet connection. Please check your network settings and try again."
                case .timedOut:
                    errorMessage = "Request timed out. Please try again."
                case .badURL, .unsupportedURL:
                    errorMessage = "Invalid URL. Please contact support."
                case .badServerResponse, .serverCertificateUntrusted:
                    errorMessage = "Server error. Please try again later."
                default:
                    errorMessage = "Network error: \(urlError.localizedDescription)"
                }
            } else if error is DecodingError {
                errorMessage = "Error parsing recipe data. Please try again later."
            } else {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}
