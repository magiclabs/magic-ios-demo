# This pod file is to install local packages for MagicSDK Demo App
# and prepare building configurations for local testing and releasing

# Pod imports
def importPods
    # Do `pod install` whenever you swapped to local packages or released packages
    # Make sure to build archives based on the local packages
    # Do `pod update` whenever the version has been updated
    
    # Distributed Library on Cocoapods
    pod 'MagicSDK', '~> 2.3'
    pod 'MagicExt-OAuth', '~> 0.10'
    
  #   Local development library
#    pod 'MagicSDK', :path => '../magic-ios/MagicSDK.podspec'
#    pod 'MagicExt-OAuth', :path => '../magic-ios/MagicExt-OAuth.podspec'
    
    # Local built library
#    pod 'MagicExt-OAuth', :path => '../magic-extension-ios-pod/MagicExt-OAuth.podspec
#    pod 'MagicSDK', :path => '../magic-ios-pod/MagicSDK.podspec'

#    pod 'MagicSDK-Web3', :path => '../magic-web3-ios-pod/MagicSDK-Web3.podspec'
#    pod 'MagicSDK-Web3/ContractABI', :path => '../magic-web3-ios-pod/MagicSDK-Web3.podspec'
#    pod 'MagicSDK-Web3/PromiseKit', :path => '../magic-web3-ios-pod/MagicSDK-Web3.podspec'


end

use_frameworks!

# iOS pod setup
target 'magic-ios-demo' do
  platform :ios, '9.0'
  importPods

  target 'magic-ios-demoTests' do
    inherit! :search_paths

    pod 'Quick', '~> 3.1.2'
    pod 'Nimble', '~> 9.0.1'
  end
end

## MacOSX pod setup
#target 'Magic_osx' do
#  platform :osx, '10.10'
#  importPods
#
#end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SKIP_INSTALL'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end