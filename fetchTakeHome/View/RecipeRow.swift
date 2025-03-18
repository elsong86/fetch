import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe
    @State private var image: CGImage? = nil
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe image
            Group {
                if loadFailed || (image == nil && !isLoading) {
                    // Show placeholder when we can't load the image
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                } else if let cgImage = image {
                    // Successfully loaded image
                    Image(decorative: cgImage, scale: 1.0, orientation: .up)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            .redacted(reason: isLoading ? .placeholder : [])
            
            // Recipe details
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .redacted(reason: isLoading ? .placeholder : [])
        }
        .padding(.vertical, 8)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Reset state when loading a new image
        isLoading = true
        loadFailed = false
        
        // Only attempt to load if we have a URL
        guard let urlString = recipe.photoURLSmall,
              let url = URL(string: urlString) else {
            isLoading = false
            loadFailed = true
            return
        }
        
        // Use ImageCacheManager to load the image
        ImageCacheManager.shared.loadImage(from: url) { loadedImage in
            // The loadImage completion handler might be called on a background thread
            // so we ensure we update our state on the main thread
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
