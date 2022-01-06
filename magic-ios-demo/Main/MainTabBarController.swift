//
//  TabBarController.swift
//  MagicSDK_Example
//
//  Created by Jerry Liu on 5/24/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

protocol TabBarControllerDelegate: AnyObject {
    func navigateToTabBar(_ viewController: MainTabBarController)
}

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    static let storyboardIdentifier = "mainTabBar"

    override func viewDidLoad() {

        super.viewDidLoad()
        delegate = self
    }
}
