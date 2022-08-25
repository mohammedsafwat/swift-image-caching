//
//  ApiClientProtocol.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-11.
//

import Foundation

protocol ApiClientProtocol {
    func performRequest<T>(url: URL, completion: @escaping (Result<T, DataError>) -> Void) where T: Decodable
}
