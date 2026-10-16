//
//  LoggedInViewController.swift
//
//  Created by Jerry Liu on 1/20/20.
//  Copyright © 2020 Magic Labs. All rights reserved.

import UIKit
import MagicSDK_Web3
import MagicSDK

class MagicViewController: ChainDemoViewController {

    static let storyboardIdentifier = "Magic"

    enum Error: Swift.Error {
        case noAccountsFound
    }

    let magic = Magic.shared

    override var addressTitle: String { "Signed in as" }
    override var topInset: CGFloat { 12 }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSection("Session")
        addAction("Is Logged In", detail: "magic.user.isLoggedIn") { [weak self] in self?.isLoggedIn() }
        addAction("Get Info", detail: "magic.user.getInfo") { [weak self] in self?.getInfo() }

        addSection("Tokens")
        addAction("Get ID Token", detail: "magic.user.getIdToken") { [weak self] in self?.getIdToken() }
        addAction("Generate ID Token", detail: "magic.user.generateIdToken") { [weak self] in self?.generateIdToken() }

        addSection("Account")
        addAction("Update Email", detail: "magic.user.updateEmail") { [weak self] in self?.updateEmail() }
        addAction("Update Phone Number", detail: "magic.user.updatePhoneNumber") { [weak self] in self?.updateSms() }
        addAction("Show Settings", detail: "magic.user.showSettings") { [weak self] in self?.showSettings() }

        addSection("Multi-factor authentication")
        addAction("Enable MFA (Headless)", detail: "magic.user.enableMFA") { [weak self] in self?.enableMFA() }
        addAction("Disable MFA (Headless)", detail: "magic.user.disableMFA") { [weak self] in self?.disableMFA() }

        addSection("Sign out")
        addAction("Logout", detail: "magic.user.logout") { [weak self] in self?.logOut() }
    }

    override func loadAddress() {
        didLoadAddress(UserDefaults.standard.string(forKey: "Email"), failure: "Signed in without an email.")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshAddressIfNeeded()
    }

    func navigateToLogin () {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: LoginViewController.storyboardIdentifier)
        
        // This is to get the SceneDelegate object from your view controller
        // then call the change root view controller function to change to main tab bar
        (UIApplication.shared.delegate as? AppDelegate)?.changeRootViewController(loginVC)
    }
    
    // MARK: - Phantom functions
    
    func getIdToken() {
        guard let magic = magic else { return }
        
        magic.user.getIdToken().done({ response in
            self.show(response)
        }).catch({ error in
            self.show(error.localizedDescription)
        })
    }
    
    func getInfo() {
        guard let magic = magic else { return }
            
        magic.user.getInfo().done({ result in
            self.show(result.description)
        }).catch({ error in
            self.show(error.localizedDescription)
        })
    }
    
    func updateEmail() {
        
        guard let magic = magic else { return }
        let configuration = UpdateEmailConfiguration(email: "hiro@magic.link")
        
        magic.user.updateEmail(configuration, eventLog: true)
            .on(eventName: UserModule.UpdateEmailEvent.emailNotDeliverable.rawValue) {
            print("Email not deliverable")
        }.on(eventName: UserModule.UpdateEmailEvent.emailSent.rawValue) {
            print("Email sent!")
        }.done({ result in
                self.show(result.description)
            }).catch({ error in
                self.show(error.localizedDescription)
            })
    }

    
    // MARK: - Magic Auth Methods
    func logOut() {
        guard let magic = magic else { return }
        magic.user.logout(response: { response in
            if response.status.isSuccess {
                UserDefaults.standard.removeObject(forKey: "Email")
                UserDefaults.standard.removeObject(forKey: "Token")
                self.navigateToLogin()
            }
        })
    }
    
    func generateIdToken() {
        guard let magic = magic else { return }
        magic.user.generateIdToken(response: { response in
            self.show(response.result ?? "")
        })
    }
    
    func updateSms() {
        guard let magic = magic else { return }
        magic.user.updatePhoneNumber(response: { response in
            self.show(response.result ?? "")
        })
    }
    
    func showSettings() {
        guard let magic = magic else { return }
        magic.user.showSettings().done({ result in
            self.show(result.email ?? "")
        }).catch({ error in
            self.show(error.localizedDescription)
        })
    }
    func isLoggedIn() {
        guard let magic = magic else { return }
        magic.user.isLoggedIn(response: { response in
            self.show(response.result?.description ?? "")
        })
    }

    // MARK: - MFA

    private var mfaHandle: MagicEventPromise<Bool>?
    private var mfaRetries = 2
    private var recoveryRetries = 2

    func enableMFA() {
        guard let magic = magic else { return }
        mfaRetries = 2

        mfaHandle = magic.user.enableMFA(EnableMFAConfiguration(showUI: false), eventLog: true)

            // Relayer sends { QRCode: "data:image/png;base64,...", key: "TOTP_SECRET" }
            .on(eventName: AuthModule.EnableMFAEventOnReceived.mfaSecretGenerated.rawValue) { [weak self] params in
                DispatchQueue.main.async {
                    let key = params?["key"]?.string ?? ""
                    self?.showCopyableSecret(key) {
                        self?.promptForCode(title: "Enter Code", message: "Enter the 6-digit code from your authenticator app.", cancelEventType: AuthModule.EnableMFAEventEmit.cancel.rawValue) { totp in
                            self?.mfaHandle?.emit(eventType: AuthModule.EnableMFAEventEmit.verifyMFACode.rawValue, arg: totp)
                        }
                    }
                }
            }
            .onPersistent(eventName: AuthModule.EnableMFAEventOnReceived.invalidMFAOTP.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    if self?.mfaRetries ?? 0 <= 0 {
                        self?.mfaHandle?.emit(eventType: AuthModule.EnableMFAEventEmit.cancel.rawValue)
                        self?.show("Too many invalid attempts — MFA setup cancelled.")
                    } else {
                        self?.mfaRetries -= 1
                        self?.promptForCode(title: "Invalid Code", message: "Enter the 6-digit code from your authenticator app (\(self?.mfaRetries ?? 0) retries left).", cancelEventType: AuthModule.EnableMFAEventEmit.cancel.rawValue) { totp in
                            self?.mfaHandle?.emit(eventType: AuthModule.EnableMFAEventEmit.verifyMFACode.rawValue, arg: totp)
                        }
                    }
                }
            }
            .on(eventName: AuthModule.EnableMFAEventOnReceived.mfaRecoveryCodes.rawValue) { [weak self] params in
                DispatchQueue.main.async {
                    let codes = params?["recoveryCode"]?.string ?? ""
                    self?.show("MFA enabled! Save your recovery code:\n\n\(codes)")
                }
            }

        mfaHandle?
            .onError { [weak self] error in
                DispatchQueue.main.async { self?.show(error.localizedDescription) }
            }
            .done { [weak self] _ in
                DispatchQueue.main.async { self?.show("MFA enabled successfully.") }
            }
            .catch { _ in }
    }

    func disableMFA() {
        guard let magic = magic else { return }
        mfaRetries = 2
        recoveryRetries = 2

        mfaHandle = magic.user.disableMFA(DisableMFAConfiguration(showUI: false), eventLog: true)

            .on(eventName: AuthModule.DisableMFAEventOnReceived.mfaCodeRequested.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.promptForCode(title: "Disable MFA", message: "Enter the 6-digit code from your authenticator app.", cancelEventType: AuthModule.DisableMFAEventEmit.cancel.rawValue) { totp in
                        self?.mfaHandle?.emit(eventType: AuthModule.DisableMFAEventEmit.verifyMFACode.rawValue, arg: totp)
                    }
                }
            }
            .onPersistent(eventName: AuthModule.DisableMFAEventOnReceived.invalidMFAOTP.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    if self?.mfaRetries ?? 0 <= 0 {
                        // Out of TOTP retries — ask user to switch to recovery code
                        self?.promptForCode(title: "Lost Device?", message: "Too many invalid attempts. Enter your MFA recovery code.", cancelEventType: AuthModule.DisableMFAEventEmit.cancel.rawValue) { recoveryCode in
                            self?.mfaHandle?.emit(eventType: AuthModule.DisableMFAEventEmit.lostDevice.rawValue, arg: recoveryCode)
                        }
                    } else {
                        self?.mfaRetries -= 1
                        self?.promptForCode(title: "Invalid Code", message: "Enter the 6-digit code from your authenticator app (\(self?.mfaRetries ?? 0) retries left).", cancelEventType: AuthModule.DisableMFAEventEmit.cancel.rawValue) { totp in
                            self?.mfaHandle?.emit(eventType: AuthModule.DisableMFAEventEmit.verifyMFACode.rawValue, arg: totp)
                        }
                    }
                }
            }
            .onPersistent(eventName: AuthModule.DisableMFAEventOnReceived.invalidRecoveryCode.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    if self?.recoveryRetries ?? 0 <= 0 {
                        self?.mfaHandle?.emit(eventType: AuthModule.DisableMFAEventEmit.cancel.rawValue)
                        self?.show("Too many invalid recovery code attempts — cancelled.")
                    } else {
                        self?.recoveryRetries -= 1
                        self?.promptForCode(title: "Invalid Recovery Code", message: "Enter your recovery code (\(self?.recoveryRetries ?? 0) retries left).", cancelEventType: AuthModule.DisableMFAEventEmit.cancel.rawValue) { code in
                            self?.mfaHandle?.emit(eventType: AuthModule.DisableMFAEventEmit.lostDevice.rawValue, arg: code)
                        }
                    }
                }
            }

        mfaHandle?
            .onError { [weak self] error in
                DispatchQueue.main.async { self?.show(error.localizedDescription) }
            }
            .done { [weak self] _ in
                DispatchQueue.main.async { self?.show("MFA disabled successfully.") }
            }
            .catch { _ in }
    }

    private func showCopyableSecret(_ key: String, then continuation: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Add to Authenticator App",
            message: "Copy this key into your authenticator app (e.g. Google Authenticator), then tap Next.",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.text = key
            field.isUserInteractionEnabled = true
            field.clearButtonMode = .never
            field.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
            field.textAlignment = .center
            field.accessibilityLabel = "TOTP secret key"
        }
        alert.addAction(UIAlertAction(title: "Copy & Next", style: .default) { _ in
            UIPasteboard.general.string = key
            continuation()
        })
        alert.addAction(UIAlertAction(title: "Next", style: .default) { _ in
            continuation()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.mfaHandle?.emit(eventType: AuthModule.EnableMFAEventEmit.cancel.rawValue)
        })

        present(alert, animated: true)
    }

    private func promptForCode(title: String, message: String, cancelEventType: String, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Code"
            field.keyboardType = .numberPad
            field.textContentType = .oneTimeCode
        }
        let submit = UIAlertAction(title: "Submit", style: .default) { _ in
            guard let code = alert.textFields?.first?.text, !code.isEmpty else { return }
            completion(code)
        }
        alert.addAction(submit)
        alert.preferredAction = submit
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.mfaHandle?.emit(eventType: cancelEventType)
        })

        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        let keyWindow: UIWindow?
        if #available(iOS 16.0, *) {
            keyWindow = scene?.keyWindow ?? scene?.windows.first
        } else {
            keyWindow = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
        }
        guard var presenter = keyWindow?.rootViewController else { return }
        while let next = presenter.presentedViewController { presenter = next }
        presenter.present(alert, animated: true)
    }

}
