// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import ADCountryPicker


 class KeyVerificationSelfVerifyWaitViewController: UIViewController, ADCountryPickerDelegate {
    
     func countryPicker(_ picker: ADCountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
         _ = picker.navigationController?.popToRootViewController(animated: true)
         self.dismiss(animated: true, completion: nil)
         tf_CountryCode.text = dialCode
         //countryCodeLabel.text = code
        // countryCallingCodeLabel.text = dialCode
         
        let x =  picker.getFlag(countryCode: code)
         let xx =  picker.getCountryName(countryCode: code)
         let xxx =  picker.getDialCode(countryCode: code)
     }
   

    
    
    // MARK: - Constants
    
    private enum Constants {
        static let clientNamesLineSpacing: CGFloat = 3.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
  
    private var syncTimer: Timer?
    var countryPhoneCode = ""
    
    var countryPicker: ADCountryPicker!
    
    @IBOutlet weak var countryButton: UIButton!
     
    
    @IBOutlet weak var tf_CountryCode: UITextField!
    @IBOutlet weak var tf_PhoneNumber: UITextField!
    @IBOutlet weak var lbl_ScanCode: UILabel!
    @IBOutlet weak var btnConnectWhatsApp: RoundedButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var desktopClientImageView: UIImageView!
    @IBOutlet private weak var mobileClientImageView: UIImageView!
        
    @IBOutlet private weak var recoverSecretsAvailabilityLoadingContainerView: UIView!
    @IBOutlet private weak var recoverSecretsAvailabilityLoadingLabel: UILabel!
    @IBOutlet private weak var recoverSecretsAvailabilityActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var recoverSecretsContainerView: UIView!
    @IBOutlet private weak var recoverSecretsButton: RoundedButton!
    @IBOutlet private weak var recoverSecretsAdditionalInformationLabel: UILabel!
    
    // MARK: Private

    private var viewModel: KeyVerificationSelfVerifyWaitViewModelType!
    private var cancellable: Bool!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    private weak var cancelBarButtonItem: UIBarButtonItem?
    
    let matrixManager = MatrixManager(baseUrl: "https://matrix.tag.org/_matrix/client/r0")

    
    
    

    // MARK: - Setup
    
    class func instantiate(with viewModel: KeyVerificationSelfVerifyWaitViewModelType, cancellable: Bool) -> KeyVerificationSelfVerifyWaitViewController {
        let viewController = StoryboardScene.KeyVerificationSelfVerifyWaitViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.cancellable = cancellable
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // self.setupViews()
        //   self.activityPresenter = ActivityIndicatorPresenter()
        // self.errorPresenter = MXKErrorAlertPresentation()
        
        //   self.registerThemeServiceDidChangeThemeNotification()
        //self.update(theme: self.theme)
        
        //  self.viewModel.viewDelegate = self
        //  self.viewModel.process(viewAction: .loadData)
        
        //startSync()
        
        
        
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
        self.desktopClientImageView.tintColor = theme.tintColor
        self.mobileClientImageView.tintColor = theme.tintColor
        self.recoverSecretsAvailabilityLoadingLabel.textColor = theme.textSecondaryColor
        self.recoverSecretsAvailabilityActivityIndicatorView.color = theme.tintColor
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if self.cancellable {
            let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.skip, style: .plain) { [weak self] in
                self?.cancelButtonAction()
            }

            self.vc_removeBackTitle()

            self.navigationItem.rightBarButtonItem = cancelBarButtonItem
            self.cancelBarButtonItem = cancelBarButtonItem
        }
        
        self.titleLabel.text = VectorL10n.deviceVerificationSelfVerifyOpenOnOtherDeviceTitle(AppInfo.current.displayName)
        self.informationLabel.text = VectorL10n.deviceVerificationSelfVerifyOpenOnOtherDeviceInformation
        
        self.desktopClientImageView.image = Asset.Images.monitor.image.withRenderingMode(.alwaysTemplate)
        self.mobileClientImageView.image = Asset.Images.smartphone.image.withRenderingMode(.alwaysTemplate)
                
        self.recoverSecretsAdditionalInformationLabel.text = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsAdditionalHelp(AppInfo.current.displayName)
    }

    private func render(viewState: KeyVerificationSelfVerifyWaitViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .secretsRecoveryCheckingAvailability(let text):
            self.renderSecretsRecoveryCheckingAvailability(withText: text)
        case .loaded(let viewData):
            self.renderLoaded(viewData: viewData)
        case .cancelled(let reason):
            self.renderCancelled(reason: reason)
        case .cancelledByMe(let reason):
            self.renderCancelledByMe(reason: reason)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderSecretsRecoveryCheckingAvailability(withText text: String?) {
        self.recoverSecretsAvailabilityLoadingLabel.text = text
        self.recoverSecretsAvailabilityActivityIndicatorView.startAnimating()
        self.recoverSecretsAvailabilityLoadingContainerView.isHidden = false
        self.recoverSecretsContainerView.isHidden = true
    }
    
    private func renderLoaded(viewData: KeyVerificationSelfVerifyWaitViewData) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.cancelBarButtonItem?.title = viewData.isNewSignIn ? VectorL10n.skip : VectorL10n.cancel
   
        let hideRecoverSecrets: Bool
        let recoverSecretsButtonTitle: String?
        
        switch viewData.secretsRecoveryAvailability {
        case .notAvailable:
            hideRecoverSecrets = true
            recoverSecretsButtonTitle = nil
        case .available(let secretsRecoveryMode):
            hideRecoverSecrets = false
            
            switch secretsRecoveryMode {
            case .passphraseOrKey:
                recoverSecretsButtonTitle = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsWithPassphrase
            case .onlyKey:
                recoverSecretsButtonTitle = VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsWithoutPassphrase
            }
        }
        
        self.recoverSecretsAvailabilityLoadingContainerView.isHidden = true
        self.recoverSecretsAvailabilityActivityIndicatorView.stopAnimating()
        self.recoverSecretsContainerView.isHidden = hideRecoverSecrets
        self.recoverSecretsButton.setTitle(recoverSecretsButtonTitle, for: .normal)
    }
    
    private func renderCancelled(reason: MXTransactionCancelCode) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelled, animated: true) {
            self.viewModel.process(viewAction: .cancel)
        }
    }
    
    private func renderCancelledByMe(reason: MXTransactionCancelCode) {
        if reason.value != MXTransactionCancelCode.user().value {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
            
            self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationCancelledByMe(reason.humanReadable), animated: true) {
                self.viewModel.process(viewAction: .cancel)
            }
        } else {
            self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        }
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions
    
    private func cancelButtonAction() {
        //self.viewModel.process(viewAction: .cancel)
        
        MXLog.debug("Test Or Push")
        
        //pushToWhatsAppConnectScreen()
    }
    
    
    @IBAction private func acn_SyncCode(_ sender: Any) {
        //self.getSyncCode()
        
        tf_PhoneNumber.resignFirstResponder()
        
        callSyncApi()
    }
    @IBAction private func acn_ConnectWithWhatsApp(_ sender: Any) {
        
       // callSyncApi()
        //self.viewModel.process(viewAction: .cancel)
    }
    
    
    @IBAction private func acn_CountryCode(_ sender: Any) {
        
        
        let picker = ADCountryPicker(style: .grouped)
        // delegate
        picker.delegate = self

        // Display calling codes
        picker.showCallingCodes = true

        // or closure
        picker.didSelectCountryClosure = { name, code in
            _ = picker.navigationController?.popToRootViewController(animated: true)
            MXLog.debug(code)
        }
        
        
//        Use this below code to present the picker
        
        let pickerNavigationController = UINavigationController(rootViewController: picker)
        self.present(pickerNavigationController, animated: true, completion: nil)
        
    }
    
    @IBAction private func recoverSecretsButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .recoverSecrets)
    }
}


// MARK: - KeyVerificationSelfVerifyWaitViewModelViewDelegate
extension KeyVerificationSelfVerifyWaitViewController: KeyVerificationSelfVerifyWaitViewModelViewDelegate {

    func keyVerificationSelfVerifyWaitViewModel(_ viewModel: KeyVerificationSelfVerifyWaitViewModelType, didUpdateViewState viewSate: KeyVerificationSelfVerifyWaitViewState) {
        self.render(viewState: viewSate)
    }
    
    
}

extension KeyVerificationSelfVerifyWaitViewController {
   func pushToWhatsAppConnectScreen(){
       
       if let viewControllers = Bundle.main.loadNibNamed("WhatsAppVC", owner: nil, options: nil) {
         // Access the first view controller in the array (assuming there's only one)
         if let vc = viewControllers.first as? UIViewController {
           self.navigationController?.pushViewController(vc, animated: true)
         } else {
           // Handle the case where the cast to UIViewController fails (e.g., wrong type in Nib)
             MXLog.debug("Error: Could not cast first object in Nib to UIViewController")
         }
       } else {
         // Handle the case where the Nib file is not found
           MXLog.debug("Error: Could not load Nib file WhatsAppView")
       }


    }
    
}
//
//    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
//    
//    func pushToWhatsAppConnectScreen() {
//        MXLog.debug("[KeyVerificationSelfVerifyWaitViewController] pushToWhatsAppConnectScreen")
//        
//        // Create a modal router
//        let modalRouter = NavigationRouter()
//        
//        // Create the coordinator for the WhatsApp screen (replace with appropriate coordinator if needed)
//        let parameters = AuthenticationForgotPasswordCoordinatorParameters(navigationRouter: modalRouter, loginWizard: loginWizard, homeserver: parameters.authenticationService.state.homeserver)
//        let coordinator = AuthenticationForgotPasswordCoordinator(parameters: parameters)
//        
//        // Define the callback to handle the result
//        coordinator.callback = { [weak self, weak coordinator] result in
//            guard let self = self, let coordinator = coordinator else { return }
//            switch result {
//            case .success:
//                self.navigationRouter.dismissModule(animated: true, completion: nil)
//                self.successIndicator = self.indicatorPresenter.present(.success(label: VectorL10n.done))
//            case .cancel:
//                self.navigationRouter.dismissModule(animated: true, completion: nil)
//            }
//            self.remove(childCoordinator: coordinator)
//        }
//        
//        // Start the coordinator
//        coordinator.start()
//        add(childCoordinator: coordinator)
//        
//        // Set the root module for the modal router and present it
//        modalRouter.setRootModule(coordinator)
//        navigationRouter.present(modalRouter, animated: true)
//    }
//}


extension KeyVerificationSelfVerifyWaitViewController: UITextFieldDelegate {
    
    func startSync() {
            syncTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(getSyncCode), userInfo: nil, repeats: true)
        }
        

    

   
    
    func callSyncApi() {
        let phone = tf_PhoneNumber.text
        guard let phoneNumber = phone, !phone!.isEmpty else {
            MXLog.debug("Please enter your phone number.")
            
            matrixManager.showAlert(title: "Error", message: "Please enter your phone number.")
            return
        }
        DispatchQueue.main.async {
            self.matrixManager.startLoading(in: self)
        }
        
        let usernameS = UserDefaults.standard.string(forKey: "Username") ?? ""
        let passwordS = UserDefaults.standard.string(forKey: "Password") ?? ""
        
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Login example
            self.matrixManager.login(username: usernameS, password: passwordS) { result in
                switch result {
                case .success(let accessToken):
                    MXLog.debug("Logged in with access token: \(accessToken)")
                    
                    // Send a message after successful login
                    let roomId = "!UOwHrBaxFpFkvocGVT:matrix.tag.org"
                    let message = "Hello from MatrixManager!"
                    
                    self.matrixManager.sendMessage(roomId: roomId, phoneNumber: phone ?? "", message: message) { sendMessageResult in
                        switch sendMessageResult {
                        case .success:
                            MXLog.debug("Message sent successfully")
                            
                            // Handle message sent successfully, update UI or perform other actions
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {                            //  self.lbl_ScanCode.text = "Message Sent Successfully"
                                
                                //self.getSyncCode1()
                                
                                self.startSync()
                                
                            }
                            
                        case .failure(let error):
                            MXLog.debug("Failed to send message: \(error)")
                            // Handle send message error here
                        }
                    }
                    
                case .failure(let error):
                    MXLog.debug("Login error: \(error)")
                    
                    DispatchQueue.main.async{
                        self.matrixManager.stopLoading()
                        self.matrixManager.showAlert(title: "Error", message: "Please try after sometime.")
                    }
                    
                    // Handle login error here
                }
            }
        }
    }
  
  func getSyncCode1(){
 
      let roomId = "!UOwHrBaxFpFkvocGVT:matrix.tag.org"
      
      matrixManager.sync { syncResult in
          switch syncResult {
          case .success(let syncResponse):
              MXLog.debug("Sync response: \(syncResponse)")
              
              // Handle sync response here
              if let joinedRoom = syncResponse.rooms.join[roomId] {
                  for event in joinedRoom.timeline.events {
                      if event.type == "m.room.message", let body = event.content.body {
                          // Check if the body contains the scan code format you're interested in
                          if body.contains("**") {
                              let components = body.components(separatedBy: "**")
                              if components.count > 1 {
                                  let scanCode = components[1]
                                  DispatchQueue.main.async {
                                      self.matrixManager.stopLoading()
                                      self.lbl_ScanCode.text = scanCode
                                      MXLog.debug("Scan Code: \(scanCode)")
                                      DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                         
                                          self.viewModel.process(viewAction: .cancel)
                                      }
                                      
                                  }
                                  // Update UI or perform other actions with the scan code
                              }
                          }
                      }
                      
                      
                      
                  }
              }
          case .failure(let error):
              MXLog.debug("Sync error: \(error)")
          }
      }
  }
    
    
 
        @objc func getSyncCode() {
                matrixManager.sync { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let syncResponse):
                        self.handleSyncResponse(syncResponse: syncResponse)
                    case .failure(let error):
                        MXLog.debug("Sync failed with error: \(error)")
                    }
                }
            }
      
    func handleSyncResponse(syncResponse: SyncResponseMatrix) {
            let roomId = "!UOwHrBaxFpFkvocGVT:matrix.tag.org" // Replace with your actual room ID
            
            if let joinedRoom = syncResponse.rooms.join[roomId] {
                for event in joinedRoom.timeline.events {
                    if event.type == "m.room.message", let body = event.content.body {
                        // Check if the body contains the scan code format you're interested in
                        if body.contains("**") {
                            let components = body.components(separatedBy: "**")
                            if components.count > 1 {
                                let scanCode = components[1]
                                DispatchQueue.main.async {
                                    self.matrixManager.stopLoading()
                                    self.lbl_ScanCode.text = scanCode
                                    MXLog.debug("Scan Code: \(scanCode)")
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
//                                        self.viewModel.process(viewAction: .cancel)
//                                    }
                                }
                                // Update UI or perform other actions with the scan code
                            }
                        }
                        
                        // Check if the user has successfully logged into WhatsApp
                        if body.contains("Successfully logged in as") {
                            // User successfully logged in
                            DispatchQueue.main.async {
                                self.syncTimer?.invalidate()
                                self.syncTimer = nil
                                MXLog.debug("User successfully logged into WhatsApp-\(body)")
                                MXLog.debug("User successfully logged into WhatsApp")
                                
                                UserDefaults.standard.set(true, forKey: "UserLoggedIn")
                                
                             self.viewModel.process(viewAction: .cancel)
                                // Perform any additional actions needed upon successful login
                            }
                            break
                        }
                    }
                }
            }
        }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tf_PhoneNumber.resignFirstResponder()
            return true
        }
  }



    
    
    
    

