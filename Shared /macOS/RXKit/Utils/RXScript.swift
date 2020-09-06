//
//  RXScript.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct RXScript: Codable, Equatable {
    
    // MARK: - Properties -
    
    public let name: String
    public let fileURL: URL
    
    // MARK: - Initalization -
    
    public init(name: String, fileURL: URL) {
        self.name = name
        self.fileURL = fileURL
    }
    
    // MARK: - Running -
    
    public func run() {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = [fileURL.path]
        process.launch()
    }
}
