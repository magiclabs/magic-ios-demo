//
//  BitcoinViewController.swift
//
//  Demo of the Bitcoin extension (`BitcoinConfiguration` in AppDelegate).

import UIKit
import MagicSDK
import MagicExt_Bitcoin
import MagicSDK_Web3

class BitcoinViewController: ChainDemoViewController {

    override var addressTitle: String { "Bitcoin address" }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSection("Account")
        addAction("Get Public Address", detail: "magic_get_multichain_public_address") { [weak self] in self?.getPublicAddress() }

        addSection("Sign a transaction")
        addAction("Sign Transaction", detail: "btc_signTransaction, sample UTXO") { [weak self] in self?.signTransaction() }

        addSection("Wallet")
        addAction("Reveal Private Key", detail: "magic_reveal_key") { [weak self] in self?.revealPrivateKey() }
    }

    override func loadAddress() {
        guard let bitcoin = Magic.shared.bitcoin else {
            didLoadAddress(nil, failure: "Bitcoin extension is not configured.")
            return
        }
        bitcoin.getPublicAddress { self.didLoadAddress($0.result, failure: $0.error?.localizedDescription) }
    }

    private var bitcoin: BitcoinExtension? {
        let bitcoin = Magic.shared.bitcoin
        if bitcoin == nil { show("Bitcoin extension is not configured.") }
        return bitcoin
    }

    private func getPublicAddress() {
        bitcoin?.getPublicAddress { self.handle($0) { $0 } }
    }

    /// Spends a made-up UTXO back to the user's own address. The UTXO does not exist,
    /// so the result is signed but cannot be broadcast. A real app picks UTXOs from
    /// an indexer and works out the fee and change itself.
    private func signTransaction() {
        guard let bitcoin = bitcoin else { return }
        bitcoin.getPublicAddress { response in
            guard let address = response.result else {
                self.show("Could not read the Bitcoin address.")
                return
            }
            let inputs = [BitcoinTransactionInput(txid: String(repeating: "ab", count: 32), txNum: 0, value: 0.001, address: address)]
            let outputs = [BitcoinTransactionOutput(address: address, value: 0.0009)] // 0.0001 BTC fee
            bitcoin.signTransaction(inputs: inputs, outputs: outputs) {
                self.handle($0) { "txid: \($0.transactionHash)\n\nsigned transaction (hex):\n\($0.signedTransaction)" }
            }
        }
    }

    private func revealPrivateKey() {
        bitcoin?.revealPrivateKey { self.handle($0) { "revealed: \($0)" } }
    }
}
