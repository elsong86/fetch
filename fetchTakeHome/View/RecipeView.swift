import SwiftUI

struct RecipeView: View {
    let recipe: Recipe
    @State private var image: CGImage? = nil
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe Image
                Group {
                    if loadFailed || (image == nil && !isLoading) {
                        // Fallback image when load fails
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    } else if let cgImage = image {
                        // Successfully loaded image
                        Image(decorative: cgImage, scale: 1.0, orientation: .up)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        // Placeholder for loading state
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .clipped()
                .redacted(reason: isLoading ? .placeholder : [])
                
                // Recipe Info
                VStack(alignment: .leading, spacing: 20) {
                    // Name and Cuisine
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                            Text(recipe.cuisine)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .redacted(reason: isLoading ? .placeholder : [])
                    
                    // Sources Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sources")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        // Source URL Link
                        if let sourceURL = recipe.sourceURL, let url = URL(string: sourceURL) {
                            Button(action: {
                                openURL(url)
                            }) {
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(.blue)
                                    Text("View Original Recipe")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // YouTube URL Link
                        if let youtubeURL = recipe.youtubeURL, let url = URL(string: youtubeURL) {
                            Button(action: {
                                openURL(url)
                            }) {
                                HStack {
                                    Image(systemName: "play.rectangle.fill")
                                        .foregroundColor(.red)
                                    Text("Watch Recipe Video")
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // No sources available
                        if recipe.sourceURL == nil && recipe.youtubeURL == nil {
                            Text("No external sources available for this recipe.")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitle(recipe.name, displayMode: .inline)
        .onAppear {
            loadLargeImage()
        }
    }
    
    private func loadLargeImage() {
        // Reset state when loading a new image
        isLoading = true
        loadFailed = false
        
        // Try to use large photo URL first, fallback to small
        let urlString = recipe.photoURLLarge ?? recipe.photoURLSmall
        
        // Only attempt to load if we have a URL
        guard let urlStr = urlString,
              let url = URL(string: urlStr) else {
            isLoading = false
            loadFailed = true
            return
        }
        
        // Use ImageCacheManager to load the image
        ImageCacheManager.shared.loadImage(from: url) { loadedImage in
            DispatchQueue.main.async {
                isLoading = false
                
                if let loadedImage = loadedImage {
                    self.image = loadedImage
                } else {
                    loadFailed = true
                }
            }
        }
    }
}
