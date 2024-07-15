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

    // MARK: - RoomNameModelElement
    struct RoomNameModelCheck: Codable {
        let type, roomID, sender: String
        let content: ContentCheck
        let stateKey: String
        let originServerTs: Int
        let unsigned: Unsigned
        let eventID, userID: String
        let age: Int
        let replacesState: String?
        let prevContent: PrevContentCheck?

        enum CodingKeys: String, CodingKey {
            case type
            case roomID = "room_id"
            case sender, content
            case stateKey = "state_key"
            case originServerTs = "origin_server_ts"
            case unsigned
            case eventID = "event_id"
            case userID = "user_id"
            case age
            case replacesState = "replaces_state"
            case prevContent = "prev_content"
        }
    }

    // MARK: - Content
    struct ContentCheck: Codable {
        let roomVersion, creator, guestAccess, historyVisibility: String?
        let joinRule, membership, displayname, avatarURL: String?
        let users: [String: Int]?
        let usersDefault: Int?
        let events: [String: Int]?
        let eventsDefault, stateDefault, ban, kick: Int?
        let redact, invite, historical: Int?

        enum CodingKeys: String, CodingKey {
            case roomVersion = "room_version"
            case creator
            case guestAccess = "guest_access"
            case historyVisibility = "history_visibility"
            case joinRule = "join_rule"
            case membership, displayname
            case avatarURL = "avatar_url"
            case users
            case usersDefault = "users_default"
            case events
            case eventsDefault = "events_default"
            case stateDefault = "state_default"
            case ban, kick, redact, invite, historical
        }
    }

    // MARK: - PrevContent
    struct PrevContentCheck: Codable {
        let isDirect: Bool
        let membership, displayname, avatarURL: String

        enum CodingKeys: String, CodingKey {
            case isDirect = "is_direct"
            case membership, displayname
            case avatarURL = "avatar_url"
        }
    }

    // MARK: - Unsigned
    struct Unsigned: Codable {
        let age: Int
        let replacesState: String?
        let prevContent: PrevContentCheck?
        let prevSender: String?

        enum CodingKeys: String, CodingKey {
            case age
            case replacesState = "replaces_state"
            case prevContent = "prev_content"
            case prevSender = "prev_sender"
        }
    }

    typealias RoomNameModel = [RoomNameModelCheck]
