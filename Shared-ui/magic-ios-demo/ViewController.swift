//
//  ViewController.swift
//  Magic
//
//

import UIKit
import MagicSDK
import AuthenticationServices

class ViewController: UIViewController, UITabBarControllerDelegate {

}

extension UIViewController {
     func showResult(_ message:String) -> Void {
        return showToast(title: "Result", message: message)
    }
    
    func showError(message:String) -> Void {
        return showToast(title: "Error", message: message)
    }
    
    private func showToast(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert, animated: true)
        let deadlineTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            alert.dismiss(animated: true, completion: nil)
        })
    }
}
