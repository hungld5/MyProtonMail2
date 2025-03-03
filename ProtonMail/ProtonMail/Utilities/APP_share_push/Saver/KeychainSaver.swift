//
//  KeychainSaver.swift
//  Proton Mail - Created on 07/11/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

class KeychainSaver<T>: Saver<T> where T: Codable {
    convenience init(key: String) {
        self.init(key: key, store: KeychainWrapper.keychain)
    }
}

extension KeychainWrapper: KeyValueStoreProvider {
    func data(forKey key: String, attributes: [CFString: Any]?) -> Data? {
        do {
            return try dataOrError(forKey: key)
        } catch {
            SystemLogger.log(error: error)
        }
        return nil
    }

    func set(_ data: Data, forKey key: String, attributes: [CFString: Any]?) {
        do {
            try setOrError(data, forKey: key)
        } catch {
            SystemLogger.log(error: error)
        }
    }

    func remove(forKey key: String) {
        do {
            try removeOrError(forKey: key)
        } catch {
            SystemLogger.log(error: error)
        }
    }
}
