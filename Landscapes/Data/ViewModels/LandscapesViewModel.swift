//
//  LandscapesViewModel.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-11.
//

import Foundation

final class LandscapesViewModel: LandscapesViewModelProtocol {

    // MARK: - Initializer

    init(networkClient: ApiClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - LandscapesViewModelProtocol

    func fetchLandscapes(url: String) {
        guard let landscapesUrl = URL(string: url) else {
            return
        }
        networkClient.performRequest(url: landscapesUrl) { (result: Result<[Landscape], DataError>) in
            switch result {
            case .success(let landscapes):
                self.landscapes = landscapes
            case .failure(let error):
                self.error = error
            }
        }
    }

    var onLandscapesUpdated: (() -> Void)?
    var onError: (() -> Void)?

    // MARK: - Private

    private let networkClient: ApiClientProtocol
    private(set) var landscapes: [Landscape] = [] {
        didSet {
            onLandscapesUpdated?()
        }
    }
    private(set) var error: DataError = .unknown {
        didSet {
            onError?()
        }
    }
}
