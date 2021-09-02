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
 
 ----------
 - whats the purpose of signedInteractionData and interaction data entry
 - does service version number changes sometimes?
 - add loading hud?
 - transition directly opening the chat
 - add app bouncing chat button like in web?
 -
 */

protocol TalkativeServerDelegate: AnyObject {
    func onReady()
    func onInteractionStart()
    func onQosFail(reason: QosFail) // improve errors
    func onInteractionFinished() // clean vc from memory
}

// Default method filling for making them optional
extension TalkativeServerDelegate {
    func onReady() {}
    func onInteractionStart() {}
    func onQosFail(reason: QosFail) {}
}

final class TalkativeViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    
    private let domain: String! = "https://talkative-cdn.com/mobile-embed/0.0.5/index.html"
    private var webview: WKWebView?
    private var isLoading = true
    private var loadingIndicator = UIActivityIndicatorView(style: .large)
    weak var delegate: TalkativeServerDelegate?
    var config: TalkativeConfig
    
    init(with config: TalkativeConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupLayout()
        
        webview?.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"
        webview?.load(self.prepareChatRequest())
    }
    
    func setupViews() {
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

        webview = WKWebView(frame: CGRect.zero, configuration: webConfiguration)
        webview!.uiDelegate = self
        webview!.navigationDelegate = self
        
        self.view.addSubview(self.webview!)
        
        loadingIndicator.color = .gray
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.isUserInteractionEnabled = false
        
        self.view.addSubview(self.webview!)
        self.view.addSubview(loadingIndicator)

    }
    
    func setupLayout() {
        webview?.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // align webview and self.view edges
        let webViewCons = [
            webview!.topAnchor.constraint(equalTo: self.view.topAnchor),
            webview!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            webview!.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            webview!.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ]
        
        // align indicator and self.view edges
        let indicatorCons = [
            loadingIndicator.topAnchor.constraint(equalTo: self.view.topAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            loadingIndicator.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            loadingIndicator.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ]
        
        self.view.addConstraints(webViewCons)
        self.view.addConstraints(indicatorCons)
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
        
        return URLRequest(url: URL(string: urlString)!)
    }
    
    deinit {
        print("it's released")
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
                    delegate?.onReady()
                    self.webview!.evaluateJavaScript(code)
                }
            }
        }
        
        if (dict["started"] != nil) {
            delegate?.onInteractionStart()
            self.loadingIndicator.stopAnimating()
        }
        
        //This code triggers when the user is done with the chat (after feedback)
        if (dict["final"] != nil) {
            dismiss()
        }
    }
    
    private func dismiss() {
        self.delegate?.onInteractionFinished()
        self.dismiss(animated: true)
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

