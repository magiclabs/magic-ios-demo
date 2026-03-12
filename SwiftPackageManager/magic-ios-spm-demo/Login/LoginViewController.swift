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
        
        configureTextFields()
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
        
        smsLoginButton.isEnabled = false
        smsActivityIndicator.startAnimating()

        let config = LoginWithSmsConfiguration(phoneNumber: self.phoneInput.text!)

        magic.auth.loginWithSMS(config, response: { res in
            DispatchQueue.main.async {
                self.smsActivityIndicator.stopAnimating()
                self.smsLoginButton.isEnabled = true
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
        
        emailLoginButton.isEnabled = false
        emailActivityIndicator.startAnimating()
        
        magic.auth.loginWithEmailOTP(config, response: { res in
            DispatchQueue.main.async {
                self.emailActivityIndicator.stopAnimating()
                self.emailLoginButton.isEnabled = true
            }
            
            if res.status.isSuccess {
                print(res.result ?? "nil")
                self.navigateToMain()
            }
        })
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

    @IBAction func recoverAccount() {
        handleRecoverAccount()
    }
    @IBAction func SocialLogin() {

          handleSocialLogin(provider: OAuthProvider.allCases[selectedRow])
     }
    
    private func configureTextFields() {
        emailInput.placeholder = "Email"
        phoneInput.placeholder = "Phone number"
        recoveryEmailInput.placeholder = "Recovery email"
        
        emailInput.keyboardType = .emailAddress
        recoveryEmailInput.keyboardType = .emailAddress
        phoneInput.keyboardType = .phonePad
    }
    
    private func styleButtons(in rootView: UIView) {
        for subview in rootView.subviews {
            if let button = subview as? UIButton {
                button.backgroundColor = .black
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 6
                button.clipsToBounds = true
                button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
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
