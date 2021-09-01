import UIKit
import AVFoundation

class ViewController: UIViewController {
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TalkativeManager.shared.serviceDelegate = self
    }
    
    @IBAction func onlineCheck(_ sender: Any) {
        TalkativeManager.shared.onlineCheck { (response: OnlineResponse?, error: Error?) in
            if (response != nil && response!.status == "online" && response!.features.video == true) {
                //This starts the interaction if the queue is online
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
    
    //This is the action linked to the Start Video button
    @IBAction func startVideo(_ sender: Any) {
        TalkativeManager.shared.startChat(type: .video)
    }
    
    //This is the action linked to the Start Chat button
    @IBAction func startChat(_ sender: Any) {
        TalkativeManager.shared.startChat(type: .chat)
    }
    
}

extension ViewController: TalkativeServerDelegate {
    func onReady() {
        print("webview is ready")
    }
    
    func onInteractionStart() {
        print("chat can start")
    }
    
    func onInteractionFinished() {
        print("chan finished")
    }
    
    func onQosFail(reason: QosFail) {
        print("Error: \(reason.localizedDescription)")
    }
}

