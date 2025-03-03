//
//  ProductionCalendar.swift
//  ProtonCore-Doh - Created on 24/03/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreDoh

final class ProductionPass: DoH, VerificationModifiable {

    let defaultHost: String = ProductionHosts.passAPI.urlString
    let captchaHost: String = ProductionHosts.passAPI.urlString

    let accountHost: String = ProductionHosts.accountApp.urlString
    var _humanVerificationV3Host: String = ProductionHosts.verifyApp.urlString
    var humanVerificationV3Host: String { _humanVerificationV3Host }

    let apiHost: String = ProductionHosts.passAPI.dohHost
    let defaultPath: String = ""
    let signupDomain: String = "proton.me"
    let proxyToken: String? = nil
}
