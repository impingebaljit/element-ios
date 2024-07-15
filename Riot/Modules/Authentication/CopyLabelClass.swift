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

class CopyLabelClass: UILabel {

        
        // MARK: - Initialization
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        private func setup() {
            // Enable user interaction
            isUserInteractionEnabled = true
            
            // Add a long press gesture recognizer to show the copy menu
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(showMenu(_:)))
            addGestureRecognizer(longPressGesture)
        }
        
        // MARK: - UIResponder Methods
        
        override var canBecomeFirstResponder: Bool {
            return true
        }
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            return action == #selector(copyText(_:))
        }
        
        // MARK: - Menu Actions
        
        @objc private func copyText(_ sender: Any?) {
            UIPasteboard.general.string = text
        }
        
        // MARK: - Gesture Recognizer
        
        @objc private func showMenu(_ sender: UILongPressGestureRecognizer) {
            guard sender.state == .began else { return }
            
            becomeFirstResponder()
            
            let menu = UIMenuController.shared
            menu.menuItems = [UIMenuItem(title: "Copy", action: #selector(copyText(_:)))]
            
            if let superview = superview {
                menu.showMenu(from: superview, rect: frame)
            }
        }
    }
