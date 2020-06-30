//
//  R1AppButton.swift
//  R1Kit
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct R1AppButton: Codable, Equatable, Hashable, Identifiable {
   
    // MARK: - Properties -
    
    public var id: Int
    public var colors: R1AppButtonStateColors
    public var action: R1Script?
    
    // MARK: - Initalization -
    
    public init(number: Int) {
        id = number
        colors = R1AppButtonStateColors(resting: R1Color(.blue), pressed: R1Color(.white))
        action = nil
    }

}
