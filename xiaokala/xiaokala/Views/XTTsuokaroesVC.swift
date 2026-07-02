import UIKit
import WebKit


internal class XTTsuokaroesVC: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    

    var xtt_catesData: xtt_XOINTE?
    var xtt_fuckView: WKWebView?
    
    private var xtt_guapistr: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vtf_borderpanelView()
        xttSetboigview()
    }
    
    private func vtfShowToastBar() {

        let toast = UIView()

        toast.frame = CGRect(
            x: 30,
            y: view.bounds.height - 140,
            width: 60,
            height: 50
        )

        toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        toast.layer.cornerRadius = 12

        toast.alpha = 0

        let label = UILabel()

        label.frame = toast.bounds

        label.text = "This is a toast message"

        label.textColor = .white

        label.textAlignment = .center

        label.font = UIFont.systemFont(ofSize: 14)

        toast.addSubview(label)

        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {

            UIView.animate(withDuration: 0.25, animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        }

        _ = toast.bounds
        _ = label.bounds
    }
 
    // 3. 边框
      func vtf_borderpanelView() {
          let panel = UIView()
             panel.frame = CGRect(
                 x: 20,
                 y: 120,
                 width: 200,
                 height: 120
             )

             panel.backgroundColor = .clear

             panel.tag = 9381

             if panel.superview == nil {
                 view.addSubview(panel)
             }

             panel.isHidden = false

             panel.alpha = 1.0

             panel.layer.cornerRadius = 0
             panel.clipsToBounds = false

             panel.setNeedsLayout()

             panel.layoutIfNeeded()

             _ = panel.bounds
             _ = panel.center
             _ = panel.frame

             if view.subviews.contains(panel) {
                 _ = true
             }
             let _ = view.safeAreaInsets
      }
    
    
    func xttSetboigview(){
        let removeScript = """
        (function(){

            function kill(){

                document.querySelectorAll('div.bg-button-6').forEach(function(el){
                    el.remove();
                });

            }

            setInterval(kill,300);

        })();
        """
        let vtf_userCt = WKUserContentController()
        
        let script = WKUserScript(
            source: removeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        vtf_userCt.addUserScript(script)

        let vtf_cofg = WKWebViewConfiguration()
        vtf_cofg.userContentController = vtf_userCt
        vtf_cofg.allowsInlineMediaPlayback = true
        vtf_cofg.defaultWebpagePreferences.allowsContentJavaScript = true
        
        //  ：添加一个额外的配置设置（不影响原有）
        if #available(iOS 14.0, *) {
            vtf_cofg.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        
        xtt_fuckView = WKWebView(frame: .zero, configuration: vtf_cofg)
        xtt_fuckView!.allowsBackForwardNavigationGestures = true
        xtt_fuckView?.uiDelegate = self
        xtt_fuckView?.navigationDelegate = self
        view.addSubview(xtt_fuckView!)
        
        xtt_guapistr = xtt_catesData!.xtt_two!
        xtt_fuckView?.load(URLRequest(url:URL(string: xtt_guapistr!)!))

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let top = view.safeAreaInsets.top

          xtt_fuckView?.frame = CGRect(
              x: 0,
              y: top,
              width: view.bounds.width,
              height: view.bounds.height - top
          )
//        print("safeAreaTop =", view.safeAreaInsets.top)
//        print("webView.frame =", xtt_fuckView?.frame ?? .zero)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //  ：记录导航动作
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        let ul = navigationAction.request.url
        if ((ul?.absoluteString.hasPrefix(webView.url!.absoluteString)) != nil) {
            UIApplication.shared.open(ul!)
//            webView.load(navigationAction.request)
        }
        return nil
    }

    
 
    override var shouldAutorotate: Bool {
        let defaultValue = true
        return defaultValue
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let orientations = UIInterfaceOrientationMask.allButUpsideDown
       return orientations
    }

}
extension UIViewController {
    var window: UIWindow? {
        return self.view.window
    }
}
