//
//  LoggedOutViewController.swift
//  Magic
//
//  Created by Jerry Liu on 1/20/20.
//  Copyright © 2020 Magic Labs. All rights reserved.

import UIKit
import MagicSDK
import MagicExt_OAuth
import MagicExt_OIDC
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

    @IBOutlet var providerPicker: UITextField!

    @IBOutlet var jwt: UITextField!
    @IBOutlet var providerId: UITextField!

     // picker
    let pickerData: [String] = OAuthProvider.allCases.map { $0.rawValue }
     var selectedRow: Int = 0


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

        // email Input
        self.emailInput.isHidden = true

        guard let magic = magic else { return }
        // Checked if user is LoggedIn


        magic.user.isLoggedIn() { flag in

            // if it's logged in auto move to next page
            if flag.result ?? false {
                self.navigateToMain()
            } else {
                self.emailInput.isHidden = false
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


    // MARK: - Email Login
    func handleEmailLogin() {
        guard let magic = magic else { return }

        let configuration = LoginWithMagicLinkConfiguration(email: self.emailInput.text!)
            firstly {
                magic.auth.loginWithMagicLink(configuration)
            }.done { token -> Void in

                let defaults = UserDefaults.standard
                defaults.set(token, forKey: "Token")
                defaults.set(self.emailInput.text, forKey: "Email")

                self.navigateToMain()
                print(token)

            }.catch { error in
                print("Error", error)
            }
    }

//    // MARK: - Email Login with PromiEvents
//    func handleSignIn() {
//        guard let magic = magic else { return }
//
//        let configuration = LoginWithMagicLinkConfiguration(email: self.emailInput.text!)
//        magic.auth.loginWithMagicLink(configuration, eventLog: true).once(eventName: AuthModule.LoginWithMagicLinkEvent.emailSent.rawValue){
//            print("email-sent")
//        }.done { token -> Void in
//
//                            let defaults = UserDefaults.standard
//                            defaults.set(token, forKey: "Token")
//                            defaults.set(self.emailInput.text, forKey: "Email")
//
//                            self.navigateToMain()
//                            print(token)
//
//                        }.catch { error in
//                            print("Error", error)
//                        }
//    }
//
    // MARK: - Social Login
    func handleSocialLogin(provider: OAuthProvider) {

        guard let magic = magic else { return }

        let config = OAuthConfiguration(provider: provider, redirectURI: "magicdemo://")

        magic.oauth.loginWithPopup(config, response: {res in

            if (res.status.isSuccess) {
                let defaults = UserDefaults.standard
                defaults.set(res.result?.magic.idToken, forKey: "Token")
                defaults.set(res.result?.magic.userMetadata.email, forKey: "Email")
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

        let config = LoginWithSmsConfiguration(phoneNumber: self.phoneInput.text!)

        magic.auth.loginWithSMS(config, response: {res in

            if (res.status.isSuccess) {
                print(res.result ?? "nil")
                self.navigateToMain()
            }

        })
    }

    // MARK: - EmailOTP Login
    func handleEmailOTPLogin() {
        guard let magic = magic else { return }
        let config = LoginWithEmailOTPConfiguration(email: self.emailInput.text!)

        magic.auth.loginWithEmailOTP(config, response: {res in

            if (res.status.isSuccess) {
                print(res.result ?? "nil")
                self.navigateToMain()
            }

        })
    }

    // MARK: - OpenId Login
    func handleOpenIdLogin() {
        guard let magic = magic else { return }

        let config = OpenIdConfiguration(jwt: self.jwt.text!, providerId: self.providerId.text!)

        magic.openid.loginWithOIDC(config, response: {res in

            if (res.status.isSuccess) {
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
    
    // MARK: - Magic Connect Login
    func handleMCLogin() {
        guard let magic = magic else { return }
        
        magic.wallet.connectWithUI(response: { res in
            if (res.status.isSuccess) {
                print(res.result ?? "nil")
                
                let defaults = UserDefaults.standard
                if let publicAddress = res.result?.first {
                    defaults.set(publicAddress, forKey: "publicAddress")
                    self.navigateToMain()
                }
            }
        })
    }
    
    @IBAction func magicConnectLogin() {
        handleMCLogin()
    }
    @IBAction func emailLogin() {
        handleEmailLogin()
    }

    @IBAction func SMSLogin() {
        handleSMSLogin()
    }

    @IBAction func emailOTPLogin() {
        handleEmailOTPLogin()
    }

    @IBAction func openIdLogin() {
        handleOpenIdLogin()
    }

    @IBAction func recoverAccount() {
        handleRecoverAccount()
    }
    @IBAction func SocialLogin() {

          handleSocialLogin(provider: OAuthProvider.allCases[selectedRow])
     }
}
