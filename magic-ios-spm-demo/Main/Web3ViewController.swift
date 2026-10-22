//
//  Web3ViewController.swift
//
//  The Web3 tab. A segmented control switches between the EVM, Solana and
//  Bitcoin pages, each one a `ChainDemoViewController`.

import UIKit

class Web3ViewController: UIViewController {

    static let storyboardIdentifier = "web3"

    private let pages: [(title: String, controller: ChainDemoViewController)] = [
        ("EVM", EVMViewController()),
        ("Solana", SolanaViewController()),
        ("Bitcoin", BitcoinViewController())
    ]
    private let chainControl = UISegmentedControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        for (index, page) in pages.enumerated() {
            chainControl.insertSegment(withTitle: page.title, at: index, animated: false)
        }
        chainControl.selectedSegmentIndex = 0
        chainControl.addTarget(self, action: #selector(chainChanged), for: .valueChanged)
        chainControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chainControl)
        NSLayoutConstraint.activate([
            chainControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            chainControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chainControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        for page in pages {
            let child = page.controller
            addChild(child)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            NSLayoutConstraint.activate([
                child.view.topAnchor.constraint(equalTo: chainControl.bottomAnchor, constant: 12),
                child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                child.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
            child.didMove(toParent: self)
        }
        showSelectedPage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pages[chainControl.selectedSegmentIndex].controller.refreshAddressIfNeeded()
    }

    @objc private func chainChanged() {
        showSelectedPage()
    }

    /// Shows the selected page and hides the others. The hidden pages keep their last result.
    private func showSelectedPage() {
        for (index, page) in pages.enumerated() {
            page.controller.view.isHidden = index != chainControl.selectedSegmentIndex
        }
        pages[chainControl.selectedSegmentIndex].controller.refreshAddressIfNeeded()
    }
}
