//
//  AppDelegate.swift
//  Magic
//
//  Created by Jerry Liu on 01/16/2020.
//  Copyright (c) 2020 Magic Labs. All rights reserved.
//

import UIKit
import MagicSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: - Magic Instantiation
        Magic.shared = Magic(apiKey: "YOUR_PUBLISHABLE_KEY")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // MARK: - User Session Check
        // if user is logged in before
        if UserDefaults.standard.string(forKey: "Email") != nil || UserDefaults.standard.string(forKey: "publicAddress") != nil {
              // instantiate the main tab bar controller and set it as root view controller
              // using the storyboard identifier we set earlier
            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: MainTabBarController.storyboardIdentifier)
              window?.rootViewController = mainTabBarController
          } else {
              // if user isn't logged in
              // instantiate the navigation controller and set it as root view controller
              // using the storyboard identifier we set earlier
            let loginNavController = storyboard.instantiateViewController(withIdentifier: LoginViewController.storyboardIdentifier)
              window?.rootViewController = loginNavController
          }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else {
            return
        }
        
        // change the root view controller to your specific view controller
        window.rootViewController = vc
    }
}

