import Foundation
import UIKit
import WebKit

/**
 Questions & Ideas
 
 - as an user I want to give my credentials only once
 - as an user I want to call simply startChat
 - why color is mandatory? it's better to have minimal effort to make SKD ready
 - webview could be private and not given users to access it in the closures
 - what error cases could we have? (for QosFail and/or connection )
 - it's better to put talkativeHelper to TalkativeVC so user can manage from there
    |-> why do we need online checker at the end users intend is opening a chat right
 so if there's any error it's one of the error if it's ready we can make it
 optional to start the call
 
 -- Meeting Notes to questions
 - companyId queueId region is mandatory
 - user should be able to informed about call started async

 */

struct TalkativeConfiguration {
    var companyId: String
    var queueId: String
    var region: String
    var color: String
    var type: CommunicationType
    var interactionData: Array<InteractionDataEntry>
    var signedInteractionData: String
}

extension TalkativeConfiguration {
    static func defaultConfig(companyId: String, queueId: String, region: String) -> TalkativeConfiguration {
        return TalkativeConfiguration(companyId: companyId,
                                      queueId: queueId,
                                      region: region,
                                      color: "255,0,0",
                                      type: .chat,
                                      interactionData: [InteractionDataEntry(label: "Name", data: "John", type: "string")],
                                      signedInteractionData: ""
        )
    }
}

enum QosFail: Error {
    case slowInternet
    case noActiveUser
    case general(String)
}

protocol TalkativeServerDelegate: AnyObject {
    func onReady()
    func onInteractionStart()
    func onQosFail(reason: QosFail) // could be good to sent error enum and/or code
    func onInteractionFinished()
}

enum CommunicationType: String {
    case chat = "chat"
    case video = "video"
}

final class TalkativeViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    
    private let domain: String! = "https://talkative-cdn.com/mobile-embed/0.0.5/index.html"
    private var webview: WKWebView?
    weak var delegate: TalkativeServerDelegate?
    var config: TalkativeConfiguration
    
    init(with config: TalkativeConfiguration) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = [];
        self.extendedLayoutIncludesOpaqueBars = true;
        let preferences = WKPreferences()
        let userController: WKUserContentController = WKUserContentController()
        userController.add(self, name: "engage");
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.preferences = preferences
        webConfiguration.userContentController = userController;

        // This is an addition to fix video on iPhone
        webConfiguration.allowsInlineMediaPlayback = true

        webview = WKWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), configuration: webConfiguration)
        webview!.uiDelegate = self
        webview!.navigationDelegate = self
        
        self.view.addSubview(self.webview!)
        // align webview and self.view to top
        let centerX = NSLayoutConstraint(item: webview!,
                                         attribute: .centerX,
                                         relatedBy: .equal,
                                         toItem: self.view,
                                         attribute: .centerX,
                                         multiplier: 1.0,
                                         constant: 0.0)
        let centerY = NSLayoutConstraint(item: webview!,
                                         attribute: .centerY,
                                         relatedBy: .equal,
                                         toItem: self.view,
                                         attribute: .centerY,
                                         multiplier: 1.0,
                                         constant: 0.0)
        let height = NSLayoutConstraint(item: webview!,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: self.view,
                                         attribute: .height,
                                         multiplier: 1.0,
                                         constant: 0.0)
        let width = NSLayoutConstraint(item: webview!,
                                         attribute: .width,
                                         relatedBy: .equal,
                                         toItem: self.view,
                                         attribute: .width,
                                         multiplier: 1.0,
                                         constant: 0.0)

        
        self.view.addConstraints([centerX, centerY, height, width])
        
        // This will be changed in future
        webview?.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"
        webview?.load(self.prepareChatRequest())
    }
    
    func prepareChatRequest() -> URLRequest {
        var urlString: String = ""
        urlString += domain
        urlString += "?company-uuid="
        urlString += config.companyId
        urlString += "&queue-uuid="
        urlString += config.queueId
        urlString += "&region="
        urlString += config.region
        urlString += "&primary-color="
        urlString += config.color
        urlString += "&%3Aapi-features=%5B%27chat%27%2C+%27video%27%5D"
        
        let link = URL(string: urlString)!
        var request = URLRequest(url: link)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : Any] else {
            return
        }
        
        if (dict["ready"] != nil) {
            if (dict["qos"] != nil) {
                let qosStringData = (dict["qos"] as! String);
                let jsonData = qosStringData.data(using: .utf8)!
                let qos = try! JSONDecoder().decode(Qos.self, from: jsonData)
                
                if (config.type.rawValue == "chat" && qos.chat == false || config.type.rawValue == "video" && qos.video == false) {
//                    onQosFail(self.webview)
                    delegate?.onQosFail(reason: .slowInternet)
                } else {
                    let jsonEncoder = JSONEncoder()
                    let jsonData = try! jsonEncoder.encode(config.interactionData)
                    let str = String(data: jsonData, encoding: .utf8)!;
                    var code = ""
                    if (config.type.rawValue == "video") {
                        code = "TalkativeEngageApi.startVideo({interactionData: " + str + ", signedInteractionData: '" + config.signedInteractionData + "'})"
                    } else {
                        code = "TalkativeEngageApi.startChat({interactionData: " + str + ", signedInteractionData: '" + config.signedInteractionData + "'})"
                    }
//                    onReady(self.webview)
                    delegate?.onReady()
                    self.webview!.evaluateJavaScript(code)
                }
            }
        }
        
        if (dict["started"] != nil) {
//            onInteractionStart(self.webview)
            delegate?.onInteractionStart()
        }
        
        //This code triggers when the user is done with the chat (after feedback)
        if (dict["final"] != nil) {
            dismiss()
        }
    }
    
    private func dismiss() {
        self.navigationController!.popViewController(animated: true)
//        onInteractionFinished(self.webview)
        delegate?.onInteractionFinished()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))

        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let urlString = url.absoluteString.lowercased()
        if urlString.starts(with: domain) || urlString.starts(with: "https://talkative-cdn") {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:])
        }
    }
}

struct MessageBody: Codable {
    let ready, final: Bool?
    let qos: String?
}

struct Qos: Codable {
    let video, chat: Bool
}
