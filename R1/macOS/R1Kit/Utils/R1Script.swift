//
//  R1R1Script.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct R1Script: Codable, Equatable, Hashable {
    public let name: String
    public let path: URL
    public init(name: String, path: URL) {
        self.name = name
        self.path = path
    }
}

