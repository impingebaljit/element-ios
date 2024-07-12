// 
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

import Foundation
import MatrixSDK


class MatrixManager {
    private let baseUrl: String
    private var accessToken: String?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        activityIndicator.hidesWhenStopped = true
    }
    

      func startLoading(in viewController: UIViewController) {
        viewController.view.addSubview(activityIndicator)
        activityIndicator.center = viewController.view.center
        activityIndicator.startAnimating()
      }

      func stopLoading() {
          DispatchQueue.main.async {
              self.activityIndicator.removeFromSuperview() // Remove from any view it's currently in
              self.activityIndicator.stopAnimating()
          }
       
      }
    
    
    func login(username: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let loginUrl = "\(baseUrl)/login"
        let params = ["type": "m.login.password","user": username, "password": password]
        
        sendRequest(url: loginUrl, method: "POST", params: params) { result in
            switch result {
            case .success(let data):
                do {
                    let jsonDecoder = JSONDecoder()
                    let response = try jsonDecoder.decode(LoginResponse.self, from: data)
                    self.accessToken = response.accessToken
                    completion(.success(response.accessToken))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sync(completion: @escaping (Result<SyncResponseMatrix, Error>) -> Void) {
        guard let accessToken = self.accessToken else {
            completion(.failure(MatrixError.notLoggedIn))
            return
        }
        
        let syncUrl = "https://matrix.tag.org/_matrix/client/v3/sync" //"\(baseUrl)/sync"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        sendRequest(url: syncUrl, method: "GET", headers: headers) { result in
            switch result {
            case .success(let data):
                do {
                    let jsonDecoder = JSONDecoder()
                    let response = try jsonDecoder.decode(SyncResponseMatrix.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendMessage(roomId: String,phoneNumber: String, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let accessToken = self.accessToken else {
                completion(.failure(MatrixError.notLoggedIn))
                return
            }
            
            let sendMessageUrl = "\(baseUrl)/rooms/\(roomId)/send/m.room.message"
            let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json"]
            let params: [String: Any] = [
                "msgtype": "m.text",
                "body": "login \(phoneNumber)"
            ]
            
            sendRequest(url: sendMessageUrl, method: "POST", params: params, headers: headers) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    //Function to LEave Room
    func leaveRoom(roomId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = self.accessToken else {
            completion(.failure(MatrixError.notLoggedIn))
            return
        }
      
        let leaveRoomUrl = "\(baseUrl)/rooms/\(roomId)/leave"
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        sendRequest(url: leaveRoomUrl, method: "POST", headers: headers) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    
    // Function to fetch joined rooms
    func getJoinedRooms(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let accessToken = self.accessToken else {
            completion(.failure(MatrixError.notLoggedIn))
            return
        }
        
        let urlString = "\(baseUrl)/joined_rooms"
        let headers = ["Authorization": "Bearer \(accessToken)", "Content-Type": "application/json"]
        guard let url = URL(string: urlString) else {
            completion(.failure(MatrixError.requestFailed))
            return
        }
        
        sendRequest(url: urlString, method: "GET", headers: headers) { result in
            switch result {
            case .success(let data):
                do {
                    let jsonDecoder = JSONDecoder()
                    let response = try jsonDecoder.decode(JoinedRoomsResponse.self, from: data)
                    completion(.success(response.joinedRooms))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    private func sendRequest(url: String, method: String, params: [String: Any]? = nil, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(MatrixError.invalidUrl))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let params = params {
            request.httpBody = try? JSONSerialization.data(withJSONObject: params)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let error = MatrixError.invalidResponse(statusCode: statusCode)
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                let error = MatrixError.noData
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
    // Function to create a new room
        func createRoom(completion: @escaping (Result<String, Error>) -> Void) {
            guard let accessToken = self.accessToken else {
                completion(.failure(MatrixError.notLoggedIn))
                return
            }
            
            let urlString = "\(baseUrl)/createRoom"
            guard let url = URL(string: urlString) else {
                completion(.failure(MatrixError.requestFailed))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("en-GB,en-US;q=0.9,en;q=0.8", forHTTPHeaderField: "accept-language")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("max-age=0", forHTTPHeaderField: "cache-control")
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("https://app.element.io", forHTTPHeaderField: "origin")
            request.setValue("u=1, i", forHTTPHeaderField: "priority")
            request.setValue("\"Not/A)Brand\";v=\"8\", \"Chromium\";v=\"126\", \"Google Chrome\";v=\"126\"", forHTTPHeaderField: "sec-ch-ua")
            request.setValue("?0", forHTTPHeaderField: "sec-ch-ua-mobile")
            request.setValue("\"macOS\"", forHTTPHeaderField: "sec-ch-ua-platform")
            request.setValue("empty", forHTTPHeaderField: "sec-fetch-dest")
            request.setValue("cors", forHTTPHeaderField: "sec-fetch-mode")
            request.setValue("cross-site", forHTTPHeaderField: "sec-fetch-site")
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36", forHTTPHeaderField: "user-agent")
            
            let body: [String: Any] = [
                "preset": "trusted_private_chat",
                "visibility": "private",
                "invite": ["@whatsappbot:matrix.tag.org"],
                "is_direct": true,
                "initial_state": [
                    [
                        "type": "m.room.guest_access",
                        "state_key": "",
                        "content": ["guest_access": "can_join"]
                    ]
                ]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(.failure(error))
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    //completion(.failure(MatrixError.invalidResponse))
                    completion(.failure(error ?? "Error"))
                    return
                }
                
                do {
                    let createRoomResponse = try JSONDecoder().decode(CreateRoomResponse.self, from: data)
                    completion(.success(createRoomResponse.roomId))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    
    
    func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { action in
                // Perform any actions when the alert is dismissed
            }
            
            alert.addAction(okAction)
            
            if let topController = UIApplication.topViewController() {
                topController.present(alert, animated: true, completion: nil)
            }
        }
       
}

enum MatrixError: Error {
    case notLoggedIn
    case requestFailed
    case invalidUrl
    case invalidResponse(statusCode: Int)
    case noData
}



struct LoginResponse: Codable {
    
    
    let userID, accessToken, homeServer, deviceID: String
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case accessToken = "access_token"
        case homeServer = "home_server"
        case deviceID = "device_id"
    }
}

struct SyncResponse: Codable {
    // Define your sync response structure
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
