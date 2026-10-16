//
//  ChainDemoViewController.swift
//
//  Shared layout for one chain on the Web3 page (EVM, Solana or Bitcoin):
//  an address card, a scrollable list of actions grouped in sections, and a
//  result card that shows the last response.

import UIKit
import MagicSDK_Web3

class ChainDemoViewController: UIViewController {

    /// Caption above the address, e.g. "Solana address".
    var addressTitle: String { "Address" }

    /// Space above the address card. Zero when a parent supplies the gap, as on the Web3 page.
    var topInset: CGFloat { 0 }

    private(set) var address: String?

    private let addressLabel = UILabel()
    private let copyButton = UIButton(type: .system)
    private let actionStack = UIStackView()
    private let resultView = UITextView()
    private var isLoadingAddress = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
    }

    // MARK: - Address

    /// Subclasses fetch the address here and report it with `didLoadAddress`.
    func loadAddress() {}

    /// Loads the address the first time the page is shown.
    func refreshAddressIfNeeded() {
        guard address == nil, !isLoadingAddress else { return }
        isLoadingAddress = true
        addressLabel.text = "Loading..."
        loadAddress()
    }

    /// Reports the outcome of `loadAddress`. Pass `failure` text when there is no address.
    func didLoadAddress(_ address: String?, failure: String? = nil) {
        DispatchQueue.main.async {
            self.isLoadingAddress = false
            self.address = address
            self.addressLabel.text = address ?? failure ?? "Not available"
            self.copyButton.isHidden = address == nil
        }
    }

    // MARK: - Building the page

    func addSection(_ title: String) {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        if let last = actionStack.arrangedSubviews.last {
            actionStack.setCustomSpacing(20, after: last)
        }
        actionStack.addArrangedSubview(label)
    }

    /// Adds a full-width button. `detail` is a second line, such as the RPC method.
    func addAction(_ title: String, detail: String? = nil, action: @escaping () -> Void) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.subtitle = detail
        config.titleAlignment = .leading
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        config.cornerStyle = .medium
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in action() })
        button.contentHorizontalAlignment = .leading
        actionStack.addArrangedSubview(button)
    }

    // MARK: - Results

    func show(_ text: String) {
        DispatchQueue.main.async {
            self.resultView.text = text
            self.resultView.setContentOffset(.zero, animated: false)
        }
    }

    /// Shows the formatted result, or the error, of an SDK call.
    func handle<T>(_ response: Web3Response<T>, format: @escaping (T) -> String) {
        if let error = response.error {
            show("Error: \(error.localizedDescription)")
        } else if let result = response.result {
            show(format(result))
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        let addressCard = makeCard()
        let addressCaption = makeCaption(addressTitle)
        addressLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        addressLabel.numberOfLines = 0
        addressLabel.lineBreakMode = .byCharWrapping
        addressLabel.text = "Loading..."

        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.tintColor = .secondaryLabel
        copyButton.isHidden = true
        copyButton.addAction(UIAction { [weak self] _ in self?.copyAddress() }, for: .touchUpInside)
        copyButton.setContentHuggingPriority(.required, for: .horizontal)

        let captionRow = UIStackView(arrangedSubviews: [addressCaption, copyButton])
        captionRow.alignment = .center
        let addressStack = UIStackView(arrangedSubviews: [captionRow, addressLabel])
        addressStack.axis = .vertical
        addressStack.spacing = 4
        pin(addressStack, in: addressCard, inset: 12)

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        actionStack.axis = .vertical
        actionStack.spacing = 8
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(actionStack)

        let resultCard = makeCard()
        let resultCaption = makeCaption("Result")
        resultView.isEditable = false
        resultView.backgroundColor = .clear
        resultView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        resultView.textContainerInset = .zero
        resultView.textContainer.lineFragmentPadding = 0
        resultView.text = "Tap an action to see its result here."
        resultView.textColor = .label
        let resultStack = UIStackView(arrangedSubviews: [resultCaption, resultView])
        resultStack.axis = .vertical
        resultStack.spacing = 4
        pin(resultStack, in: resultCard, inset: 12)

        [addressCard, scrollView, resultCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            addressCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset),
            addressCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addressCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: addressCard.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: resultCard.topAnchor, constant: -12),

            actionStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            actionStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            actionStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            actionStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            actionStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            resultCard.leadingAnchor.constraint(equalTo: addressCard.leadingAnchor),
            resultCard.trailingAnchor.constraint(equalTo: addressCard.trailingAnchor),
            resultCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            resultCard.heightAnchor.constraint(equalToConstant: 130)
        ])
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        return card
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }

    private func pin(_ content: UIView, in card: UIView, inset: CGFloat) {
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: inset),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -inset),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -inset)
        ])
    }

    private func copyAddress() {
        guard let address = address else { return }
        UIPasteboard.general.string = address
        copyButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        }
    }
}
