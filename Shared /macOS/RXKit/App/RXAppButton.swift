//
//  RXAppButton.swift
//  RXKit
//
//  Created by Andrew Finke on 6/29/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public struct RXAppButton: Codable, Equatable, Hashable, Identifiable {

    // MARK: - Properties -

    public var id: Int
    public var colors: RXAppButtonStateColors
    public var action: RXScript? {
        didSet {
            guard let url = oldValue?.fileURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Initalization -

    public init(number: Int, restingColor: RXColor) {
        id = number
        colors = RXAppButtonStateColors(resting: restingColor, pressed: RXColor(.white))
        action = nil
    }

}
