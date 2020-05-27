//
//  R1Color.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

public struct R1Color: Codable, Equatable, Hashable {
   
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
    
    public init(_ color: NSColor) {
        red = Double(color.redComponent)
        green = Double(color.greenComponent)
        blue = Double(color.blueComponent)
    }
}
