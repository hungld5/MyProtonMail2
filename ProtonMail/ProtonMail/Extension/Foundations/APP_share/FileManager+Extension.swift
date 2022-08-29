//
//  ileManager+Extension.swift
//  Proton Mail
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

extension FileManager {
    var appGroupsDirectoryURL: URL! {
        return self.containerURL(forSecurityApplicationGroupIdentifier: Constants.App.APP_GROUP)
    }

    var applicationSupportDirectoryURL: URL {
        let urls = self.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let applicationSupportDirectoryURL = urls.first!
        // TODO:: need to handle the ! when empty
        if !FileManager.default.fileExists(atPath: applicationSupportDirectoryURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: applicationSupportDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
            }
        }
        return applicationSupportDirectoryURL
    }

    var cachesDirectoryURL: URL {
        let urls = self.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls.first!
    }

    @available(*, deprecated, renamed: "temporaryDirectory")
    var temporaryDirectoryUrl: URL {
        FileManager.default.temporaryDirectory
    }

    var appGroupsTempDirectoryURL: URL {
        var tempUrl = self.appGroupsDirectoryURL.appendingPathComponent("tmp", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempUrl.path) {
            do {
                try FileManager.default.createDirectory(at: tempUrl, withIntermediateDirectories: false, attributes: nil)
                tempUrl.excludeFromBackup()
            } catch {
            }
        }
        return tempUrl
    }

    func createTempURL(forCopyOfFileNamed name: String) throws -> URL {
        let subUrl = self.appGroupsTempDirectoryURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        try FileManager.default.createDirectory(at: subUrl, withIntermediateDirectories: true, attributes: nil)

        return subUrl.appendingPathComponent(name, isDirectory: false)
    }
}
