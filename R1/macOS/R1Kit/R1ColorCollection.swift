//
//  R1ColorCollection.swift
//  R1Kit
//
//  Created by Andrew Finke on 5/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Cocoa

public struct R1ColorCollection: Codable, Equatable, Hashable {
    
    public var firstColor: R1Color
    public var secondColor: R1Color
    public var thirdColor: R1Color
    public var fourthColor: R1Color
    
    public init(color: NSColor) {
        firstColor = R1Color(color)
        secondColor = R1Color(color)
        thirdColor = R1Color(color)
        fourthColor = R1Color(color)
    }
    
    internal init(firstColor: R1Color, secondColor: R1Color, thirdColor: R1Color, fourthColor: R1Color) {
        self.firstColor = firstColor
        self.secondColor = secondColor
        self.thirdColor = thirdColor
        self.fourthColor = fourthColor
    }
}

