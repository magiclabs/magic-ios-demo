Magic IOS Demo App
---

This is a demo app to demonstrate the usage of Magic IOS SDK including Web3 functionalities

Get Started
---

1. Install the app
```bash
$ git clone https://github.com/magiclabs/magic-ios-demo.git
$ cd /YOUR/PATH/TO/magic-ios-demo/
$ pod install
```

2. Replace the `YOUR_PUBLISHABLE_KEY` in the AppDelegate.swift

```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // MARK: - Magic Instantiation
        Magic.shared = Magic(apiKey: "YOUR_PUBLISHABLE_KEY")
```

3. Start the app in the XCode

SDK
---
| Package  |  Repo | Status  | 
|---|---|---|
| MagicSDK | [Repo](https://github.com/magiclabs/magic-ios-pod)  |  [![Version](https://img.shields.io/cocoapods/v/MagicSDK.svg?style=flat)](https://cocoapods.org/pods/MagicSDK) | 
| MagicExt-OAuth  | [Repo](https://github.com/magiclabs/magic-extension-ios-pod) | [![Version](https://img.shields.io/cocoapods/v/MagicExt-OAuth.svg?style=flat)](https://cocoapods.org/pods/MagicExt-OAuth)  |

If you find any issues regarding the SDKs, please file them in the repos above



