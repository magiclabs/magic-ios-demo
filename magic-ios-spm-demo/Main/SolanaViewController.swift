//
//  SolanaViewController.swift
//
//  Demo of the Solana extension (`SolanaConfiguration` in AppDelegate).

import UIKit
import MagicSDK
import MagicSDK_Web3

class SolanaViewController: ChainDemoViewController {

    override var addressTitle: String { "Solana address" }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSection("Account")
        addAction("Get Public Address", detail: "magic_get_multichain_public_address") { [weak self] in self?.getPublicAddress() }

        addSection("Sign a message")
        addAction("Sign Message", detail: "sol_signMessage") { [weak self] in self?.signMessage() }

        addSection("Sign a transaction")
        addAction("Sign Legacy Transaction", detail: "sol_signTransaction, type: .legacy") { [weak self] in self?.signTransaction(type: .legacy, partial: false) }
        addAction("Sign v0 Transaction", detail: "sol_signTransaction, type: .v0") { [weak self] in self?.signTransaction(type: .v0, partial: false) }

        addSection("Partially sign a transaction")
        addAction("Partial Sign Legacy Transaction", detail: "sol_partialSignTransaction, type: .legacy") { [weak self] in self?.signTransaction(type: .legacy, partial: true) }
        addAction("Partial Sign v0 Transaction", detail: "sol_partialSignTransaction, type: .v0") { [weak self] in self?.signTransaction(type: .v0, partial: true) }

        addSection("Wallet")
        addAction("Reveal Private Key", detail: "magic_reveal_key") { [weak self] in self?.revealPrivateKey() }
    }

    override func loadAddress() {
        guard let solana = Magic.shared.solana else {
            didLoadAddress(nil, failure: "Solana extension is not configured.")
            return
        }
        solana.getPublicAddress { self.didLoadAddress($0.result, failure: $0.error?.localizedDescription) }
    }

    private var solana: SolanaExtension? {
        let solana = Magic.shared.solana
        if solana == nil { show("Solana extension is not configured.") }
        return solana
    }

    private func getPublicAddress() {
        solana?.getPublicAddress { self.handle($0) { $0 } }
    }

    private func signMessage() {
        solana?.signMessage("Hello from Magic") { self.handle($0) { "signature (base64):\n\($0.base64EncodedString())" } }
    }

    /// Signs a one-lamport transfer from the user to themselves, in either
    /// transaction format, with either `signTransaction` or `partialSignTransaction`.
    private func signTransaction(type: SolanaTransactionType, partial: Bool) {
        guard let solana = solana else { return }
        solana.getPublicAddress { response in
            guard let address = response.result, let transaction = self.sampleTransfer(from: address, type: type) else {
                self.show("Could not read the Solana address.")
                return
            }
            let label = type == .legacy ? "legacy" : "v0"
            let format: (SolanaSignedTransaction) -> String = {
                "\(partial ? "partly signed" : "signed") \(label) transaction (base64):\n\($0.rawTransaction.base64EncodedString())"
            }
            if partial {
                // serializeConfig only applies to legacy transactions, like in magic-js.
                let config = type == .legacy ? SolanaSerializeConfig(requireAllSignatures: false, verifySignatures: false) : nil
                solana.partialSignTransaction(transaction, type: type, serializeConfig: config) { self.handle($0, format: format) }
            } else {
                solana.signTransaction(transaction, type: type) { self.handle($0, format: format) }
            }
        }
    }

    private func revealPrivateKey() {
        solana?.revealPrivateKey { self.handle($0) { "revealed: \($0)" } }
    }

    // MARK: - Sample transaction

    /// `.legacy` is a `Transaction`. `.v0` is a `VersionedTransaction`.
    private func sampleTransfer(from address: String, type: SolanaTransactionType) -> Data? {
        switch type {
        case .legacy: return SolanaSampleTransactions.legacyTransfer(from: address)
        case .v0: return SolanaSampleTransactions.v0Transfer(from: address)
        }
    }
}
