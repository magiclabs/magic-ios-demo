//
//  ChainDemoViewController.swift
//
//  Shared layout for the Solana and Bitcoin demo tabs: a column of buttons
//  and a selectable text view that shows the last result.

import UIKit
import MagicSDK_Web3

class ChainDemoViewController: UIViewController {

    private let stack = UIStackView()
    private let resultView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        resultView.isEditable = false
        resultView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        resultView.layer.borderColor = UIColor.separator.cgColor
        resultView.layer.borderWidth = 1
        resultView.layer.cornerRadius = 8
        resultView.text = "Results show here."
        resultView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(resultView)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            resultView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 24),
            resultView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            resultView.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            resultView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    func addButton(_ title: String, action: @escaping () -> Void) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .black
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        config.cornerStyle = .medium
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        stack.addArrangedSubview(button)
    }

    func show(_ text: String) {
        DispatchQueue.main.async { self.resultView.text = text }
    }

    /// Shows the formatted result, or the error, of an SDK call.
    func handle<T>(_ response: Web3Response<T>, format: @escaping (T) -> String) {
        if let error = response.error {
            show("Error: \(error.localizedDescription)")
        } else if let result = response.result {
            show(format(result))
        }
    }
}
