//
//  RXURL.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct RXURL {

    public static var support: URL = {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: RXDeveloperConfig.appGroup) else {
            fatalError("Check app group in RXDeveloperConfig")
        }
        let url = container.appendingPathComponent("RX")
        print(url)
        createDirectory(at: url)
        return url
    }()

    public static var scripts: URL = {
        let url = support.appendingPathComponent("scripts")
        createDirectory(at: url)
        return url
    }()

    public static func newScript() -> URL {
        return scripts.appendingPathComponent(UUID().uuidString)
    }

    public static func appData() -> URL {
        return support.appendingPathComponent("appData")
    }
    
    public static func hardwareData() -> URL {
        return support.appendingPathComponent("hardwareData")
    }

    private static func createDirectory(at url: URL) {
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil)
    }
}
