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
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            let result: Result<Data, Error>? = {
                if let data = data {
                    // Success
                    return .success(data)
                } else if let error = error, (error as NSError).code != URLError.cancelled.rawValue {
                    // Failure
                    return .failure(error)
                } else {
                    // Cancelled
                    return nil
                }
            }()

            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("Data Task Succeeded")
                    completion(UIImage(data: data))
                    self?.cacheImage(data, for: url)
                case .failure:
                    print("Data Task Failed")
                    completion(nil)
                case .none:
                    print("Data Task Cancelled")
                    break
                }
            }
        }

        // Request Cached Image
        cachedImage(for: url) { image in
            if let image = image {
                // Execute Handler on Main Thread
                DispatchQueue.main.async {
                    // Execute Handler
                    completion(image)
                }
            } else {
                // Fetch Image
                dataTask.resume()
            }
        }

        return dataTask
    }
    
    // MARK: - Private
    
    private struct CachedImage {
        let url: URL
        let data: Data
    }
    private let maximumCacheSize: Int
    private var cache: [CachedImage] = []
    
    private func cachedImage(for url: URL, completion: @escaping (UIImage?) -> Void) {
        if let data = cache.first(where: { $0.url == url })?.data {
            print("Using Cache in Memory")
            completion(UIImage(data: data))
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let data = try? Data(contentsOf: self.locationOnDesk(for: url)) else {
                    completion(nil)
                    return
                }
                print("Using Cache on Disk")
                self.cacheImage(data, for: url, writeToDisk: false)
                completion(UIImage(data: data))
            }
        }
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
