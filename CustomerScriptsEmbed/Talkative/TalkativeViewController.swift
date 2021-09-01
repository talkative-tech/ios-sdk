import Foundation

import UIKit
import WebKit

struct TalkativeConfiguration {
    var region: String = "eu"
    var color: String = "255,0,0"
    var type: CommunicationType = .chat
    var interactionData: Array<InteractionDataEntry> = [InteractionDataEntry(label: "Name", data: "John", type: "string")]
    var signedInteractionData: String = ""
    var onReady: ((_: WKWebView) -> Void) = { (webview) in }
    var onInteractionStart: ((_: WKWebView) -> Void) = { (webview) in }
    var onQosFail: ((_: WKWebView) -> Void) = { (webview) in }
    var onInteractionFinished: ((_: WKWebView) -> Void) = { (webview) in }
}

enum CommunicationType: String {
    case chat = "chat"
    case video = "video"
}

class TalkativeViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate {

    @IBOutlet var webview: WKWebView!
    var companyUuid: String!
    var queueUuid: String!
    var region: String!
    var color: String!
    var type: String = "chat"
    var interactionData: Array<InteractionDataEntry>!
    var signedInteractionData: String!
    var onReady: ((_: WKWebView) -> Void) = { (webview) in }
    var onInteractionStart: ((_: WKWebView) -> Void) = { (webview) in }
    var onQosFail: ((_: WKWebView) -> Void) = { (webview) in }
    var onInteractionFinished: ((_: WKWebView) -> Void) = { (webview) in }
    
    let domain: String! = "https://talkative-cdn.com/mobile-embed/0.0.5/index.html"
    
    override func loadView() {
        super.loadView()
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
        
        webview = WKWebView(frame: .zero, configuration: webConfiguration)
        webview.uiDelegate = self
        webview.navigationDelegate = self

        view = webview
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var urlString: String = ""
        urlString += domain
        urlString += "?company-uuid="
        urlString += companyUuid
        urlString += "&queue-uuid="
        urlString += queueUuid
        urlString += "&region="
        urlString += region
        urlString += "&primary-color="
        urlString += color
        urlString += "&%3Aapi-features=%5B%27chat%27%2C+%27video%27%5D"
        let link = URL(string: urlString)!
        
        let request = URLRequest(url: link)
        
        // This will be changed in future
        webview.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"
        webview.load(request)
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
                
                if (type == "chat" && qos.chat == false || type == "video" && qos.video == false) {
                    onQosFail(self.webview)
                } else {
                    let jsonEncoder = JSONEncoder()
                    let jsonData = try! jsonEncoder.encode(self.interactionData)
                    let str = String(data: jsonData, encoding: .utf8)!;
                    var code = ""
                    if (self.type == "video") {
                        code = "TalkativeEngageApi.startVideo({interactionData: " + str + ", signedInteractionData: '" + self.signedInteractionData + "'})"
                    } else {
                        code = "TalkativeEngageApi.startChat({interactionData: " + str + ", signedInteractionData: '" + self.signedInteractionData + "'})"
                    }
                    onReady(self.webview)
                    
                    self.webview.evaluateJavaScript(code)
                }
            }
        }
        
        if (dict["started"] != nil) {
            onInteractionStart(self.webview)
        }
        
        //This code triggers when the user is done with the chat (after feedback)
        if (dict["final"] != nil) {
            dismiss()
        }
    }
    
    private func dismiss() {
        self.navigationController!.popViewController(animated: true)
        onInteractionFinished(self.webview)
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
