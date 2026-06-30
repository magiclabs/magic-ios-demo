//
//  LoggedOutViewController.swift
//  Magic
//
//  Created by Jerry Liu on 1/20/20.
//  Copyright © 2020 Magic Labs. All rights reserved.

import UIKit
import MagicSDK
import MagicExt_OAuth
import PromiseKit
import MagicSDK_Web3

protocol LoginViewControllerDelegate: AnyObject {}

class LoginViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {



    static let storyboardIdentifier = "LoginVC"

    let magic = Magic.shared
    var isLoggedIn: Bool?

    weak var delegate: LoginViewControllerDelegate?

    // outlets
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var recoveryEmailInput: UITextField!
    @IBOutlet weak var phoneInput: UITextField!
    @IBOutlet weak var emailLoginButton: UIButton!
    @IBOutlet weak var smsLoginButton: UIButton!
    @IBOutlet var providerPicker: UITextField!


     // picker
    let pickerData: [String] = OAuthProvider.allCases.map { $0.rawValue }
     var selectedRow: Int = 0
    
    private var emailActivityIndicator: UIActivityIndicatorView!
    private var smsActivityIndicator: UIActivityIndicatorView!


    override func viewDidLoad() {
        super.viewDidLoad()

        //Picker
        let picker: UIPickerView
         picker = UIPickerView(frame: CGRect(x: 0, y: 200, width: view.frame.width, height: 300))
        picker.delegate = self
        picker.dataSource = self

         let toolBar = UIToolbar()
         toolBar.barStyle = UIBarStyle.default
         toolBar.isTranslucent = true
         toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
         toolBar.sizeToFit()

         let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(self.donePicker))
         let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
         let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.donePicker))

         toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
         toolBar.isUserInteractionEnabled = true
         picker.selectRow(0, inComponent: 0, animated: false)

        providerPicker.inputView = picker
        providerPicker.inputAccessoryView = toolBar
        
        styleButtons(in: view)
        setupActivityIndicators()

        guard let magic = magic else { return }
        // Checked if user is LoggedIn


        magic.user.isLoggedIn() { flag in
            // if it's logged in auto move to next page
            if flag.result ?? false {
                self.navigateToMain()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }

     // handles selection result
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
         providerPicker.text = "\(pickerData[row]) 🔽"
         selectedRow = row
    }

     @objc func donePicker() {

         providerPicker.resignFirstResponder()
     }


    // MARK: - Navigation
    func navigateToMain () {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: MainTabBarController.storyboardIdentifier)

        // This is to get the SceneDelegate object from your view controller
        // then call the change root view controller function to change to main tab bar
        (UIApplication.shared.delegate as? AppDelegate)?.changeRootViewController(mainTabBarController)
    }

    // MARK: - Social Login
    func handleSocialLogin(provider: OAuthProvider) {

        guard let magic = magic else { return }

        let config = OAuthConfiguration(provider: provider, redirectURI: "magicdemo://")

        magic.oauth.loginWithPopup(config, response: {res in

            if (res.status.isSuccess) {
                let defaults = UserDefaults.standard
                defaults.set(res.result?.magic.idToken, forKey: "Token")
                defaults.set(res.result?.oauth.userInfo.email, forKey: "Email")
                self.navigateToMain()
            } else {
                switch res.magicExtOAuthError {
                case .userDeniedAccess(let error):
                        print(error)
                    print("userDenied")
                    break
                case .parseSuccessURLError(url: let url):
                       print(url)
                    print("url")
                    break
                case .unsupportedVersions:
                    print("unsupported")
                    break
                case .none:
                    break
                @unknown default:
                    print("unexpected")
                }
            }

        })
    }

    // MARK: - SMS Login
    func handleSMSLogin() {
        guard let magic = magic else { return }
        
        smsActivityIndicator.startAnimating()

        let config = LoginWithSmsConfiguration(phoneNumber: self.phoneInput.text!)

        magic.auth.loginWithSMS(config, response: { res in
            DispatchQueue.main.async {
                self.smsActivityIndicator.stopAnimating()
            }
            
            if res.status.isSuccess {
                print(res.result ?? "nil")
                self.navigateToMain()
            }
        })
    }

    // MARK: - EmailOTP Login
    func handleEmailOTPLogin() {
        guard let magic = magic else { return }
        let config = LoginWithEmailOTPConfiguration(email: self.emailInput.text!)

        emailActivityIndicator.startAnimating()

        magic.auth.loginWithEmailOTP(config, response: { res in
            DispatchQueue.main.async {
                self.emailActivityIndicator.stopAnimating()
            }

            if res.status.isSuccess {
                print(res.result ?? "nil")
                self.navigateToMain()
            }
        })
    }

    // MARK: - EmailOTP Login (headless / showUI: false)
    private var emailOTPHandle: MagicEventPromise<String>?
    private var otpRetries = 2
    private var mfaRetries = 2
    private var recoveryRetries = 2
    private var headlessStatusLabel: UILabel?

    private func updateStatus(_ message: String) {
        if headlessStatusLabel == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            ])
            headlessStatusLabel = label
        }
        headlessStatusLabel?.text = message
    }

    private func clearStatus() {
        headlessStatusLabel?.removeFromSuperview()
        headlessStatusLabel = nil
    }

    func handleEmailOTPLoginHeadless() {
        guard let magic = magic else {
            showResult("Magic SDK not initialized")
            return
        }
        guard let email = emailInput.text, !email.isEmpty else {
            showResult("Please enter an email address")
            return
        }
        let config = LoginWithEmailOTPConfiguration(email: email, showUI: false)

        emailActivityIndicator.startAnimating()
        updateStatus("Sending OTP to \(email)…")
        otpRetries = 2; mfaRetries = 2; recoveryRetries = 2

        typealias E = AuthModule.LoginWithEmailOTPEvent

        emailOTPHandle = magic.auth.loginWithEmailOTP(config, eventLog: true)

            // — Email OTP —
            .on(eventName: E.emailOTPSent.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("OTP sent — check your email.")
                    self?.promptForCode(title: "Enter OTP", message: "Check your email for a one-time passcode.") { otp in
                        self?.updateStatus("Verifying OTP…")
                        self?.emailOTPHandle?.emit(eventType: E.verifyEmailOTP.rawValue, arg: otp)
                    }
                }
            }
            .onPersistent(eventName: E.invalidEmailOTP.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    if self?.otpRetries ?? 0 <= 0 {
                        self?.updateStatus("Too many invalid attempts — cancelling.")
                        self?.emailOTPHandle?.emit(eventType: E.cancel.rawValue)
                    } else {
                        self?.otpRetries -= 1
                        self?.updateStatus("Invalid OTP — try again (\(self?.otpRetries ?? 0) retries left).")
                        self?.promptForCode(title: "Invalid OTP", message: "Retries left: \(self?.otpRetries ?? 0)") { otp in
                            self?.updateStatus("Verifying OTP…")
                            self?.emailOTPHandle?.emit(eventType: E.verifyEmailOTP.rawValue, arg: otp)
                        }
                    }
                }
            }
            .on(eventName: E.expiredEmailOTP.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("OTP expired.")
                    self?.showResult("OTP expired — please restart login.")
                }
            }
            .on(eventName: E.loginThrottled.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("Login throttled — please wait.")
                    self?.showResult("Too many attempts — please wait before retrying.")
                }
            }
            .on(eventName: E.maxAttemptsReached.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("Max attempts reached.")
                    self?.showResult("Max OTP attempts reached.")
                }
            }

            // — MFA —
            .on(eventName: E.mfaSentHandle.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("MFA required — enter your authenticator code.")
                    self?.promptForCode(title: "Enter MFA Code", message: "Enter your authenticator code.") { code in
                        self?.updateStatus("Verifying MFA…")
                        self?.emailOTPHandle?.emit(eventType: E.verifyMFACode.rawValue, arg: code)
                    }
                }
            }
            .onPersistent(eventName: E.invalidMfaOTP.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    if self?.mfaRetries ?? 0 <= 0 {
                        self?.updateStatus("Too many invalid MFA attempts — switching to recovery.")
                        self?.emailOTPHandle?.emit(eventType: E.lostDevice.rawValue)
                    } else {
                        self?.mfaRetries -= 1
                        self?.updateStatus("Invalid MFA code — try again (\(self?.mfaRetries ?? 0) retries left).")
                        self?.promptForCode(title: "Invalid MFA Code", message: "Retries left: \(self?.mfaRetries ?? 0)") { code in
                            self?.updateStatus("Verifying MFA…")
                            self?.emailOTPHandle?.emit(eventType: E.verifyMFACode.rawValue, arg: code)
                        }
                    }
                }
            }
            .on(eventName: E.recoveryCodeSentHandle.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("Enter your MFA recovery code.")
                    self?.promptForCode(title: "MFA Recovery", message: "Enter your recovery code.") { code in
                        self?.updateStatus("Verifying recovery code…")
                        self?.emailOTPHandle?.emit(eventType: E.verifyRecoveryCode.rawValue, arg: code)
                    }
                }
            }
            .onPersistent(eventName: E.invalidRecoveryCode.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    if self?.recoveryRetries ?? 0 <= 0 {
                        self?.updateStatus("Too many invalid recovery attempts — cancelling.")
                        self?.emailOTPHandle?.emit(eventType: E.cancel.rawValue)
                    } else {
                        self?.recoveryRetries -= 1
                        self?.updateStatus("Invalid recovery code — try again (\(self?.recoveryRetries ?? 0) retries left).")
                        self?.promptForCode(title: "Invalid Recovery Code", message: "Retries left: \(self?.recoveryRetries ?? 0)") { code in
                            self?.updateStatus("Verifying recovery code…")
                            self?.emailOTPHandle?.emit(eventType: E.verifyRecoveryCode.rawValue, arg: code)
                        }
                    }
                }
            }

            // — Device verification —
            .on(eventName: E.deviceNeedsApproval.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("New device detected — check your inbox to approve.")
                    self?.showBanner("Device Needs Approval — check your inbox.")
                }
            }
            .on(eventName: E.deviceVerificationEmailSent.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("Device verification email sent — waiting for approval…")
                    self?.showBanner("Device verification email sent.")
                }
            }
            .on(eventName: E.deviceApproved.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("Device approved! Continuing login…")
                    self?.showBanner("Device approved!")
                }
            }
            .on(eventName: E.deviceVerificationLinkExpired.rawValue) { [weak self] in
                DispatchQueue.main.async {
                    self?.updateStatus("Device verification link expired — retrying…")
                    self?.showResult("Device verification link expired.")
                    self?.emailOTPHandle?.emit(eventType: E.deviceRetry.rawValue)
                }
            }

        emailOTPHandle?
            .onError { [weak self] error in
                DispatchQueue.main.async {
                    self?.emailActivityIndicator.stopAnimating()
                    self?.clearStatus()
                    self?.showResult(error.localizedDescription)
                }
            }
            .done { [weak self] _ in
                DispatchQueue.main.async {
                    self?.emailActivityIndicator.stopAnimating()
                    self?.clearStatus()
                    self?.navigateToMain()
                }
            }
            .catch { _ in }
    }

    private func promptForCode(title: String, message: String, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "6-digit code"
            field.keyboardType = .numberPad
            field.textContentType = .oneTimeCode
        }
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            guard let code = alert.textFields?.first?.text, !code.isEmpty else { return }
            completion(code)
        }
        alert.addAction(submitAction)
        alert.preferredAction = submitAction
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.emailOTPHandle?.emit(eventType: AuthModule.LoginWithEmailOTPEvent.cancel.rawValue)
            self?.emailActivityIndicator.stopAnimating()
            self?.clearStatus()
        })

        // Walk up from window root to find the topmost presented VC
        let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundInactive }) as? UIWindowScene
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

    private func showBanner(_ message: String) {
        let banner = UILabel()
        banner.text = message
        banner.textColor = .white
        banner.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        banner.textAlignment = .center
        banner.font = .systemFont(ofSize: 14, weight: .medium)
        banner.layer.cornerRadius = 10
        banner.clipsToBounds = true
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            banner.heightAnchor.constraint(equalToConstant: 44),
        ])
        UIView.animate(withDuration: 0.3, delay: 2.5, options: [], animations: {
            banner.alpha = 0
        }, completion: { _ in banner.removeFromSuperview() })
    }

    // MARK: - Recover Account
    func handleRecoverAccount() {
        guard let magic = magic else { return }

        let configuration = RecoverAccountConfiguration(email: self.recoveryEmailInput.text!)
        
        magic.user.recoverAccount(configuration, response: { res in
            if (res.status.isSuccess) {
                print(res.result ?? "nil")
                self.navigateToMain()
            } else {
                self.showResult("Email not associated with this Api Key")
            }
        })
    }

    @IBAction func SMSLogin() {
        handleSMSLogin()
    }

    @IBAction func emailOTPLogin() {
        handleEmailOTPLogin()
    }

    @IBAction func emailOTPLoginHeadless() {
        handleEmailOTPLoginHeadless()
    }

    @IBAction func recoverAccount() {
        handleRecoverAccount()
    }
    @IBAction func SocialLogin() {

          handleSocialLogin(provider: OAuthProvider.allCases[selectedRow])
     }
    
    private func styleButtons(in rootView: UIView) {
        for subview in rootView.subviews {
            if let button = subview as? UIButton {
                var config = UIButton.Configuration.filled()
                config.baseBackgroundColor = .black
                config.baseForegroundColor = .white
                config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
                config.cornerStyle = .medium
                config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                    var updated = attrs
                    updated.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
                    return updated
                }
                button.configuration = config
            } else {
                styleButtons(in: subview)
            }
        }
    }
    
    private func setupActivityIndicators() {
        emailActivityIndicator = makeActivityIndicator()
        smsActivityIndicator = makeActivityIndicator()
        
        attach(indicator: emailActivityIndicator, to: emailLoginButton)
        attach(indicator: smsActivityIndicator, to: smsLoginButton)
    }
    
    private func makeActivityIndicator() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }
    
    private func attach(indicator: UIActivityIndicatorView, to button: UIButton) {
        button.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            indicator.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8)
        ])
    }
    
}
