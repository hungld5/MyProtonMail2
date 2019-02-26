//
//  ChangePasswordViewController.swift
//  ProtonMail - Created on 3/17/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import MBProgressHUD

class ChangePasswordViewController: UIViewController {
    
    @IBOutlet weak var currentPwdEditor: UITextField!
    @IBOutlet weak var newPwdEditor: UITextField!
    @IBOutlet weak var confirmPwdEditor: UITextField!
    
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!
    @IBOutlet weak var labelThree: UILabel!
    
    @IBOutlet weak var topOffset: NSLayoutConstraint!
    
    var keyboardHeight : CGFloat = 0.0
    var textFieldPoint : CGFloat = 0.0
    
    let kAsk2FASegue = "password_to_twofa_code_segue"
    
    fileprivate var doneButton: UIBarButtonItem!
    fileprivate var viewModel : ChangePWDViewModel!
    func setViewModel(_ vm:ChangePWDViewModel) -> Void {
        self.viewModel = vm
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton = self.editButtonItem
        doneButton.target = self
        doneButton.action = #selector(ChangePasswordViewController.doneAction(_:))
        doneButton.title = LocalString._general_save_action

        self.navigationItem.title = viewModel.getNavigationTitle()
        self.titleLable.text = viewModel.getSectionTitle()
        self.labelOne.text = viewModel.getLabelOne()
        self.labelTwo.text = viewModel.getLabelTwo()
        self.labelThree.text = viewModel.getLabelThree()
        
        currentPwdEditor.placeholder = LocalString._settings_current_password
        newPwdEditor.placeholder = LocalString._settings_new_password
        confirmPwdEditor.placeholder = LocalString._settings_confirm_new_password
        
        focusFirstEmpty()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: privat methods
    fileprivate func dismissKeyboard() {
        if (self.currentPwdEditor != nil) {
            self.currentPwdEditor.resignFirstResponder()
        }
        if (self.newPwdEditor != nil) {
            self.newPwdEditor.resignFirstResponder()
        }
        if (self.confirmPwdEditor != nil) {
            self.confirmPwdEditor.resignFirstResponder()
        }
    }
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    func updateView() {
        let screenHeight = view.frame.height
        let offbox = screenHeight - textFieldPoint
        if offbox > keyboardHeight {
            topOffset.constant = 8
        } else {
            topOffset.constant = offbox - keyboardHeight
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kAsk2FASegue {
            let popup = segue.destination as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .twoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    internal func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }


    
    @IBAction func StartEditing(_ sender: UITextField) {
        let frame = sender.convert(sender.frame, to: self.view)
        textFieldPoint = frame.origin.y + frame.height + 40
        updateView()
    }
    
    fileprivate func isInputEmpty() -> Bool {
        let cPwd = (currentPwdEditor.text ?? "") //.trim()
        let nPwd = (newPwdEditor.text ?? "") //.trim()
        let cnPwd = (confirmPwdEditor.text ?? "") //.trim()
        if !cPwd.isEmpty {
            return false
        }
        if !nPwd.isEmpty {
            return false
        }
        if !cnPwd.isEmpty {
            return false
        }
        return true
    }
    
    fileprivate func focusFirstEmpty() -> Void {
        let cPwd = (currentPwdEditor.text ?? "") //.trim()
        let nPwd = (newPwdEditor.text ?? "") //.trim()
        let cnPwd = (confirmPwdEditor.text ?? "") //.trim()
        if cPwd.isEmpty {
            currentPwdEditor.becomeFirstResponder()
        }
        else if nPwd.isEmpty {
            newPwdEditor.becomeFirstResponder()
        }
        else if cnPwd.isEmpty {
            confirmPwdEditor.becomeFirstResponder()
        }
    }
    
    var cached2faCode : String?
    fileprivate func startUpdatePwd () -> Void {
        dismissKeyboard()
        if viewModel.needAsk2FA() && cached2faCode == nil {
            NotificationCenter.default.removeKeyboardObserver(self)
            self.performSegue(withIdentifier: self.kAsk2FASegue, sender: self)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            viewModel.setNewPassword(currentPwdEditor.text!, new_pwd: newPwdEditor.text!, confirm_new_pwd: confirmPwdEditor.text!, tfaCode: self.cached2faCode, complete: { value, error in
                self.cached2faCode = nil
                MBProgressHUD.hide(for: self.view, animated: true)
                if let error = error {
                    if error.code == APIErrorCode.UserErrorCode.currentWrong {
                        self.currentPwdEditor.becomeFirstResponder()
                    }
                    else if error.code == APIErrorCode.UserErrorCode.newNotMatch {
                        self.newPwdEditor.becomeFirstResponder()
                    }
                    
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    let _ = self.navigationController?.popToRootViewController(animated: true)
                }
            })
        }
    }

    // MARK: - Actions
    @IBAction func doneAction(_ sender: AnyObject) {
        startUpdatePwd()
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ChangePasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        keyboardHeight = 0
        updateView()
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            updateView()
        }
    }
}

extension ChangePasswordViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(_ code: String, pwd : String) {
        NotificationCenter.default.addKeyboardObserver(self)
        self.cached2faCode = code
        self.startUpdatePwd()
    }
    
    func Cancel2FA() {
        NotificationCenter.default.addKeyboardObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if isInputEmpty() {
            self.navigationItem.rightBarButtonItem = nil
        }
        else {
            self.navigationItem.rightBarButtonItem = doneButton
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField
        {
        case currentPwdEditor:
            newPwdEditor.becomeFirstResponder()
            break
        case newPwdEditor:
            confirmPwdEditor.becomeFirstResponder()
            break
        default:
            if !isInputEmpty() {
                startUpdatePwd()
            }
            else {
                focusFirstEmpty()
            }
            break
        }
        return true
    }
}
