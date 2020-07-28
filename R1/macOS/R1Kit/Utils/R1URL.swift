//
//  R1URL.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct R1URL {

    public static var support: URL = {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: R1DeveloperConfig.appGroup) else {
            fatalError("Check app group in R1DeveloperConfig")
        }
        let url = container.appendingPathComponent("R1")
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

    private static func createDirectory(at url: URL) {
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: nil)
    }
}
