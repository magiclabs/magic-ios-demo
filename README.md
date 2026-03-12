Magic IOS Demo App
---
This demo project provides you with the simplest usage of Magic IOS SDK including Web3 functionalities

Features
---
**Email OTP Login**: Authenticate a user passwordlessly using a one-time code sent to the specified user's email address.

**SMS Login**:Authenticate a user passwordlessly using a one-time code sent to the specified phone number.

**OAuth Login**:Authenticate a user via oauth providers

**Eth SendTransaction**:
We support blockchain interactions on iOS just like how you do it in the browser. 

**Contract**:
We support contract to allow you to deploy contracts, call deployed contract functions or read contract storages.

## Examples

[Swift Package Manager](https://github.com/magiclabs/magic-ios-demo/tree/master/SwiftPackageManager) — This example demonstrates how to build a simple web3 / Ethereum app using Magic with **Swift Package Manager**.

## Cocoapods deprecation

The Cocoapods example has been removed. We recommend using **Swift Package Manager (SPM)** because:

- **Native support** — SPM is built into Xcode and supported by Apple as the default dependency manager for Swift.
- **Simpler workflow** — No extra tools (`pod install`, Podfile, workspace) or Ruby/Bundler setup.
- **Ecosystem alignment** — Most Swift libraries publish SPM-first; Cocoapods is no longer the primary distribution path for many projects.
- **Maintenance** — We are focusing support and documentation on SPM to keep the demo and SDK integration straightforward.

Use the [Swift Package Manager example](https://github.com/magiclabs/magic-ios-demo/tree/master/SwiftPackageManager) for the current recommended integration.
