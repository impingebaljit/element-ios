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

import SwiftUI

 struct ConnectWhatsAppContentView: View {
        @State private var isLinkActive = false

        var body: some View {
            NavigationView {
                VStack {
                    Text("Main View")
                        .font(.largeTitle)
                        .padding()
                    
                    // Invisible NavigationLink triggered by state variable
                    NavigationLink(destination: BlankView(), isActive: $isLinkActive) {
                        EmptyView()
                    }
                    
                    // Custom UIButton wrapped in SwiftUI view
                    ConnectWhatsApp(title: "Connect with WhatsApp") {
                        isLinkActive = true
                    }
                    .frame(width: 200, height: 50)
                }
                .navigationTitle("Home")
            }
        }
    }

    struct BlankView: View {
        var body: some View {
            Text("This is a blank view")
                .font(.largeTitle)
                .padding()
        }
    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ConnectWhatsAppContentView()
        }
    }
