//
//  LandscapesTableViewCell.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-11.
//

import UIKit

final class LandscapesTableViewCell: UITableViewCell {

    // MARK: - Initializer

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel.font = .boldSystemFont(ofSize: 16)
        landscapeImageView.contentMode = .scaleAspectFill
        landscapeImageView.clipsToBounds = true
        landscapeImageView.layer.cornerRadius = 8
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // MARK: - Object lifecycle
    
    override func prepareForReuse() {
        landscapeImageView.image = nil
        imageRequest?.cancel()
    }
    
    // MARK: - Internal

    func configure(title: String, imageUrl: URL) {
        titleLabel.text = title
        
        imageRequest = imageService.image(for: imageUrl) { [weak self] image in
            if let image = image {
                self?.landscapeImageView.image = image
                self?.landscapeImageViewWidthConstraint.constant = image.size.width * (image.size.height / image.size.width)
            }
        }
    }

    // MARK: - Private

    private func setupViews() {
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 8
        horizontalStackView.addArrangedSubview(landscapeImageView)
        horizontalStackView.addArrangedSubview(titleLabel)
        addSubview(horizontalStackView)
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 8),
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            landscapeImageViewWidthConstraint,
        ]
        NSLayoutConstraint.activate(constraints.compactMap {$0})
    }

    private let titleLabel: UILabel = UILabel(frame: .zero)
    private let landscapeImageView: UIImageView = UIImageView(frame: .zero)
    private var imageRequest: Cancellable?
    private var horizontalStackView = UIStackView(frame: .zero)
    private lazy var imageService = ImageService(maximumCacheSizeInMemory: 512 * .kilobyte, maximumCacheSizeOnDisk: 50 * .kilobyte)
    private lazy var landscapeImageViewWidthConstraint: NSLayoutConstraint = {
        landscapeImageView.widthAnchor.constraint(equalToConstant: 0)
    }()
}
