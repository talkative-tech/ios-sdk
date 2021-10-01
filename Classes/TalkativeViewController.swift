import Foundation
import UIKit
import WebKit

/// Informs about status of the current ongoing interaction
public protocol TalkativeServerDelegate: AnyObject {
    /// Ready to start webview and interaction
    func onReady()
    /// Handshaked with service interaction started
    func onInteractionStart()
    /// Queue Availibility problem
    /// - Parameter reason: The error case like slow connection or noUser
    func onQosFail(reason: QosFail)
    /// Interaction finished will soon dismiss the view so you can release VC if you are using!
    func onInteractionFinished()
}

/// Responsible for holding webview for the interaction process and informing the delegate about changes
public final class TalkativeViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupLayout()
        
        webview?.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 14_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"
        webview?.load(self.prepareChatRequest())
    }
    
    private func setupViews() {
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
    
    private func setupLayout() {
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
    
    private func prepareChatRequest() -> URLRequest {
        var urlString: String = ""
        urlString += talkativeServerDomain
        urlString += "?company-uuid="
        urlString += config.companyId
        urlString += "&queue-uuid="
        urlString += config.queueId
        urlString += "&region="
        urlString += config.region
        urlString += "&primary-color="
        urlString += config.color
        urlString += "&%3Aapi-features=%5B%27chat%27%2C+%27video%27%5D"
        urlString += "&" + config.extraUrlParams
        
        return URLRequest(url: URL(string: urlString)!)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : Any] else {
            return
        }
        
        if (dict["ready"] != nil) {
            if (dict["qos"] != nil) {
                let qosStringData = (dict["qos"] as! String);
                let jsonData = qosStringData.data(using: .utf8)!
                let qos = try! JSONDecoder().decode(Qos.self, from: jsonData)
                
                if (config.type.rawValue == "chat" && qos.chat == false || config.type.rawValue == "video" && qos.video == false) {
                    delegate?.onQosFail(reason: .general(qosStringData.debugDescription))
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
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))

        present(alertController, animated: true, completion: nil)
    }

    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
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

    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
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
        if urlString.starts(with: talkativeServerDomain) || urlString.starts(with: "https://talkative-cdn") {
            decisionHandler(.allow)
            self.loadingIndicator.stopAnimating()
        } else {
            decisionHandler(.cancel)
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @available(iOS 15.0, *)
    public func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {

        decisionHandler(.grant)
    }
}

