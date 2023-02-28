//
//  MagicConnectViewController.swift
//  magic-ios-spm-demo
//
//  Created by Arian Flores - Magic on 2/27/23.
//

import UIKit
import MagicSDK_Web3

import MagicSDK

protocol MagicConnectControllerDelegate: AnyObject {}

class MagicConnectViewController: UIViewController {
    
    static let storyboardIdentifier = "MagicConnect"
    
    weak var delegate: MagicViewControllerDelegate?
    
    let magic = Magic.shared
    

    override func viewDidLoad() {
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
    
    // MARK: - Magic Connect Methods
    @IBAction func showUI() {
        guard let magic = magic else { return }
        magic.wallet.showUI(response: { response in
                if (response.error != nil) {
                    print(response.error.debugDescription)
                }
                print(response.result?.description ?? "")
            })
    }

    @IBAction func getInfo() {
        guard let magic = magic else { return }
        magic.wallet.getInfo(response: { response in
            if (response.error != nil) {
                print(response.error.debugDescription)
            }
            self.showResult("Wallet Type: \(response.result?.walletType ?? "No Wallet Type Found")")
        })
    }


    @IBAction func requestUserInfoWithUI() {
        guard let magic = magic else { return }
        magic.wallet.requestUserInfoWithUI(response: { response in
            if (response.error != nil) {
                print(response.error.debugDescription)
            }
            self.showResult("Email: \(response.result?.email ?? "No Email Found")")
       })
    }
    
    @IBAction func disconnect() {
        guard let magic = magic else { return }
        
        magic.wallet.disconnect(response: { response in
            print(response.result?.description ?? "")
            UserDefaults.standard.removeObject(forKey: "publicAddress")
            self.navigateToLogin()
        })
    }
}

