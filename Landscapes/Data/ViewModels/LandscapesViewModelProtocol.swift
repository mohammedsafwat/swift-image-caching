//
//  LandscapesViewModelProtocol.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-11.
//

import Foundation

protocol LandscapesViewModelProtocol {
    var onLandscapesUpdated: (() -> Void)? { get set }
    var onError: (() -> Void)? { get set }
    func fetchLandscapes(url: String)
}
