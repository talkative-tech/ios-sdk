# Talkative

[![Version](https://img.shields.io/cocoapods/v/Talkative.svg?style=flat)](https://cocoapods.org/pods/Talkative)
[![Platform](https://img.shields.io/cocoapods/p/Talkative.svg?style=flat)](https://cocoapods.org/pods/Talkative)

* [General info](#general-info)
* [Installation](#Installation)
* [Usage](#Usage)

## General info
Talkative ios client implementation.
    
## Installation
### Install with CocoaPods
Add Talkative by following entry to your Podfile.

```rb
pod 'Talkative'
```

Then run `pod install`.

In any file you'd like to use Talkative in, don't forget to import the framework with `import Talkative`.

### Set your credentials
Set your credetials like below preferably in the ```AppDelegate.swift``` before starting the interaction with the service.
```swift
TalkativeManager.shared.config = TalkativeConfig.defaultConfig(companyId: "Your Company UUID",
                                                                queueId: "Preferred queue UUID",
                                                                region: "Region")
```

Possible regions include "eu", "au", "us".

## Usage
After installation, using talkative is very simple and you can access to all the states with methods below.

For video to work you will need to add to your info.plist file 

`Privacy - Microphone Usage Description` which is a string for the description of the microphone permission prompt.

`Privacy - Camera Usage Description` which is a string for the description of the camera permission prompt.

Starting interaction if the system is online. This will open the interaction in a modal, after doing an online check.
```swift
    TalkativeManager.shared.startInteractionWithCheck(type: .chat)
```

Starting interaction immediately without check, recommended as it gives you the most control. This will return a view controller instance for you to handle with your existing navigation code as you would like. This function also doesn't do an online check.
```swift
    TalkativeManager.shared.startInteractionImmediately(type: .chat) 
```

Checking online status manually. Useful for use with `startInteractionImmediately`.
```swift
    TalkativeManager.shared.onlineCheck { status in
        var statusInfo = ""
        switch status {
        case .chatAndVideo:
            statusInfo = "Chat and Video available"
        case .chatOnly:
            statusInfo = "Only Chat is available"
        case .videoOnly:
            statusInfo = "Only Video is available"
        case .offline:
            statusInfo = "Currently Offline"
        case .error(let err):
            statusInfo = "There's an error \(err)"
        }
    }
```


If you want to be notified about states before starting the interaction set your delegated class which conforms to the ```TalkativeServerDelegate``` protocol
```swift 
    TalkativeManager.shared.serviceDelegate = self
```
Possible conditions.
```swift
    extension ViewController: TalkativeServerDelegate {
        func onReady() {
            print("webview is ready")
        }
        
        func onInteractionStart() {
            print("chat can start")
        }
        
        func onInteractionFinished() {
            print("chat finished")
        }
        
        func onQosFail(reason: QosFail) {
            print("Error: \(reason.localizedDescription)")
        }
    }
```

You can check the example app for more detail.
