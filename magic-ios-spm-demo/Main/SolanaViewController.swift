//
//  SolanaViewController.swift
//
//  Demo of the Solana extension (`SolanaConfiguration` in AppDelegate).

import UIKit
import MagicSDK
import MagicSDK_Web3

class SolanaViewController: ChainDemoViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarItem = UITabBarItem(title: "Solana", image: UIImage(systemName: "s.circle"), selectedImage: UIImage(systemName: "s.circle.fill"))

        addButton("Get Public Address") { [weak self] in self?.getPublicAddress() }
        addButton("Sign Message") { [weak self] in self?.signMessage() }
        addButton("Sign Transaction (sample transfer)") { [weak self] in self?.signTransaction() }
        addButton("Reveal Private Key") { [weak self] in self?.revealPrivateKey() }
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

    /// Signs a one-lamport transfer from the user to themselves. The blockhash is a
    /// placeholder, so the result is signed but cannot be broadcast.
    private func signTransaction() {
        guard let solana = solana else { return }
        solana.getPublicAddress { response in
            guard let address = response.result, let transaction = self.sampleTransfer(from: address) else {
                self.show("Could not read the Solana address.")
                return
            }
            solana.signTransaction(transaction, type: .legacy) {
                self.handle($0) { "signed transaction (base64):\n\($0.rawTransaction.base64EncodedString())" }
            }
        }
    }

    private func revealPrivateKey() {
        solana?.revealPrivateKey { self.handle($0) { "revealed: \($0)" } }
    }

    // MARK: - Sample transaction

    /// Serialized legacy transaction with one empty signature slot, like
    /// `Transaction.serialize({ requireAllSignatures: false })` in @solana/web3.js.
    private func sampleTransfer(from address: String) -> Data? {
        guard let account = Base58.decode(address), account.count == 32 else { return nil }
        let systemProgram = Data(count: 32)
        let blockhash = Data(count: 32)

        var instruction = Data()
        instruction.append(contentsOf: withUnsafeBytes(of: UInt32(2).littleEndian, Array.init)) // System transfer
        instruction.append(contentsOf: withUnsafeBytes(of: UInt64(1).littleEndian, Array.init)) // 1 lamport

        var message = Data([1, 0, 1])               // 1 signer, 0 readonly signed, 1 readonly unsigned
        message.append(2)                           // account count
        message.append(account)
        message.append(systemProgram)
        message.append(blockhash)
        message.append(1)                           // instruction count
        message.append(1)                           // program index: system program
        message.append(contentsOf: [2, 0, 0])       // account indexes: from, to (the same account)
        message.append(UInt8(instruction.count))
        message.append(instruction)

        return Data([1]) + Data(count: 64) + message
    }
}

/// Minimal Base58 decoder, enough to read a Solana public key.
private enum Base58 {
    private static let alphabet = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)

    static func decode(_ string: String) -> Data? {
        var bytes = [UInt8]() // little-endian
        for character in string.utf8 {
            guard var carry = alphabet.firstIndex(of: character) else { return nil }
            for index in bytes.indices {
                carry += Int(bytes[index]) * 58
                bytes[index] = UInt8(carry & 0xff)
                carry >>= 8
            }
            while carry > 0 {
                bytes.append(UInt8(carry & 0xff))
                carry >>= 8
            }
        }
        let leadingZeros = string.utf8.prefix { $0 == alphabet[0] }.count
        return Data(repeating: 0, count: leadingZeros) + Data(bytes.reversed())
    }
}
