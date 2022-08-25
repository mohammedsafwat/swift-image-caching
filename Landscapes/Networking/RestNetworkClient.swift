//
//  RestNetworkClient.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-11.
//

import Foundation

final class RestNetworkClient: ApiClientProtocol {
    func performRequest<T>(url: URL, completion: @escaping (Result<T, DataError>) -> Void) where T: Decodable {
        dataTask?.cancel()

        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(.failure(.requestFailed))
                return
            }

            DispatchQueue.main.async {
                do {
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(.parsingFailed))
                }
            }
        }

        dataTask?.resume()
    }

    // MARK: - Private

    private var dataTask: URLSessionDataTask?
}
