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
    
    init(maximumCacheSizeInMemory: Int, maximumCacheSizeOnDisk: Int) {
        self.maximumCacheSizeInMemory = maximumCacheSizeInMemory
        self.maximumCacheSizeOnDisk = maximumCacheSizeOnDisk
        createImageCacheDirectory()
        updateCacheOnDisk()
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
    private let maximumCacheSizeInMemory: Int
    private let maximumCacheSizeOnDisk: Int
    private let cacheOnDiskQueue = DispatchQueue(label: "Cache on disk", qos: .utility)
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
        
        while cacheSize > maximumCacheSizeInMemory {
            let oldestCachedImage = cache.removeFirst()
            cacheSize -= oldestCachedImage.data.count
        }
        
        let cachedImage = CachedImage(url: url, data: data)
        cache.append(cachedImage)

        if writeToDisk {
            cacheOnDiskQueue.async {
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
            updateCacheOnDisk()
        } catch {
            print("Unable to Write Image to Disk \(error)")
        }
    }

    private func updateCacheOnDisk() {
        do {
            let resourceKeys: [URLResourceKey] = [.creationDateKey, .totalFileAllocatedSizeKey]
            let contents = try FileManager.default.contentsOfDirectory(
                at: imageCacheDirectory,
                includingPropertiesForKeys: resourceKeys,
                options: []
            )

            var files = try contents.compactMap { url -> File? in
                let resourcesValues = try url.resourceValues(forKeys: Set(resourceKeys))

                guard let createdAt = resourcesValues.creationDate,
                      let size = resourcesValues.totalFileAllocatedSize
                else {
                    return nil
                }
                return File(url: url, size: size, createdAt: createdAt)
            }
            .sorted { $0.createdAt < $1.createdAt }

            var cacheSize = files.reduce(0) { result, cachedImage -> Int in
                result + cachedImage.size
            }

            print("\(files.count) Images Cached, Size on Disk \(cacheSize / .kilobyte) KB")

            while cacheSize > maximumCacheSizeOnDisk {
                guard !files.isEmpty else {
                    break
                }

                let oldestCachedImage = files.removeFirst()
                try FileManager.default.removeItem(at: oldestCachedImage.url)
                cacheSize -= oldestCachedImage.size
            }
        } catch {
            print("Unable to update cache on disk \(error)")
        }
    }

    private struct File {
        let url: URL
        let size: Int
        let createdAt: Date
    }
}

// MARK: - URLSessionTask

extension URLSessionTask: Cancellable {}
