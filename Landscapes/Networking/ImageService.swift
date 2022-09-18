//
//  ImageService.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 15.08.22.
//

import Foundation
import UIKit

final class ImageService: ImageServiceProtocol {
    
    // MARK: - Initializer
    
    init(maximumCacheSize: Int) {
        self.maximumCacheSize = maximumCacheSize
        createImageCacheDirectory()
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
                print(url)
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
        if let data = cache.first(where: { $0.url == url })?.data {
            print("Using Cache in Memory")
            return UIImage(data: data)
        } else if let data = try? Data(contentsOf: locationOnDesk(for: url)) {
            print("Using Cache on Disk")
            cacheImage(data, for: url)
            return UIImage(data: data)
        }
        return nil
    }
    
    private func cacheImage(_ data: Data, for url: URL, writeToDisk: Bool = true) {
        var cacheSize = cache.reduce(0) { result, cachedImage -> Int in
            result + cachedImage.data.count
        }
        
        while cacheSize > maximumCacheSize {
            let oldestCachedImage = cache.removeFirst()
            cacheSize -= oldestCachedImage.data.count
        }
        
        let cachedImage = CachedImage(url: url, data: data)
        cache.append(cachedImage)

        if writeToDisk {
            DispatchQueue.global(qos: .utility).async {
                self.writeImageToDisk(data, for: url)
            }
        }
    }

    private var imageCacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache")
    }

    private func createImageCacheDirectory() {
        do {
            try FileManager.default.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)
        } catch {
            print("Unable to create image cache directory")
        }
    }

    private func locationOnDesk(for url: URL) -> URL {
        let fileName = Data(url.absoluteString.utf8).base64EncodedString()
        return imageCacheDirectory.appendingPathComponent(fileName)
    }

    private func writeImageToDisk(_ data: Data, for url: URL) {
        do {
            try data.write(to: locationOnDesk(for: url))
        } catch {
            print("Unable to Write Image to Disk \(error)")
        }
    }
}

// MARK: - URLSessionTask

extension URLSessionTask: Cancellable {}
