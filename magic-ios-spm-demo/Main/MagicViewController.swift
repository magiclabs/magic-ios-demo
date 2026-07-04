//
//  LoggedInViewController.swift
//
//  Created by Jerry Liu on 1/20/20.
//  Copyright © 2020 Magic Labs. All rights reserved.

import UIKit
import MagicSDK_Web3
import MagicSDK

protocol MagicViewControllerDelegate: AnyObject {}

class MagicViewController: UIViewController {
    
    static let storyboardIdentifier = "Magic"
    
    enum Error: Swift.Error {
        case noAccountsFound
    }
    
    @IBOutlet weak var emailLabel: UILabel!
    
    weak var delegate: MagicViewControllerDelegate?
    
    let magic = Magic.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailLabel.text = UserDefaults.standard.string(forKey: "Email")
        styleButtons(in: view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
    }
    
    func navigateToLogin () {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: LoginViewController.storyboardIdentifier)
        
        // This is to get the SceneDelegate object from your view controller
        // then call the change root view controller function to change to main tab bar
        (UIApplication.shared.delegate as? AppDelegate)?.changeRootViewController(loginVC)
    }
    
    private func styleButtons(in rootView: UIView) {
        for subview in rootView.subviews {
            if let button = subview as? UIButton {
                var config = UIButton.Configuration.filled()
                config.baseBackgroundColor = .black
                config.baseForegroundColor = .white
                config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
                config.cornerStyle = .medium
                button.configuration = config
            } else {
                styleButtons(in: subview)
            }
        }
    }

    // MARK: - Phantom functions
    
    @IBAction func getIdToken() {
        guard let magic = magic else { return }
        
        magic.user.getIdToken().done({ response in
            self.showResult(response)
        }).catch({ error in
            self.showResult(error.localizedDescription)
        })
    }
    
    @IBAction func getInfo() {
        guard let magic = magic else { return }
            
        magic.user.getInfo().done({ result in
            self.showResult(result.description)
        }).catch({ error in
            self.showResult(error.localizedDescription)
        })
    }
    
    @IBAction func updateEmail() {
        
        guard let magic = magic else { return }
        let configuration = UpdateEmailConfiguration(email: "hiro@magic.link")
        
        magic.user.updateEmail(configuration, eventLog: true)
            .on(eventName: UserModule.UpdateEmailEvent.emailNotDeliverable.rawValue) {
            print("Email not deliverable")
        }.on(eventName: UserModule.UpdateEmailEvent.emailSent.rawValue) {
            print("Email sent!")
        }.done({ result in
                self.showResult(result.description)
            }).catch({ error in
                print(error)
            })
    }

    
    // MARK: - Magic Auth Methods
    @IBAction func logOut() {
        guard let magic = magic else { return }
        magic.user.logout(response: { response in
            if response.status.isSuccess {
                UserDefaults.standard.removeObject(forKey: "Email")
                UserDefaults.standard.removeObject(forKey: "Token")
                self.showResult(response.result?.description ?? "")
                self.navigateToLogin()
            }
        })
    }
    
    @IBAction func generateIdToken() {
        guard let magic = magic else { return }
        magic.user.generateIdToken(response: { response in
            self.showResult(response.result ?? "")
        })
    }
    
    @IBAction func updateSms() {
        guard let magic = magic else { return }
        magic.user.updatePhoneNumber(response: { response in
            self.showResult(response.result ?? "")
        })
    }
    
    @IBAction func showSettings() {
        guard let magic = magic else { return }
        magic.user.showSettings().done({ result in
            self.showResult(result.email ?? "")
        }).catch({ error in
            self.showResult(error.localizedDescription)
        })
    }
    @IBAction func isLoggedIn() {
        guard let magic = magic else { return }
        magic.user.isLoggedIn(response: { response in
            self.showResult(response.result?.description ?? "")
        })
    }

    // MARK: - MFA

    private var mfaHandle: MagicEventPromise<Bool>?
    private var mfaRetries = 2
    private var recoveryRetries = 2

    @IBAction func enableMFA() {
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
                        self?.showResult("Too many invalid attempts — MFA setup cancelled.")
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
                    self?.showResult("MFA enabled! Save your recovery code:\n\n\(codes)")
                }
            }

        mfaHandle?
            .onError { [weak self] error in
                DispatchQueue.main.async { self?.showResult(error.localizedDescription) }
            }
            .done { [weak self] _ in
                DispatchQueue.main.async { self?.showResult("MFA enabled successfully.") }
            }
            .catch { _ in }
    }

    @IBAction func disableMFA() {
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
                        self?.showResult("Too many invalid recovery code attempts — cancelled.")
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
                DispatchQueue.main.async { self?.showResult(error.localizedDescription) }
            }
            .done { [weak self] _ in
                DispatchQueue.main.async { self?.showResult("MFA disabled successfully.") }
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
