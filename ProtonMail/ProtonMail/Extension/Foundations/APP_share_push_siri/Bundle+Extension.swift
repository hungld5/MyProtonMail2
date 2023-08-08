//
//  Bundle+Extension.swift
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

extension Bundle {

    /// Returns the app version in a nice to read format
    var appVersion: String {
        return "\(bundleShortVersion) (\(buildVersion))"
    }

    /// Returns the build version of the app.
    var buildVersion: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Returns the major version of the app.
    var bundleShortVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    class func loadResource(named name: String, ofType ext: String) -> String {
        guard let path = main.path(forResource: name, ofType: ext) else {
            fatalError("\(name).\(ext) not present in the bundle.")
        }

        do {
            return try String(contentsOfFile: path)
        } catch {
            fatalError("\(error)")
        }
    }
}
