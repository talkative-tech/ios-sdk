import Foundation
import UIKit
import WebKit

/// Informs about status of the current ongoing interaction
public protocol TalkativeServerDelegate: AnyObject {
    /// Ready to start webview and interaction
    func onReady()
    /// Handshaked with service interaction started
    func onInteractionStart()
    func onQosFail()
    func onPresenceFail()
    /// Interaction finished will soon dismiss the view so you can release VC if you are using!
    func onInteractionFinished()
    
    func onCustomEvent(eventName: String)
    
    func onBeforeReady(qos: Qos) -> Bool
}

/// Responsible for holding webview for the interaction process and informing the delegate about changes
public final class TalkativeViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    
    public var webview: WKWebView?
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

        webview?.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 14_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1 Mobile/15E148 Safari/604.1"
        webview?.load(self.prepareInteractionRequest())
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
    
    private func prepareInteractionRequest() -> URLRequest {
        var urlString: String = ""
        urlString += talkativeServerDomain
        urlString += "?widget-uuid="
        urlString += config.widgetUuid
        urlString += "&url="
        urlString += config.getUrlFromRegion().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        urlString += "&widget-path="
        urlString += config.widgetPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        if (config.extraUrlParams != "") {
            urlString += "&" + config.extraUrlParams
        }
        
        return URLRequest(url: URL(string: urlString)!)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : Any] else {
            return
        }
        
        let event = (dict["event"] as! String)
        
        if (dict["customEvent"] != nil) {
            self.delegate?.onCustomEvent(eventName: event)
            
            return
        }

        if (event == "enterStandby") {
            let qosStringData = (dict["qos"] as! String);
            let qosJsonData = qosStringData.data(using: .utf8)!
            let qos = try! JSONDecoder().decode(Qos.self, from: qosJsonData)
            
            let beforeReadyBool = self.delegate?.onBeforeReady(qos: qos) ?? true
            if (!beforeReadyBool) {
                return
            }
            
            let jsonEncoder = JSONEncoder()
            let jsonData = try! jsonEncoder.encode(config.interactionData)
            let interactionDataStringified = String(data: jsonData, encoding: .utf8)!;
            self.webview!.evaluateJavaScript("window.talkativeApi.interactionData.appendInteractionData(" + interactionDataStringified + ");")
            if (config.signedInteractionData == "") {
                self.webview!.evaluateJavaScript("window.talkativeApi.interactionData.setSignedInteractionData('" + config.signedInteractionData + "');")
            }
            self.delegate?.onReady()
            if (config.actionable != nil) {
                self.webview!.evaluateJavaScript("window.talkativeApi.actions.triggerAction('" + config.actionable! + "');")
            }
        }
        
        if (event == "qosFail") {
            self.delegate?.onQosFail()
        }
        
        if (event == "presenceFail") {
            self.delegate?.onPresenceFail()
        }
        
        if (event == "enterInteraction") {
            self.delegate?.onInteractionStart()
        }
        
        if (event == "completeInteraction") {
            self.delegate?.onInteractionFinished()
        }
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
    
    public func runApiFunction(code: String) {
        self.webview!.evaluateJavaScript("window.talkativeApi." + code)
    }
    
    public func endInteraction() {
        self.webview!.evaluateJavaScript("window.talkativeApi.__unsafe.endInteraction()")
    }
}

