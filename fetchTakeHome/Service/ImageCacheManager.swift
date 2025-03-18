import Foundation
import CoreGraphics
import ImageIO
import SwiftUI

// Protocol for URLSession to enable testing
protocol URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

// Extensions to make URLSession conform to our protocol
extension URLSession: URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProtocol {
        return dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTask
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

/// A manager class that handles caching images to disk and retrieving them when needed
class ImageCacheManager {
    // Singleton instance
    static let shared = ImageCacheManager()
    
    // Changed from private to internal for testing
    internal var cacheDirectoryURL: URL?
    
    // URLSession dependency added for testing
    private let urlSession: URLSessionProtocol
    
    // Default initializer (private) for singleton usage
    private init() {
        self.urlSession = URLSession.shared
        // Create cache directory if it doesn't exist
        createCacheDirectoryIfNeeded()
    }
    
    // Additional initializer for testing
    internal init(cacheDirectory: URL? = nil, session: URLSessionProtocol = URLSession.shared) {
        self.urlSession = session
        
        if let cacheDirectory = cacheDirectory {
            self.cacheDirectoryURL = cacheDirectory
        } else {
            createCacheDirectoryIfNeeded()
        }
    }
    
    
    // Tries to get image from disk cache first, falls back to network if needed
    // Returns the CGImage via completion handler or nil if it fails
    func loadImage(from url: URL, completion: @escaping (CGImage?) -> Void) {
        let urlString = url.absoluteString
        
        // Check if the image is in disk cache first
        if let diskCachedImage = loadImageFromDisk(with: urlString) {
            completion(diskCachedImage)
            return
        }
        
        // If not in cache, download from network
        urlSession.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            if error != nil {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Use Image I/O for efficient image creation from data
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Save to disk cache
            self.saveImageToDisk(data, with: urlString)
            
            DispatchQueue.main.async {
                completion(cgImage)
            }
        }.resume()
    }
    
    
    // MARK: - Private Methods
    
    private func createCacheDirectoryIfNeeded() {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        
        self.cacheDirectoryURL = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        guard let cacheDirectory = cacheDirectoryURL else { return }
        
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                // Silently fail - we can't create the cache directory
            }
        }
    }
    
    // Changed from private to internal for testing
    internal func diskCacheURL(for key: String) -> URL? {
        guard let cacheDirectory = cacheDirectoryURL else {
            return nil
        }
        
        // Create a filename-safe hash of the URL
        let hashedKey = key.hashValue
        let fileURL = cacheDirectory.appendingPathComponent("\(hashedKey)")
        return fileURL
    }
    
    private func saveImageToDisk(_ data: Data, with key: String) {
        guard let url = diskCacheURL(for: key) else {
            return
        }
        
        do {
            try data.write(to: url)
        } catch {
            // Silently fail - we can't save to the cache
        }
    }
    
    private func loadImageFromDisk(with key: String) -> CGImage? {
        guard let url = diskCacheURL(for: key) else {
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Use Image I/O for efficient image loading
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                return nil
            }
            
            return cgImage
        } catch {
            return nil
        }
    }
}
