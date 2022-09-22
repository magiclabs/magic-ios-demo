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
    
    @IBOutlet weak var mcStack: UIStackView!
    @IBOutlet weak var maStack: UIStackView!
    
    weak var delegate: MagicViewControllerDelegate?
    
    let magic = Magic.shared
    
    let magicConnect = MagicConnect.shared
    
    override func viewDidLoad() {
        
        emailLabel.text = UserDefaults.standard.string(forKey: "Email")
        
        if (isMC) {
            maStack.isHidden = true
            mcStack.isHidden = false
        } else {
            mcStack.isHidden = true
            maStack.isHidden = false
        }
        
        super.viewDidLoad()
    }
    
    var isMC: Bool {
        if magic != nil {
            return false
        }
        if magicConnect != nil {
            return true
        }
        return true
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
    
    @IBAction func getMetaData() {
        guard let magic = magic else { return }
            
        magic.user.getMetadata().done({ result in
            self.showResult(result.email ?? "")
            })
    }
    
    @IBAction func updateEmail() {
        
        guard let magic = magic else { return }
        let configuration = UpdateEmailConfiguration(email: "jerry@magic.link")
        
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
    
    @IBAction func logOut() {
        guard let magic = magic else { return }
        magic.user.logout(response: { response in
            UserDefaults.standard.removeObject(forKey: "Email")
            UserDefaults.standard.removeObject(forKey: "Token")
            self.showResult(response.result?.description ?? "")
            self.navigateToLogin()
        })
    }
    
    @IBAction func generateIdToken() {
        guard let magic = magic else { return }
        magic.user.generateIdToken(response: { response in
            self.showResult(response.result ?? "")
        })
    }
    
    @IBAction func isLoggedIn() {
        guard let magic = magic else { return }
        magic.user.isLoggedIn(response: { response in
            self.showResult(response.result?.description ?? "")
        })
    }
    
    @IBAction func showWallet() {
        guard let magic = magicConnect else { return }
        magic.connect.showWallet(response: { response in
            self.showResult(response.result?.description ?? "")
        })
    }
    
    @IBAction func requestUserInfo() {
        guard let magic = magicConnect else { return }
        magic.connect.requestUserInfo(response: { response in
            self.showResult(response.result?.description ?? "")
        })
    }
    
    @IBAction func disconnect() {
        guard let magic = magicConnect else { return }
        magic.connect.disconnect(response: { response in
            self.showResult(response.result?.description ?? "")
        })
    }
}
