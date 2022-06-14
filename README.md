# Talkative

[![Version](https://img.shields.io/cocoapods/v/Talkative.svg?style=flat)](https://cocoapods.org/pods/Talkative)
[![Platform](https://img.shields.io/cocoapods/p/Talkative.svg?style=flat)](https://cocoapods.org/pods/Talkative)

* [General info](#general-info)
* [Installation](#Installation)
* [Usage](#Usage)

## General info
Talkative iOS client implementation.
    
## Installation
### Install with CocoaPods
Add Talkative by following entry to your Podfile.

```rb
pod 'Talkative'
```

Then run `pod install`.

In any file you'd like to use Talkative in, don't forget to import the framework with `import Talkative`.

### Set your config
Set your config like below, before starting the interaction with the service.
```swift
TalkativeManager.shared.config = TalkativeConfig.defaultConfig(widgetUuid: "Your Widget UUID", region: "Region")
```

Possible regions include "eu", "au", "us".

## Usage
After installation, using Talkative is very simple.

For video to work you will need to add the below to your info.plist file 

`Privacy - Microphone Usage Description` which is a string for the description of the microphone permission prompt.

`Privacy - Camera Usage Description` which is a string for the description of the camera permission prompt.

These functions will return a view controller instance for you to handle with your existing navigation code as you would like. This function doesn't do an online check.

The below code will launch your widget in standby mode with all configured cards visible.
```swift
    TalkativeManager.shared.startInteraction() 
```

Optionally you can pass through a programmatic actionable, which will directly execute that actionable.

```swift
    TalkativeManager.shared.startInteraction(actionable: "Actionable String") 
```

Checking online status, you will need to know the uuid of the queue for this check.
```swift
    TalkativeManager.shared.onlineCheck(queueUuid: "Your Queue UUID") { status in
        var statusInfo = ""
        switch status {
        case .online:
            statusInfo = "Currently Online"
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
            print("interaction started")
        }
        
        func onInteractionFinished() {
            print("interaction finished")
        }
        
        func onQosFail() {
            print("Qos fail")
        }
    
        func onPresenceFail() {
            print("Presence fail")
        }
        
        func onCustomEvent(eventName: String) {
            print("Custom event: " + eventName)
        }

        func onBeforeReady(qos: Qos) -> Bool {
            // This must return true for interactions to start
            return true
        }
    }
```

You can check the example app for more detail.
