// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum SwipeableItem {
    case message(MessageEntity)
    case conversation(ConversationEntity)

    var isStarred: Bool {
        switch self {
        case .message(let message):
            return message.isStarred
        case .conversation(let conversation):
            return conversation.starred
        }
    }

    var itemID: String {
        switch self {
        case .message(let message):
            return message.messageID.rawValue
        case .conversation(let conversation):
            return conversation.conversationID.rawValue
        }
    }

    func isUnread(labelID: LabelID) -> Bool {
        switch self {
        case .message(let message):
            return message.unRead
        case .conversation(let conversation):
            return conversation.isUnread(labelID: labelID)
        }
    }
}
