import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecipesViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Main content
                if let errorMessage = viewModel.errorMessage {
                    // Error state
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.title)
                            .padding(.top)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            loadRecipes()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if !viewModel.isLoading && viewModel.recipes.isEmpty {
                    // Empty state
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                        Text("No Recipes Found")
                            .font(.title)
                            .padding(.top)
                        Button("Refresh") {
                            loadRecipes()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    // Recipes list with redaction for loading state
                    List {
                        // Show placeholder rows when loading
                        if viewModel.isLoading && viewModel.recipes.isEmpty {
                            // Create dummy recipe placeholders
                            ForEach(0..<10, id: \.self) { _ in
                                RecipeRow(recipe: Recipe(
                                    id: UUID().uuidString,
                                    name: "Loading Recipe",
                                    cuisine: "Loading Cuisine",
                                    photoURLLarge: nil,
                                    photoURLSmall: nil,
                                    sourceURL: nil,
                                    youtubeURL: nil
                                ))
                                .redacted(reason: .placeholder)
                                .disabled(true)
                            }
                        } else {
                            // Show actual recipes with navigation links
                            ForEach(viewModel.recipes) { recipe in
                                NavigationLink(destination: RecipeView(recipe: recipe)) {
                                    RecipeRow(recipe: recipe)
                                }
                            }
                            .redacted(reason: viewModel.isLoading ? .placeholder : [])
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .refreshable {
                        await viewModel.loadRecipes()
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: loadRecipes) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            loadRecipes()
        }
    }
    
    private func loadRecipes() {
        Task {
            await viewModel.loadRecipes()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
