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
        
        emailLabel.text = UserDefaults.standard.string(forKey: "Email")
        super.viewDidLoad()
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
        })
    }
    
    @IBAction func updateEmail() {
        
        guard let magic = magic else { return }
        let configuration = UpdateEmailConfiguration(email: "hiro@magic.link")
        
        magic.user.updateEmail(configuration, eventLog: true)
            .once(eventName: "email-not-deliverable"){
            print("Email not deliverable")
        }.once(eventName: "email-sent"){
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
        })
    }
    @IBAction func isLoggedIn() {
        guard let magic = magic else { return }
        magic.user.isLoggedIn(response: { response in
            self.showResult(response.result?.description ?? "")
        })
    }
}
