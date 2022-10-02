//
//  ViewController.swift
//  Landscapes
//
//  Created by Mohammed Abdullatif on 2022-08-10.
//

import UIKit

final class LandscapesViewController: UIViewController {

    // MARK: - Initializer

    init(viewModel: LandscapesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.onLandscapesUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - NSCoding

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        viewModel.fetchLandscapes(url: Constants.landscapesData)
    }

    // MARK: - UITableView

    private func setupViews() {
        title = "Landscapes"
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LandscapesTableViewCell.self, forCellReuseIdentifier: Constants.landscapesCellIdentifier)
    }

    // MARK: - Private

    private let tableView: UITableView = UITableView(frame: .zero)
    private let viewModel: LandscapesViewModel
}

// MARK: - UITableViewDataSource

extension LandscapesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.landscapesCellIdentifier
        ) as? LandscapesTableViewCell else {
            fatalError("The UITableViewCell was not registered correctly")
        }
        guard indexPath.row < viewModel.landscapes.count else {
            return cell
        }
        let landscape = viewModel.landscapes[indexPath.row]
        cell.configure(title: landscape.title, imageUrl: landscape.imageUrl)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.landscapes.count
    }
}

// MARK: - UITableViewDelegate

extension LandscapesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
}

