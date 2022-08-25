//
//  ImageServiceProtocol.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 17.08.22.
//

import Foundation
import UIKit

protocol ImageServiceProtocol {
    func image(for url: URL, completion: @escaping (UIImage?) -> Void) -> Cancellable
}
