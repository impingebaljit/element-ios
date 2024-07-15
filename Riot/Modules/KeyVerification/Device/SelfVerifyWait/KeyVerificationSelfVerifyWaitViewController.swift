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
     var finalGetPhone = ""
    
    var countryPicker: ADCountryPicker!
     
     var finalRoomId: String = ""
    
    @IBOutlet weak var countryButton: UIButton!
     
    
    @IBOutlet weak var tf_CountryCode: UITextField!
    @IBOutlet weak var tf_PhoneNumber: UITextField!
    @IBOutlet weak var lbl_ScanCode: CopyLabelClass!
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
        
       // callSyncApi()
        
       // callSyncApiNewWithAllRooms()
        
        
        guard !countryPhoneCode.isEmpty else {
            MXLog.debug("Please enter your country code.")
            matrixManager.showAlert(title: "Error", message: "Please enter your country code.")
            return
        }

        let phoneNumber = tf_PhoneNumber.text ?? ""
        guard !phoneNumber.isEmpty else {
            MXLog.debug("Please enter your phone number.")
            matrixManager.showAlert(title: "Error", message: "Please enter your phone number.")
            return
        }

        finalGetPhone = countryPhoneCode + phoneNumber
        MXLog.debug(finalGetPhone)

        
        
        loginAndSetup()
       // callSyncApiWithNewLogicCreateandLeaveRoom()
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
        picker.didSelectCountryWithCallingCodeClosure = { name, code, callingCode  in
            _ = picker.navigationController?.popToRootViewController(animated: true)
            MXLog.debug(code)
            
            MXLog.debug(code)
            MXLog.debug(callingCode)
            
            self.countryPhoneCode = callingCode

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


//extension KeyVerificationSelfVerifyWaitViewController: UITextFieldDelegate {
//
//        
//
//        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//            tf_PhoneNumber.resignFirstResponder()
//                return true
//            }
//      
//    func callSyncApiWithNewLogicCreateandLeaveRoom() {
//       
//        DispatchQueue.main.async {
//            self.matrixManager.startLoading(in: self)
//        }
//        let username = UserDefaults.standard.string(forKey: "Username") ?? ""
//        let password = UserDefaults.standard.string(forKey: "Password") ?? ""
//
//        // Step 1: Login
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            self.matrixManager.login(username: username, password: password) { result in
//                switch result {
//                case .success(let accessToken):
//                    MXLog.debug("Logged in with access token: \(accessToken)")
//
//                    // Step 2: Get all rooms
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                        self.matrixManager.getJoinedRooms { roomsResult in
//                            switch roomsResult {
//                            case .success(let rooms):
//                                self.processRooms(rooms: rooms, getPhone: self.finalGetPhone)
//                            case .failure(let error):
//                                MXLog.debug("Failed to get rooms: \(error)")
//                                DispatchQueue.main.async {
//                                    self.matrixManager.showAlert(title: "Error", message: "Failed to get rooms")
//                                }
//                            }
//                        }
//                    }
//                case .failure(let error):
//                    MXLog.debug("Login error: \(error)")
//                    DispatchQueue.main.async {
//                        self.matrixManager.stopLoading()
//                        self.matrixManager.showAlert(title: "Error", message: "Too many requests have been sent.")
//                    }
//                }
//            }
//        }
//    }
//
//    func processRooms(rooms: [String], getPhone: String) {
//        var whatsappRoomId: String?
//
//        let group = DispatchGroup()
//
//        for roomId in rooms {
//            self.finalRoomId = roomId
//            group.enter()
//            self.checkIfRoomContainsWhatsappbridgeUser(roomId: roomId) { containsWhatsappbridge in
//                if containsWhatsappbridge {
//                    whatsappRoomId = roomId
//                    MXLog.debug("whatsappRoomId: \(whatsappRoomId ?? "not found")")
//                }
//                group.leave()
//            }
//        }
//
//        group.notify(queue: .main) {
//            if let roomId = whatsappRoomId {
//                self.handleRoomWithWhatsappbridgeUser(roomId: roomId, getPhone: getPhone)
//            } else {
//                // No room found with whatsappbridge user, create a new room
//                MXLog.debug("No room found with whatsappbridge user, creating a new room.")
//                self.createNewRoomAndSendLoginMessage(getPhone: getPhone)
//            }
//        }
//    }
//
//    func checkIfRoomContainsWhatsappbridgeUser(roomId: String, completion: @escaping (Bool) -> Void) {
//        MXLog.debug("checkIfRoomContainsWhatsappbridgeUser called for roomId: \(roomId)")
//        self.matrixManager.getRoomState(roomId: roomId) { result in
//            switch result {
//            case .success(let members):
//                let containsWhatsappbridge = members.contains { $0.userID == "@whatsappbot:matrix.tag.org" }
//                completion(containsWhatsappbridge)
//            case .failure(let error):
//                MXLog.debug("Failed to get room members for room: \(roomId), error: \(error)")
//                completion(false)
//            }
//        }
//    }
//
//    func handleRoomWithWhatsappbridgeUser(roomId: String, getPhone: String) {
//        // Send login message with a 5-second delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            let message = "Hello from MatrixManager!"
//            self.finalRoomId = roomId
//            self.matrixManager.sendMessage(roomId: roomId, phoneNumber: getPhone, message: message) { sendMessageResult in
//                switch sendMessageResult {
//                case .success:
//                    MXLog.debug("Message sent successfully to room: \(roomId)")
//
//                    // Step 4: Sync after sending message
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                        self.scheduleSyncCalls { syncCompleted in
//                            if !syncCompleted {
//                                // Step 5: Leave the room if no scan code found
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                                    self.leaveRoom(roomId: roomId) { leaveResult in
//                                        switch leaveResult {
//                                        case .success:
//                                            MXLog.debug("Left room: \(roomId)")
//
//                                            // Step 6: Create a new room
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                                                self.createNewRoomAndSendLoginMessage(getPhone: getPhone)
//                                            }
//                                        case .failure(let error):
//                                            MXLog.debug("Failed to leave room: \(roomId), error: \(error)")
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                case .failure(let error):
//                    MXLog.debug("Failed to send message to room: \(error)")
//                    DispatchQueue.main.async {
//                        self.matrixManager.showAlert(title: "Error", message: "Failed to send message to room")
//                    }
//                }
//            }
//        }
//    }
//
//    func createNewRoomAndSendLoginMessage(getPhone: String) {
//        self.matrixManager.createRoom { result in
//            switch result {
//            case .success(let roomId):
//                MXLog.debug("Created Room ID: \(roomId)")
//                self.finalRoomId = roomId
//
//                // Send login message with new room ID with a 5-second delay
//                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                    let message = "Hello from MatrixManager!"
//                    self.matrixManager.sendMessage(roomId: self.finalRoomId, phoneNumber: getPhone, message: message) { sendMessageResult in
//                        switch sendMessageResult {
//                        case .success:
//                            MXLog.debug("Message sent successfully")
//
//                            // Sync after sending message
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                                self.scheduleSyncCalls { syncCompleted in
//                                    if !syncCompleted {
//                                        // Leave the room if no scan code found
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                                            self.leaveRoom(roomId: roomId) { leaveResult in
//                                                switch leaveResult {
//                                                case .success:
//                                                    MXLog.debug("Left room: \(roomId)")
//
//                                                    // Create another new room and send login message
//                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                                                        self.createNewRoomAndSendLoginMessage(getPhone: getPhone)
//                                                    }
//                                                case .failure(let error):
//                                                    MXLog.debug("Failed to leave room: \(roomId), error: \(error)")
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        case .failure(let error):
//                            MXLog.debug("Failed to send message: \(error)")
//                            DispatchQueue.main.async {
//                                self.matrixManager.showAlert(title: "Error", message: "Failed to send message")
//                            }
//                        }
//                    }
//                }
//            case .failure(let error):
//                MXLog.debug("Failed to create room: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    self.matrixManager.showAlert(title: "Error", message: "Failed to create room")
//                }
//            }
//        }
//    }
//

//    func leaveRoom(roomId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        self.matrixManager.leaveRoom(roomId: roomId) { result in
//            completion(result)
//        }
//    }
//

//    
//    func scheduleSyncCalls(completion: @escaping (Bool) -> Void) {
//        var attempts = 0
//        var syncCompleted = false
//        
//        func attemptSync() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempts) * 5.0 + 5.0) {
//                self.getSyncCode { result in
//                    switch result {
//                    case .success(let syncResponse):
//                        if self.handleSyncResponse(syncResponse: syncResponse) {
//                            syncCompleted = true
//                            completion(true)
//                        } else {
//                            attempts += 1
//                            if attempts < 4 {
//                                attemptSync() // Retry sync if not completed and within attempts limit
//                            } else {
//                                completion(false) // If all attempts fail, complete with false
//                            }
//                        }
//                    case .failure(let error):
//                        MXLog.debug("Sync failed with error: \(error)")
//                        attempts += 1
//                        if attempts < 4 {
//                            attemptSync() // Retry sync if failed and within attempts limit
//                        } else {
//                            completion(false) // If all attempts fail, complete with false
//                        }
//                    }
//                }
//            }
//        }
//        
//        attemptSync() // Start the initial attempt
//    }
//
//    func getSyncCode(completion: @escaping (Result<SyncResponseMatrix, Error>) -> Void) {
//        matrixManager.sync { result in
//            completion(result)
//        }
//    }
//
//    func handleSyncResponse(syncResponse: SyncResponseMatrix) -> Bool {
//        let roomId = self.finalRoomId
//        
//        if let joinedRoom = syncResponse.rooms.join[roomId] {
//            for event in joinedRoom.timeline.events {
//                if event.type == "m.room.message", let body = event.content.body {
//                    // Check if the body contains the scan code format you're interested in
//                    if body.contains("**") {
//                        let components = body.components(separatedBy: "**")
//                        if components.count > 1 {
//                            let scanCode = components[1]
//                            DispatchQueue.main.async {
//                                self.matrixManager.stopLoading()
//                                self.lbl_ScanCode.text = scanCode
//                                MXLog.debug("Scan Code: \(scanCode)")
//                            }
//                            return true
//                        }
//                    }
//                    
//                    // Check if the user has successfully logged into WhatsApp
//                    if body.contains("Successfully logged in as") {
//                        DispatchQueue.main.async {
//                            self.syncTimer?.invalidate()
//                            self.syncTimer = nil
//                            MXLog.debug("User successfully logged into WhatsApp: \(body)")
//                            
//                            UserDefaults.standard.set(true, forKey: "UserLoggedIn")
//                            
//                            self.viewModel.process(viewAction: .cancel)
//                        }
//                        break
//                    }
//                }
//            }
//        }
//        
//        return false
//    }

extension KeyVerificationSelfVerifyWaitViewController: UITextFieldDelegate {
func loginAndSetup() {
       DispatchQueue.main.async {
           self.matrixManager.startLoading(in: self)
       }
       
       let username = UserDefaults.standard.string(forKey: "Username") ?? ""
       let password = UserDefaults.standard.string(forKey: "Password") ?? ""
       
       DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
           self.login(username: username, password: password)
       }
   }


    private func login(username: String, password: String) {
            matrixManager.login(username: username, password: password) { [weak self] result in
                switch result {
                case .success(let accessToken):
                    MXLog.debug("Logged in with access token: \(accessToken)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        self?.getJoinedRooms()
                    }
                case .failure(let error):
                    MXLog.debug("Login error: \(error)")
                    DispatchQueue.main.async {
                        self?.matrixManager.stopLoading()
                        self?.matrixManager.showAlert(title: "Error", message: "Too many requests have been sent.")
                    }
                }
            }
        }
    
    private func getJoinedRooms() {
            matrixManager.getJoinedRooms { [weak self] roomsResult in
                switch roomsResult {
                case .success(let rooms):
                    self?.processRooms(rooms: rooms)
                case .failure(let error):
                    MXLog.debug("Failed to get rooms: \(error)")
                    DispatchQueue.main.async {
                        self?.matrixManager.showAlert(title: "Error", message: "Failed to get joined rooms")
                    }
                }
            }
        }

    private func processRooms(rooms: [String]) {
        let group = DispatchGroup()
        var foundWhatsAppBridgeRoomId: String?

        for roomId in rooms {
            group.enter()
            checkIfRoomContainsWhatsappbridgeUser(roomId: roomId) { [weak self] containsWhatsappbridge in
                guard let self = self else { return }
                self.finalRoomId = roomId
                if containsWhatsappbridge {
                    self.leaveRoom(roomId: self.finalRoomId) { _
                        in }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
//            if let roomId = foundWhatsAppBridgeRoomId {
//                self.sendLoginMessage(in: self.finalRoomId)
//            } else {
//                MXLog.debug("No room found with WhatsApp bridge user, creating a new room.")
                self.createNewRoomAndSendLoginMessage()
            //}
        }
    }
   
    private func checkIfRoomContainsWhatsappbridgeUser(roomId: String, completion: @escaping (Bool) -> Void) {
        MXLog.debug("Checking if room contains WhatsApp bridge user for roomId: \(roomId)")
        
        matrixManager.getRoomState(roomId: roomId) { result in
            switch result {
            case .success(let roomStates):
                // Check if any room state matches the criteria for WhatsApp bridge user
                let containsWhatsappbridge = roomStates.contains { state -> Bool in
                    return state.type == "m.room.member" &&
                           state.sender == "@whatsappbot:matrix.tag.org"
                }
                completion(containsWhatsappbridge)
                
                MXLog.debug("WhatsApp room exist")
                
            case .failure(let error):
                MXLog.debug("Failed to get room state for room for whatsapp name: \(roomId), error: \(error)")
                completion(false)
            }
        }
    }

    private func handleRoomWithWhatsappbridgeUser(roomId: String) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.sendLoginMessage(in: roomId)
            }
        }
    
    private func sendLoginMessage(in roomId: String) {
        self.matrixManager.sendMessage(roomId: roomId, phoneNumber: finalGetPhone, message: "hi") { result in
            switch result {
            case .success:
                self.scheduleSyncCalls { syncCompleted in
                    if syncCompleted {
                        MXLog.debug("Successfully synced and obtained scan code.")
                    } else {
                        MXLog.debug("Failed to sync and obtain scan code, leaving the room and creating a new one.")
                        self.leaveRoomAndCreateNewOne()
                    }
                }
            case .failure(let error):
                MXLog.debug("Failed to send login message in room: \(roomId), error: \(error)")
            }
        }
    }
    
    private func leaveRoomAndCreateNewOne() {
       let roomId = finalRoomId 

        self.leaveRoom(roomId: roomId) { [weak self] leaveResult in
            switch leaveResult {
            case .success:
                MXLog.debug("Left room: \(roomId)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self?.createNewRoomAndSendLoginMessage()
                }
            case .failure(let error):
                MXLog.debug("Failed to leave room: \(roomId), error: \(error)")
            }
        }
    }

   
    private func createNewRoomAndSendLoginMessage() {
        matrixManager.createRoom { [weak self] result in
            switch result {
            case .success(let roomId):
                MXLog.debug("Created Room ID: \(roomId)")
                self?.finalRoomId = roomId
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self?.sendLoginMessage(in: self?.finalRoomId ?? "")
                }
            case .failure(let error):
                MXLog.debug("Failed to create new room: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.matrixManager.showAlert(title: "Error", message: "Failed to create new room")
                }
            }
        }
    }


    private func scheduleSyncCalls(completion: @escaping (Bool) -> Void) {
        var attempts = 0
        let maxAttempts = 4
        let roomID = self.finalRoomId
        
        var syncCompleted = false

        func attemptSync() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempts) * 5.0 + 5.0) {
                self.getSyncCode { result in
                    switch result {
                    case .success(let syncResponse):
                        if self.handleSyncResponse(syncResponse: syncResponse) {
                            syncCompleted = true
                            completion(true)
                        } else {
                            attempts += 1
                            if attempts < maxAttempts {
                                attemptSync()
                            } else {
                                self.leaveRoom(roomId: roomID) { result in
                                    switch result {
                                    case .success:
                                        self.createNewRoomAndSendLoginMessage()
                                    case .failure(let error):
                                        MXLog.debug("Failed to leave room with error: \(error)")
                                        completion(false)
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        MXLog.debug("Sync failed with error: \(error)")
                        attempts += 1
                        if attempts < maxAttempts {
                            attemptSync()
                        } else {
                            self.leaveRoom(roomId: roomID) { result in
                                switch result {
                                case .success:
                                    self.createNewRoomAndSendLoginMessage()
                                case .failure(let error):
                                    MXLog.debug("Failed to leave room with error: \(error)")
                                    completion(false)
                                }
                            }
                        }
                    }
                }
            }
        }

        attemptSync()
    }

    func getSyncCode(completion: @escaping (Result<SyncResponseMatrix, Error>) -> Void) {
        matrixManager.sync { result in
            completion(result)
        }
    }

    func handleSyncResponse(syncResponse: SyncResponseMatrix) -> Bool {
        
        let roomId = self.finalRoomId
        if let joinedRoom = syncResponse.rooms.join[roomId] {
            for event in joinedRoom.timeline.events {
                if event.type == "m.room.message", let body = event.content.body {
                    if body.contains("**") {
                        let components = body.components(separatedBy: "**")
                        if components.count > 1 {
                            let scanCode = components[1]
                            DispatchQueue.main.async {
                                self.matrixManager.stopLoading()
                                self.lbl_ScanCode.text = scanCode
                                MXLog.debug("Scan Code: \(scanCode)")
                                
                                UIPasteboard.general.string = scanCode
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                    self.viewModel.process(viewAction: .cancel)
                                }
                            }
                            return true
                        }
                    }
                    
                    if body.contains("You're already logged in") {
                        DispatchQueue.main.async {
                            self.viewModel.process(viewAction: .cancel)
                        }
                    }

                    if body.contains("Successfully logged in as") {
                        DispatchQueue.main.async {
                            MXLog.debug("User successfully logged into WhatsApp: \(body)")
                            UserDefaults.standard.set(true, forKey: "UserLoggedIn")
                            self.viewModel.process(viewAction: .cancel)
                        }
                        return true
                    }
                }
            }
        }
        return false
    }
 
    
    private func leaveRoom(roomId: String, completion: @escaping (Result<Void, Error>) -> Void) {
            matrixManager.leaveRoom(roomId: roomId) { result in
                completion(result)
            }
        }

}



