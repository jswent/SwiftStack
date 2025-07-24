//
//  File.swift
//  
//
//  Created by James Swent on 7/23/25.
//

import Foundation

extension Bundle {
    // swiftlint:disable force_cast
    var appName: String {
        return infoDictionary?["CFBundleName"] as! String
    }

    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }

    var appBuild: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
    // swiftlint:enable force_cast
}
