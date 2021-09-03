## Talkative iOS SDK
* [General info](#general-info)
* [Installation](#Installation)
* [Usage](#Usage)
* [Contact](#contact)

## General info
Talkative ios client implementation.
	
## Implementation
### Install with CocoaPods
Add TalkativeSDK by following entry to your Podfile.

```rb
pod 'TalkativeSDK', '~> 14.0'
```

Then run `pod install`.

In any file you'd like to use Talkative in, don't forget to
import the framework with `import TalkativeSDK`.

### 1 - Setting your credentials
Set your credetials like below preferably in the ```AppDelegate.swift``` before starting the interaction with the service.
```swift
TalkativeManager.shared.config = TalkativeConfig.defaultConfig(companyId: "Your Company ID",
                                                                queueId: "Preferred queue ID",
                                                                region: "Region")
```
### 2 - Start interaction by using manager with type
```swift
TalkativeManager.shared.startInteractionWithCheck(type: .video)
```

## 
### 1 - Setting your credentials
 Set your credetials like below preferably in the ```AppDelegate.swift``` before starting the interaction with the service.
```swift
TalkativeManager.shared.config = TalkativeConfig.defaultConfig(companyId: "Your Company ID",
                                                                queueId: "Preferred queue ID",
                                                                region: "Region")
```
### 2 - Start interaction by using manager with type
```swift
TalkativeManager.shared.startInteractionWithCheck(type: .video)
```

## Usage
After installation, using talkative is very simple and you can access to all the states with methods below.

Checking online status
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
Starting interaction if the system is online
```swift
    TalkativeManager.shared.startInteractionWithCheck(type: .chat)
```

Starting interaction immediately without check
```swift
    TalkativeManager.shared.startInteractionImmediately(type: .chat) 
```

If you want to be notified about states before starting the interaction set your delegated class which conform to ```TalkativeServerDelegate``` protocol
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

You can check example app for more detail.
## Contact
TBD