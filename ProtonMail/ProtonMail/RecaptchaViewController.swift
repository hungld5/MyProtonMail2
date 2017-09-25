//
//  SignUpUserNameViewController.swift
//
//
//  Created by Yanfeng Zhang on 12/17/15.
//
//

import UIKit

class RecaptchaViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority = UILayoutPriority(rawValue: 750.0);
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    fileprivate let kSegueToNotificationEmail = "sign_up_pwd_email_segue"
    fileprivate var startVerify : Bool = false
    fileprivate var checkUserStatus : Bool = false
    fileprivate var stopLoading : Bool = false
    fileprivate var doneClicked : Bool = false
    var viewModel : SignupViewModel!
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topLeftButton.setTitle(NSLocalizedString("Back", comment: "top left back button"), for: .normal)
        topTitleLabel.text = NSLocalizedString("Human Verification", comment: "view top title")
        continueButton.setTitle(NSLocalizedString("Continue", comment: "Action"), for: .normal)
        
        resetChecking()
        webView.scrollView.isScrollEnabled = false
        
        URLCache.shared.removeAllCachedResponses();
        MBProgressHUD.showAdded(to: webView, animated: true)
        //let recptcha = NSURL(string: "https://secure.protonmail.com/mobile.html")!
        
        let recptcha = URL(string: "https://secure.protonmail.com/captcha/captcha.html?token=signup&client=ios&host=\(AppConstants.URL_HOST)")!
        let requestObj = URLRequest(url: recptcha)
        webView.loadRequest(requestObj)
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToNotificationEmail {
            let viewController = segue.destination as! SignUpEmailViewController
            viewController.viewModel = self.viewModel
        }
    }

    @IBAction func backAction(_ sender: UIButton) {
        stopLoading = true
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func startChecking() {
        
    }
    
    func resetChecking() {
        checkUserStatus = false
    }
    
    func finishChecking(_ isOk : Bool) {
        if isOk {
            checkUserStatus = true
        } else {

        }
    }
    
    @IBAction func createAccountAction(_ sender: UIButton) {
        if viewModel.isTokenOk() {
            self.finishChecking(true)
            if doneClicked {
                return
            }
            doneClicked = true;
            MBProgressHUD.showAdded(to: view, animated: true)
            DispatchQueue.main.async(execute: { () -> Void in
                self.viewModel.createNewUser { (isOK, createDone, message, error) -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.doneClicked = false
                        if !message.isEmpty {
                            let title =  NSLocalizedString("Create user failed", comment: "Title")
                            var message = NSLocalizedString("Default error, please try again.", comment: "Error")
                            if let error = error {
                                message = error.localizedDescription
                            }
                            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            alert.addOKAction()
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            if isOK || createDone {
                                self.goNotificationEmail()
                            }
                        }
                    })
                }
            })
        } else {
            self.finishChecking(false)
            let alert = NSLocalizedString("The verification failed!", comment: "Error").alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func goNotificationEmail() {
        self.performSegue(withIdentifier: self.kSegueToNotificationEmail, sender: self)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        PMLog.D("\(request)")
        let urlString = request.url?.absoluteString;
        //TODO::Fix later
//        if urlString?.contains("https://www.google.com/recaptcha/api2/frame") == true {
//            startVerify = true;
//        }
//        
//        if urlString?.contains(".com/fc/api/nojs") == true {
//            startVerify = true;
//        }
//        if urlString?.contains("fc/apps/canvas") == true {
//            startVerify = true;
//        }
//        
//        if urlString?.contains("about:blank") == true {
//            startVerify = true;
//        }
//        
//        if urlString?.contains("https://www.google.com/intl/en/policies/privacy") == true {
//            return false
//        }
//
//        if urlString?.contains("how-to-solve-") == true {
//            return false
//        }
//        if urlString?.contains("https://www.google.com/intl/en/policies/terms") == true {
//            return false
//        }

        if let _ = urlString?.range(of: "https://secure.protonmail.com/expired_recaptcha_response://") {
            viewModel.setRecaptchaToken("", isExpired: true)
            resetWebviewHeight()
            webView.reload()
            return false
        }
        else if let _ = urlString?.range(of: "https://secure.protonmail.com/captcha/recaptcha_response://") {
            if let token = urlString?.replacingOccurrences(of: "https://secure.protonmail.com/captcha/recaptcha_response://", with: "", options: NSString.CompareOptions.widthInsensitive, range: nil) {
                viewModel.setRecaptchaToken(token, isExpired: false)
            }
            resetWebviewHeight()
            return false
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if startVerify {
            if let _ = webView.stringByEvaluatingJavaScript(from: "document.body.scrollHeight;") {
                let height = CGFloat(500)
                webViewHeightConstraint.constant = height;
            }
            startVerify = false
        }
        MBProgressHUD.hide(for: self.webView, animated: true)
    }
    
    func resetWebviewHeight() {
        if let _ = webView.stringByEvaluatingJavaScript(from: "document.body.scrollHeight;") {
            let height = CGFloat(85)
            webViewHeightConstraint.constant = height;
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        PMLog.D("")
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        PMLog.D("")
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {

    }
}
