//
//  Landscape.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-11.
//

import Foundation

struct Landscape: Decodable {

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case title
        case imageUrl = "image_url"
    }

    // MARK: - Properties

    let title: String
    let imageUrl: URL
}
