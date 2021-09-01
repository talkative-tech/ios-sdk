import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var webviewController: TalkativeViewController?
    let companyUuid: String = "bfc1d038-680e-45e0-ab57-79373c852560"
    let queueUuid: String = "b0a99b74-f914-4154-88d8-d8ac5aa16d4b"

    //This is the action linked to the Start Video button
    @IBAction func startVideo(_ sender: Any) {
        // You can get these from Engage, they identify the company
        let region: String = "eu"
        //This is an RGB value for the primary color
        let color: String = "255,0,0"
        
        //This is where you define interaction data
        let interactionData = [
            InteractionDataEntry(label: "Name", data: "John", type: "string")
        ]
        
        // put your signed interaction data in here
        // https://support.talkative.uk/technical/signed-interaction-data
        // (this is optional, set to empty string if not needed)
        let signedInteractionData = ""

        // This code loads the interaction immediately if one exists, or does an online check and then loads a new interaction if online
        if (self.webviewController != nil) {
            self.loadWebview(companyUuid: self.companyUuid, queueUuid: self.queueUuid, region: region, color: color, type: "video", interactionData: interactionData, signedInteractionData: signedInteractionData);
        } else {
            TalkativeHelper.onlineCheck(companyUuid: self.companyUuid, queueUuid: self.queueUuid, region: region) { (response: OnlineResponse?, error: Error?) in
                if (response != nil && response!.status == "online" && response!.features.video == true) {
                    //This starts the interaction if the queue is online
                    self.loadWebview(companyUuid: self.companyUuid, queueUuid: self.queueUuid, region: region, color: color, type: "video", interactionData: interactionData, signedInteractionData: signedInteractionData);
                } else {
                    //This is where you add code to handle agents being offline
                    
                    //As an example show an alert that the queue is offline.
                    DispatchQueue.main.async(execute: {
                        let alertController = UIAlertController(title: nil, message: "Offline", preferredStyle: .alert)

                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in

                        }))

                        self.present(alertController, animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    //This is the action linked to the Start Chat button
    @IBAction func startChat(_ sender: Any) {
        // You can get these from Engage, they identify the company
        let region: String = "eu"
        //This is an RGB value for the primary color
        let color: String = "255,0,0"
        
        //This is where you define unsigned interaction data
        let interactionData = [
            InteractionDataEntry(label: "Name", data: "John", type: "string")
        ]
        
        // put your signed interaction data in here
        // https://support.talkative.uk/technical/signed-interaction-data
        // (this is optional, set to empty string if not needed)
        let signedInteractionData = ""

        // This code loads the interaction immediately if one exists, or does an online check and then loads a new interaction if online
        if (webviewController != nil) {
            loadWebview(companyUuid: self.companyUuid, queueUuid: self.queueUuid, region: region, color: color, interactionData: interactionData, signedInteractionData: signedInteractionData);
        } else {
            TalkativeHelper.onlineCheck(companyUuid: self.companyUuid, queueUuid: self.queueUuid, region: region) { (response: OnlineResponse?, error: Error?) in
                if (response != nil && response!.status == "online" && response!.features.chat == true) {
                    //This starts the interaction if the queue is online
                    self.loadWebview(companyUuid: self.companyUuid, queueUuid: self.queueUuid, region: region, color: color, interactionData: interactionData, signedInteractionData: signedInteractionData);
                } else {
                    //This is where you add code to handle agents being offline
                    
                    //As an example show an alert that the queue is offline.
                    DispatchQueue.main.async(execute: {
                        let alertController = UIAlertController(title: nil, message: "Offline", preferredStyle: .alert)

                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in

                        }))

                        self.present(alertController, animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    //This is the code to load the Talkative Webview screen
    func loadWebview(companyUuid: String, queueUuid: String, region: String, color: String, type: String = "chat", interactionData: Array<InteractionDataEntry>, signedInteractionData: String) {
        DispatchQueue.main.async(execute: {
            // This keeps the WebView alive if the user navigates away mid interaction.
            if (self.webviewController == nil) {
//                let storyboard = UIStoryboard(name: "WebView", bundle: nil)
                self.webviewController = TalkativeViewController()
//                self.webviewController = storyboard.instantiateViewController(withIdentifier: "TalkativeViewController") as? TalkativeViewController
//                self.webviewController!.companyUuid = companyUuid
//                self.webviewController!.queueUuid = queueUuid
//                self.webviewController!.region = region
//                self.webviewController!.color = color
//                self.webviewController!.type = type
//                self.webviewController!.interactionData = interactionData
//                self.webviewController!.signedInteractionData = signedInteractionData
//                self.webviewController!.onQosFail = { (webview) in
//                    let alertController = UIAlertController(title: nil, message: "Your internet is too slow for this feature.", preferredStyle: .alert)
//                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
//                        self.navigationController!.popViewController(animated: true)
//                        self.webviewController = nil
//                    }))
//
//                    self.present(alertController, animated: true, completion: nil)
//                }
//                self.webviewController!.onInteractionFinished = { (webview) in
//                    self.webviewController = nil
//                }
            }

            self.navigationController!.pushViewController(self.webviewController!, animated: true)
        })
    }
}

