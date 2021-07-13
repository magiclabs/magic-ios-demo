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

class LoginViewController: UIViewController {

    static let storyboardIdentifier = "LoginVC"

    let magic = Magic.shared
    var isLoggedIn: Bool?
    
    weak var delegate: LoginViewControllerDelegate?
    @IBOutlet weak var emailInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func navigateToMain () {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: MainTabBarController.storyboardIdentifier)
        
        // This is to get the SceneDelegate object from your view controller
        // then call the change root view controller function to change to main tab bar
        (UIApplication.shared.delegate as? AppDelegate)?.changeRootViewController(mainTabBarController)
    }

    
    // MARK: - Sign in
    func handleSignIn() {
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
    
//    // MARK: - Sign in with PromiEvents
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
    
    @IBAction func signIn() {
        handleSignIn()
    }
    
    @IBAction func googleLogin() {
        handleSocialLogin(provider: OAuthProvider.GOOGLE)
    }
    
    @IBAction func appleLogin() {
        handleSocialLogin(provider: OAuthProvider.APPLE)
    }
    
    @IBAction func facebookLogin() {
        handleSocialLogin(provider: OAuthProvider.FACEBOOK)
    }
    
    @IBAction func linkedinLogin() {
        handleSocialLogin(provider: OAuthProvider.LINKEDIN)
    }
    
    @IBAction func githubLogin() {
        handleSocialLogin(provider: OAuthProvider.GITHUB)
    }
    
    @IBAction func gitlabLogin() {
        handleSocialLogin(provider: OAuthProvider.GITLAB)
    }
    
    @IBAction func bitbucketLogin() {
        handleSocialLogin(provider: OAuthProvider.BITBUCKET)
    }
    
    @IBAction func twitterLogin() {
        handleSocialLogin(provider: OAuthProvider.TWITTER)
    }
    
    @IBAction func discordLogin() {
        handleSocialLogin(provider: OAuthProvider.DISCORD)
    }
}
