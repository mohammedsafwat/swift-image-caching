//
//  ImageService.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 15.08.22.
//

import UIKit

final class ImageService: ImageServiceProtocol {
    
    // MARK: - Initializer
    
    init(maximumCacheSize: Int) {
        self.maximumCacheSize = maximumCacheSize
    }
    
    // MARK: - Internal
    
    func image(for url: URL, completion: @escaping (UIImage?) -> Void) -> Cancellable {
        if let cachedImage = cachedImage(for: url) {
            completion(cachedImage)
            return CachedRequest()
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            var image: UIImage?
            
            defer {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
            
            if let data = data {
                image = UIImage(data: data)
                self?.cacheImage(data, for: url)
            }
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    // MARK: - Private
    
    private struct CachedImage {
        let url: URL
        let data: Data
    }
    private struct CachedRequest: Cancellable {
        func cancel() {}
    }
    
    private let maximumCacheSize: Int
    private var cache: [CachedImage] = []
    
    private func cachedImage(for url: URL) -> UIImage? {
        guard let data = cache.first(where: { $0.url == url })?.data else { return nil }
        return UIImage(data: data)
    }
    
    private func cacheImage(_ data: Data, for url: URL) {
        var cacheSize = cache.reduce(0) { result, cachedImage -> Int in
            result + cachedImage.data.count
        }
        
        while cacheSize > maximumCacheSize {
            let oldestCachedImage = cache.removeFirst()
            cacheSize -= oldestCachedImage.data.count
        }
        
        let cachedImage = CachedImage(url: url, data: data)
        cache.append(cachedImage)
    }
}

// MARK: - URLSessionTask

extension URLSessionTask: Cancellable {}
