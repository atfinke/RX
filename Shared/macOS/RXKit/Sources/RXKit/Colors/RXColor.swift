//
//  RXColor.swift
//  RXKit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

#if os(macOS)
public typealias LegacyColor = NSColor
#else
public typealias LegacyColor = UIColor
#endif

public struct RXColor: Codable, Equatable {

     // MARK: - Properties -

    public let red: Double
    public let green: Double
    public let blue: Double

    public var swiftColor: Color {
        return Color(red: red, green: green, blue: blue)
    }

    public var rgb: (red: Double, green: Double, blue: Double) {
        return (red, green, blue)
    }

    // MARK: - Initalization -

    public init(_ color: LegacyColor) {
        // handles colorspace
        #if os(macOS)
        guard let ciColor = CIColor(color: color) else {
            fatalError()
        }
        #else
        let ciColor = CIColor(color: color)
        #endif
        red = Double(ciColor.red)
        green = Double(ciColor.green)
        blue = Double(ciColor.blue)
    }
}
