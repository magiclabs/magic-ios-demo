//
//  SolanaSampleTransactions.swift
//
//  Builds the sample transactions the Solana demo tab signs. The SDK takes
//  serialized bytes, so a real app would get these from a Solana library, for
//  example `Transaction.serialize({ requireAllSignatures: false })` or
//  `VersionedTransaction.serialize()` in @solana/web3.js.

import Foundation

enum SolanaSampleTransactions {

    /// A legacy transaction: one empty signature slot, then the message.
    /// Pass it to the SDK with `type: .legacy`.
    static func legacyTransfer(from address: String) -> Data? {
        guard let body = transferMessageBody(from: address) else { return nil }
        return emptySignature + body
    }

    /// A version 0 transaction: one empty signature slot, then a message that
    /// starts with the `0x80` version prefix and ends with an empty list of
    /// address table lookups. Pass it to the SDK with `type: .v0`.
    static func v0Transfer(from address: String) -> Data? {
        guard let body = transferMessageBody(from: address) else { return nil }
        return emptySignature + Data([0x80]) + body + Data([0])
    }

    /// One signature slot (compact-u16 count of 1, then 64 zero bytes).
    private static let emptySignature = Data([1]) + Data(count: 64)

    /// The message fields shared by both formats, after any version prefix and
    /// before any address table lookups. It is a one-lamport transfer from the
    /// user to themselves. The blockhash is a placeholder, so the result is
    /// signed but cannot be broadcast.
    private static func transferMessageBody(from address: String) -> Data? {
        guard let account = Base58.decode(address), account.count == 32 else { return nil }
        let systemProgram = Data(count: 32)
        let blockhash = Data(count: 32)

        var instruction = Data()
        instruction.append(contentsOf: withUnsafeBytes(of: UInt32(2).littleEndian, Array.init)) // System transfer
        instruction.append(contentsOf: withUnsafeBytes(of: UInt64(1).littleEndian, Array.init)) // 1 lamport

        var body = Data([1, 0, 1])              // 1 signer, 0 readonly signed, 1 readonly unsigned
        body.append(2)                          // account count
        body.append(account)
        body.append(systemProgram)
        body.append(blockhash)
        body.append(1)                          // instruction count
        body.append(1)                          // program index: system program
        body.append(contentsOf: [2, 0, 0])      // account indexes: from, to (the same account)
        body.append(UInt8(instruction.count))
        body.append(instruction)
        return body
    }
}

/// Minimal Base58 decoder, enough to read a Solana public key.
enum Base58 {
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
